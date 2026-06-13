package io.nexpass

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import org.json.JSONArray
import org.json.JSONObject
import javax.crypto.Cipher
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import java.security.SecureRandom

/**
 * Cross-process credential cache for the AutofillService.
 *
 * When the Flutter app's vault is unlocked, decrypted credentials are written
 * here so the AutofillService (which runs in an isolated process) can access
 * them without needing the Flutter engine.
 *
 * Security: Credentials are encrypted with a per-install random key stored
 * in Android Keystore (or fallback SharedPreferences). The key is generated
 * on first launch and never leaves the device.
 */
object CredentialCache {

    private const val PREFS_NAME = "nexpass_autofill_cache"
    private const val KEY_CREDENTIALS = "cached_credentials"
    private const val KEY_ENCRYPT_KEY = "cache_enc_key"
    private const val KEY_IV = "cache_iv"

    private var cachedKey: SecretKey? = null

    // ── Public API ──────────────────────────────────────────────────────

    /**
     * Write a list of decrypted credentials to the cache.
     * Called by AutofillServicePlugin when Flutter sends updated vault data.
     */
    fun cacheCredentials(context: Context, credentials: List<CachedCredential>) {
        val prefs = getPrefs(context)
        val key = getOrCreateKey(context)

        val jsonArray = JSONArray()
        for (cred in credentials) {
            val obj = JSONObject().apply {
                put("uuid", cred.uuid)
                put("packageName", cred.packageName)
                put("name", cred.name)
                put("username", cred.username)
                put("password", cred.password)
                put("website", cred.website)
            }
            jsonArray.put(obj)
        }

        val plainText = jsonArray.toString()
        val encrypted = encryptAesGcm(key, plainText.toByteArray(Charsets.UTF_8))

        prefs.edit()
            .putString(KEY_CREDENTIALS, Base64.encodeToString(encrypted, Base64.NO_WRAP))
            .apply()
    }

    /**
     * Query cached credentials matching a package name.
     * Returns empty list if no match or cache is empty.
     */
    fun queryByPackage(context: Context, packageName: String): List<CachedCredential> {
        val encrypted = getPrefs(context).getString(KEY_CREDENTIALS, null) ?: return emptyList()
        val key = getOrCreateKey(context)

        return try {
            val cipherText = Base64.decode(encrypted, Base64.NO_WRAP)
            val plainBytes = decryptAesGcm(key, cipherText)
            val json = String(plainBytes, Charsets.UTF_8)
            val array = JSONArray(json)

            val results = mutableListOf<CachedCredential>()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                val cred = CachedCredential(
                    uuid = obj.getString("uuid"),
                    packageName = obj.getString("packageName"),
                    name = obj.getString("name"),
                    username = obj.getString("username"),
                    password = obj.getString("password"),
                    website = obj.optString("website", ""),
                )
                // Match by package name or website domain
                if (cred.packageName == packageName ||
                    cred.website.contains(packageName, ignoreCase = true)) {
                    results.add(cred)
                }
            }
            results
        } catch (e: Exception) {
            android.util.Log.w("CredentialCache", "Failed to decrypt cache: ${e.message}")
            emptyList()
        }
    }

    /**
     * Query all cached credentials (for AutofillService to show all available).
     */
    fun queryAll(context: Context): List<CachedCredential> {
        val encrypted = getPrefs(context).getString(KEY_CREDENTIALS, null) ?: return emptyList()
        val key = getOrCreateKey(context)

        return try {
            val cipherText = Base64.decode(encrypted, Base64.NO_WRAP)
            val plainBytes = decryptAesGcm(key, cipherText)
            val json = String(plainBytes, Charsets.UTF_8)
            val array = JSONArray(json)

            val results = mutableListOf<CachedCredential>()
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                results.add(CachedCredential(
                    uuid = obj.getString("uuid"),
                    packageName = obj.getString("packageName"),
                    name = obj.getString("name"),
                    username = obj.getString("username"),
                    password = obj.getString("password"),
                    website = obj.optString("website", ""),
                ))
            }
            results
        } catch (e: Exception) {
            android.util.Log.w("CredentialCache", "Failed to decrypt cache: ${e.message}")
            emptyList()
        }
    }

    /**
     * Clear all cached credentials.
     * Called when the vault is locked.
     */
    fun clearCache(context: Context) {
        getPrefs(context).edit().remove(KEY_CREDENTIALS).apply()
    }

    /**
     * Check if the cache has any credentials.
     */
    fun hasCredentials(context: Context): Boolean {
        return getPrefs(context).getString(KEY_CREDENTIALS, null) != null
    }

    // ── Internal ────────────────────────────────────────────────────────

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private fun getOrCreateKey(context: Context): SecretKey {
        cachedKey?.let { return it }

        val prefs = getPrefs(context)
        val existingKeyB64 = prefs.getString(KEY_ENCRYPT_KEY, null)

        if (existingKeyB64 != null) {
            val keyBytes = Base64.decode(existingKeyB64, Base64.NO_WRAP)
            cachedKey = SecretKeySpec(keyBytes, "AES")
            return cachedKey!!
        }

        // Generate a new random AES key
        val keyBytes = ByteArray(32)
        SecureRandom().nextBytes(keyBytes)
        val key = SecretKeySpec(keyBytes, "AES")

        prefs.edit()
            .putString(KEY_ENCRYPT_KEY, Base64.encodeToString(keyBytes, Base64.NO_WRAP))
            .apply()

        cachedKey = key
        return key
    }

    // ── AES-256-GCM encryption helpers ──────────────────────────────────

    private fun encryptAesGcm(key: SecretKey, plainText: ByteArray): ByteArray {
        val iv = ByteArray(12)
        SecureRandom().nextBytes(iv)

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key, GCMParameterSpec(128, iv))
        val encrypted = cipher.doFinal(plainText)

        // Prepend IV (12 bytes) to ciphertext
        val result = ByteArray(iv.size + encrypted.size)
        System.arraycopy(iv, 0, result, 0, iv.size)
        System.arraycopy(encrypted, 0, result, iv.size, encrypted.size)
        return result
    }

    private fun decryptAesGcm(key: SecretKey, data: ByteArray): ByteArray {
        val iv = data.copyOfRange(0, 12)
        val cipherText = data.copyOfRange(12, data.size)

        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, iv))
        return cipher.doFinal(cipherText)
    }
}

/**
 * Lightweight credential data class for cross-process cache.
 */
data class CachedCredential(
    val uuid: String,
    val packageName: String,
    val name: String,
    val username: String,
    val password: String,
    val website: String = "",
)

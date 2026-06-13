package io.nexpass

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

/**
 * MethodChannel bridge between Flutter and the Android AutofillService.
 *
 * Handles:
 * - "cacheCredentials": Flutter sends decrypted credentials → stored in CredentialCache
 * - "clearCache": Flutter clears the cache on vault lock
 * - "queryMatchingCredentials": Returns cached credentials matching a domain
 * - "fillCredential": Returns a specific credential by UUID
 * - "openAutofillSettings": Opens Android autofill service selection
 * - "onCredentialSelected": Notified when user picks a credential
 */
class AutofillServicePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var credentialSavedReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = binding
        channel = MethodChannel(binding.binaryMessenger, "io.nexpass.app/autofill")
        channel.setMethodCallHandler(this)
        registerBroadcastReceiver(binding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = pluginBinding?.applicationContext
            ?: run { result.error("NO_CONTEXT", "Plugin not attached", null); return }

        when (call.method) {
            // ── Flutter → Native: Cache credentials for autofill ────
            "cacheCredentials" -> handleCacheCredentials(call, context, result)

            // ── Flutter → Native: Clear credential cache ────────────
            "clearCache" -> {
                CredentialCache.clearCache(context)
                result.success(true)
            }

            // ── Flutter / System: Query matching credentials ────────
            "queryMatchingCredentials" -> handleQueryCredentials(call, context, result)

            // ── Flutter / System: Get specific credential ───────────
            "fillCredential" -> handleFillCredential(call, context, result)

            // ── Flutter: Notify credential selected ─────────────────
            "onCredentialSelected" -> result.success(null)

            // ── Flutter: Open autofill settings ─────────────────────
            "openAutofillSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        unregisterBroadcastReceiver(binding.applicationContext)
        pluginBinding = null
    }

    // ── Handler implementations ──────────────────────────────────────────

    private fun handleCacheCredentials(
        call: MethodCall,
        context: Context,
        result: MethodChannel.Result,
    ) {
        try {
            val rawList = call.arguments as? List<*> ?: run {
                result.error("INVALID_ARGS", "Expected credential list", null)
                return
            }

            val credentials = rawList.mapNotNull { raw ->
                val map = raw as? Map<*, *> ?: return@mapNotNull null
                CachedCredential(
                    uuid = map["uuid"] as? String ?: return@mapNotNull null,
                    packageName = map["packageName"] as? String ?: "",
                    name = map["name"] as? String ?: "",
                    username = map["username"] as? String ?: "",
                    password = map["password"] as? String ?: "",
                    website = map["website"] as? String ?: "",
                )
            }

            CredentialCache.cacheCredentials(context, credentials)
            result.success(true)
        } catch (e: Exception) {
            result.error("CACHE_ERROR", "Failed to cache credentials: ${e.message}", null)
        }
    }

    private fun handleQueryCredentials(
        call: MethodCall,
        context: Context,
        result: MethodChannel.Result,
    ) {
        try {
            val domain = call.arguments as? String ?: ""
            val all = CredentialCache.queryAll(context)

            val filtered = if (domain.isEmpty()) all else all.filter { cred ->
                cred.name.contains(domain, ignoreCase = true) ||
                    cred.username.contains(domain, ignoreCase = true) ||
                    cred.website.contains(domain, ignoreCase = true) ||
                    cred.packageName.contains(domain, ignoreCase = true)
            }

            result.success(filtered.map { cred ->
                mapOf(
                    "uuid" to cred.uuid,
                    "name" to cred.name,
                    "username" to cred.username,
                    "password" to cred.password,
                    "website" to cred.website,
                )
            })
        } catch (e: Exception) {
            result.error("QUERY_ERROR", "Failed to query: ${e.message}", null)
        }
    }

    private fun handleFillCredential(
        call: MethodCall,
        context: Context,
        result: MethodChannel.Result,
    ) {
        try {
            val uuid = call.arguments as? String ?: ""
            val all = CredentialCache.queryAll(context)
            val match = all.find { it.uuid == uuid }

            if (match != null) {
                result.success(mapOf(
                    "success" to true,
                    "uuid" to match.uuid,
                    "username" to match.username,
                    "password" to match.password,
                ))
            } else {
                result.success(mapOf("success" to false, "error" to "Not found"))
            }
        } catch (e: Exception) {
            result.error("FILL_ERROR", "Failed to fill: ${e.message}", null)
        }
    }

    // ── Broadcast receiver for saved credentials ─────────────────────────

    private fun registerBroadcastReceiver(context: Context) {
        credentialSavedReceiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                // Forward to Flutter for Isar sync
                val data = mapOf(
                    "uuid" to (intent.getStringExtra(NexPassAutofillService.EXTRA_UUID) ?: ""),
                    "name" to (intent.getStringExtra(NexPassAutofillService.EXTRA_NAME) ?: ""),
                    "username" to (intent.getStringExtra(NexPassAutofillService.EXTRA_USERNAME) ?: ""),
                    "password" to (intent.getStringExtra(NexPassAutofillService.EXTRA_PASSWORD) ?: ""),
                    "packageName" to (intent.getStringExtra(NexPassAutofillService.EXTRA_PACKAGE) ?: ""),
                )
                channel.invokeMethod("onCredentialSaved", data)
            }
        }

        val filter = IntentFilter(NexPassAutofillService.ACTION_CREDENTIAL_SAVED)
        context.registerReceiver(credentialSavedReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
    }

    private fun unregisterBroadcastReceiver(context: Context) {
        credentialSavedReceiver?.let {
            try { context.unregisterReceiver(it) } catch (_: Exception) {}
        }
        credentialSavedReceiver = null
    }
}

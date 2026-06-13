package io.nexpass

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.CancellationSignal
import android.service.autofill.AutofillService
import android.service.autofill.Dataset
import android.service.autofill.FillCallback
import android.service.autofill.FillContext
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.SaveCallback
import android.service.autofill.SaveInfo
import android.service.autofill.SaveRequest
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import android.widget.RemoteViews

/**
 * Android Autofill Service for NexPass.
 *
 * When a login form is detected, queries the CredentialCache for matching
 * credentials and presents them as autofill suggestions.
 *
 * Architecture:
 * - AutofillService runs in an isolated process (separate from Flutter).
 * - Credentials are shared via CredentialCache (EncryptedSharedPreferences).
 * - The Flutter app writes to CredentialCache whenever the vault is updated.
 */
class NexPassAutofillService : AutofillService() {

    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback
    ) {
        try {
            val context = request.fillContexts.last()
            val structure = context.structure
            val parser = AutofillStructureParser(structure)

            // ── No fillable fields detected ─────────────────────────
            if (parser.usernameId == null && parser.passwordId == null) {
                callback.onSuccess(null)
                return
            }

            // ── Query cached credentials ────────────────────────────
            val credentials = CredentialCache.queryAll(applicationContext)
            if (credentials.isEmpty()) {
                callback.onSuccess(null)
                return
            }

            // ── Build FillResponse with matching credentials ────────
            val response = buildFillResponse(
                credentials = credentials,
                usernameId = parser.usernameId,
                passwordId = parser.passwordId,
            )

            callback.onSuccess(response)
        } catch (e: Exception) {
            android.util.Log.e("NexPassAutofill", "onFillRequest error: ${e.message}", e)
            callback.onSuccess(null)
        }
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        try {
            val structure = request.fillContexts.last().structure
            val parser = AutofillStructureParser(structure)

            // Extract the filled values from the AssistStructure
            val username = extractValue(structure, parser.usernameId)
            val password = extractValue(structure, parser.passwordId)
            val packageName = parser.packageName

            if (username.isNullOrEmpty() && password.isNullOrEmpty()) {
                callback.onSuccess()
                return
            }

            // Save to CredentialCache for future autofill
            val newCred = CachedCredential(
                uuid = java.util.UUID.randomUUID().toString(),
                packageName = packageName,
                name = packageName.substringAfterLast('.').replaceFirstChar { it.uppercase() },
                username = username ?: "",
                password = password ?: "",
                website = packageName,
            )

            // Append to existing cache
            val existing = CredentialCache.queryAll(applicationContext).toMutableList()
            existing.add(newCred)
            CredentialCache.cacheCredentials(applicationContext, existing)

            // Notify Flutter via broadcast (picked up by AutofillServicePlugin)
            val broadcast = Intent(ACTION_CREDENTIAL_SAVED).apply {
                putExtra(EXTRA_UUID, newCred.uuid)
                putExtra(EXTRA_NAME, newCred.name)
                putExtra(EXTRA_USERNAME, newCred.username)
                putExtra(EXTRA_PASSWORD, newCred.password)
                putExtra(EXTRA_PACKAGE, newCred.packageName)
                setPackage(packageName)
            }
            sendBroadcast(broadcast)

            callback.onSuccess()
        } catch (e: Exception) {
            android.util.Log.e("NexPassAutofill", "onSaveRequest error: ${e.message}", e)
            callback.onSuccess()
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────

    private fun buildFillResponse(
        credentials: List<CachedCredential>,
        usernameId: AutofillId?,
        passwordId: AutofillId?,
    ): FillResponse {
        val builder = FillResponse.Builder()

        // Add a Dataset for each credential
        for (cred in credentials) {
            val presentation = RemoteViews(packageName, android.R.layout.simple_list_item_1).apply {
                setTextViewText(android.R.id.text1, "${cred.name} — ${cred.username}")
            }

            val datasetBuilder = Dataset.Builder(presentation)

            if (usernameId != null) {
                datasetBuilder.setValue(
                    usernameId,
                    AutofillValue.forText(cred.username),
                    presentation,
                )
            }

            if (passwordId != null) {
                datasetBuilder.setValue(
                    passwordId,
                    AutofillValue.forText(cred.password),
                    presentation,
                )
            }

            builder.addDataset(datasetBuilder.build())
        }

        // Add SaveInfo so the system asks to save new credentials
        val saveType = when {
            usernameId != null && passwordId != null ->
                SaveInfo.SAVE_DATA_TYPE_USERNAME or SaveInfo.SAVE_DATA_TYPE_PASSWORD
            passwordId != null ->
                SaveInfo.SAVE_DATA_TYPE_PASSWORD
            else ->
                SaveInfo.SAVE_DATA_TYPE_USERNAME
        }

        val requiredIds = mutableListOf<AutofillId>()
        usernameId?.let { requiredIds.add(it) }
        passwordId?.let { requiredIds.add(it) }

        val saveInfo = SaveInfo.Builder(saveType, requiredIds.toTypedArray())
            .build()
        builder.setSaveInfo(saveInfo)

        return builder.build()
    }

    private fun extractValue(
        structure: android.app.assist.AssistStructure,
        autofillId: AutofillId?,
    ): String? {
        if (autofillId == null) return null

        for (i in 0 until structure.windowNodeCount) {
            val window = structure.getWindowNodeAt(i)
            val value = findValueInNode(window.rootViewNode, autofillId)
            if (value != null) return value
        }
        return null
    }

    private fun findValueInNode(
        node: android.app.assist.AssistStructure.ViewNode,
        targetId: AutofillId,
    ): String? {
        if (node.autofillId == targetId) {
            val value = node.autofillValue
            if (value != null && value.isText) {
                return value.textValue?.toString()
            }
        }
        for (i in 0 until node.childCount) {
            val result = findValueInNode(node.getChildAt(i), targetId)
            if (result != null) return result
        }
        return null
    }

    companion object {
        const val ACTION_CREDENTIAL_SAVED = "io.nexpass.CREDENTIAL_SAVED"
        const val EXTRA_UUID = "uuid"
        const val EXTRA_NAME = "name"
        const val EXTRA_USERNAME = "username"
        const val EXTRA_PASSWORD = "password"
        const val EXTRA_PACKAGE = "package"
    }
}

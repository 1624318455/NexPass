package io.nexpass

import android.os.CancellationSignal
import android.service.autofill.AutofillService
import android.service.autofill.FillCallback
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.SaveCallback
import android.service.autofill.SaveRequest
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.content.Context

/**
 * Android system AutofillService for NexPass.
 *
 * Lifecycle:
 * 1. Android detects a login form → calls [onFillRequest].
 * 2. We parse the [AutofillStructure] to find username/password fields.
 * 3. We present an inline suggestion that, when tapped, launches [AuthActivity]
 *    to verify the user via biometric before injecting credentials.
 * 4. Android calls [onSaveRequest] when the user submits new credentials.
 */
class NexPassAutofillService : AutofillService() {

    companion object {
        const val REQUEST_AUTH = 101
        const val EXTRA_PACKAGE_NAME = "PACKAGE_NAME"
        const val EXTRA_AUTOFILL_IDS = "AUTOFILL_IDS"
    }

    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback
    ) {
        val context = this
        val structure = request.fillContexts.last().structure
        val parser = AutofillStructureParser(structure)

        val usernameId = parser.usernameId
        val passwordId = parser.passwordId
        val targetPackage = parser.packageName

        // No fillable fields found — pass
        if (usernameId == null && passwordId == null) {
            callback.onSuccess(null)
            return
        }

        // ── Build authentication intent ──────────────────────────
        val authIntent = Intent(context, AuthActivity::class.java).apply {
            putExtra(EXTRA_PACKAGE_NAME, targetPackage)
            putExtra(EXTRA_AUTOFILL_IDS, collectAutofillIds(usernameId, passwordId))
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            REQUEST_AUTH,
            authIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )

        // ── Build inline suggestion view ─────────────────────────
        val presentation = buildSuggestionPresentation(context)

        // ── Build dataset with authentication ────────────────────
        val datasetBuilder = Dataset.Builder(presentation)

        if (usernameId != null) {
            datasetBuilder.setValue(
                usernameId,
                AutofillValue.forText("Tap to fill from NexPass"),
                presentation
            )
        }

        if (passwordId != null) {
            datasetBuilder.setValue(
                passwordId,
                AutofillValue.forText(""),
                presentation
            )
        }

        datasetBuilder.setAuthentication(pendingIntent.intentSender)

        // ── Build response ───────────────────────────────────────
        val responseBuilder = FillResponse.Builder()
        responseBuilder.addDataset(datasetBuilder.build())

        // Optional: add a "save" credential UI for new logins
        responseBuilder.setSaveInfo(
            android.service.autofill.SaveInfo.Builder(
                SaveInfo.SAVE_DATA_TYPE_GENERIC,
                collectAutofillIds(usernameId, passwordId)
            ).build()
        )

        callback.onSuccess(responseBuilder.build())
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) {
        // In production: extract the new credentials from SaveRequest.structure
        // and offer to save them into the NexPass vault via MethodChannel.
        callback.onSuccess()
    }

    // ── Helpers ─────────────────────────────────────────────────────

    private fun buildSuggestionPresentation(context: Context): RemoteViews {
        return RemoteViews(context.packageName, R.layout.autofill_inline_suggestion).apply {
            setTextViewText(R.id.autofill_text, "NexPass — Tap to fill")
            setImageViewResource(R.id.autofill_icon, R.drawable.ic_nexpass_shield)
        }
    }

    private fun collectAutofillIds(vararg ids: AutofillId?): List<AutofillId> {
        return ids.filterNotNull().toList()
    }
}

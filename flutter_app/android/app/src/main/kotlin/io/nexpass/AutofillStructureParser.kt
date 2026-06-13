package io.nexpass

import android.app.assist.AssistStructure
import android.view.autofill.AutofillId

/**
 * Parses Android AssistStructure to identify autofill-relevant fields
 * (username/email and password inputs).
 *
 * Traverses the ViewNode tree recursively, applying heuristic matching
 * on hint text and input types.
 */
class AutofillStructureParser(private val structure: AssistStructure) {

    var usernameId: AutofillId? = null
        private set
    var passwordId: AutofillId? = null
        private set
    var packageName: String = ""
        private set

    init {
        packageName = structure.activityComponent.packageName
        parse()
    }

    private fun parse() {
        for (i in 0 until structure.windowNodeCount) {
            val window = structure.getWindowNodeAt(i)
            traverseNode(window.rootViewNode)
        }
    }

    private fun traverseNode(node: AssistStructure.ViewNode) {
        val id = node.autofillId
        val hints = node.autofillHints
        val hint = (node.hint?.toString() ?: "").lowercase()
        val inputType = node.inputType

        if (id != null) {
            // ── Check explicit autofill hints first ─────────────────
            if (hints != null) {
                for (h in hints) {
                    val lower = h.lowercase()
                    when {
                        USERNAME_HINTS.any { lower.contains(it) } && usernameId == null ->
                            usernameId = id
                        PASSWORD_HINTS.any { lower.contains(it) } && passwordId == null ->
                            passwordId = id
                    }
                }
            }

            // ── Fallback: check hint text and input type ───────────
            if (usernameId == null && isUsernameField(hint, inputType)) {
                usernameId = id
            }
            if (passwordId == null && isPasswordField(hint, inputType)) {
                passwordId = id
            }
        }

        // Recurse into children
        for (i in 0 until node.childCount) {
            traverseNode(node.getChildAt(i))
        }
    }

    private fun isUsernameField(hint: String, inputType: Int): Boolean {
        if (hint.isNotEmpty()) {
            if (USERNAME_HINTS.any { hint.contains(it) }) return true
        }

        val typeClass = inputType and android.text.InputType.TYPE_MASK_CLASS
        val typeVariation = inputType and android.text.InputType.TYPE_MASK_VARIATION

        return typeClass == android.text.InputType.TYPE_CLASS_TEXT &&
            (typeVariation == android.text.InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS ||
             typeVariation == android.text.InputType.TYPE_TEXT_VARIATION_WEB_EMAIL_ADDRESS)
    }

    private fun isPasswordField(hint: String, inputType: Int): Boolean {
        if (hint.isNotEmpty()) {
            if (PASSWORD_HINTS.any { hint.contains(it) }) return true
        }

        val typeClass = inputType and android.text.InputType.TYPE_MASK_CLASS
        val typeVariation = inputType and android.text.InputType.TYPE_MASK_VARIATION

        if (typeClass == android.text.InputType.TYPE_CLASS_TEXT) {
            return typeVariation == android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                typeVariation == android.text.InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD ||
                typeVariation == android.text.InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD
        }

        return false
    }

    companion object {
        private val USERNAME_HINTS = listOf(
            "user", "email", "login", "account", "phone", "mobile", "name",
        )
        private val PASSWORD_HINTS = listOf(
            "pass", "password", "pin", "code", "secret", "otp",
        )
    }
}

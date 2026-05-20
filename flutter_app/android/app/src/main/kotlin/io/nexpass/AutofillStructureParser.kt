package io.nexpass

import android.view.View
import android.view.autofill.AutofillId
import android.view.autofill.AutofillStructure

/**
 * Parses the [AutofillStructure] tree to locate username and password fields
 * based on Android's semantic hints (autofill hints, HTML attributes, view IDs).
 */
class AutofillStructureParser(private val structure: AutofillStructure) {

    var usernameId: AutofillId? = null
        private set

    var passwordId: AutofillId? = null
        private set

    var packageName: String = ""
        private set

    init {
        parse()
    }

    private fun parse() {
        packageName = structure.activityComponent?.packageName ?: ""
        traverseNode(structure, 0)
    }

    private fun traverseNode(node: AutofillStructure.ViewNode, depth: Int) {
        if (depth > 20) return // Prevent deep recursion

        val autofillHints = node.autofillHints
        val viewHint = node.hint?.lowercase() ?: ""
        val viewIdEntry = node.idEntry?.lowercase() ?: ""

        // Detect username field
        if (usernameId == null && isUsernameField(autofillHints, viewHint, viewIdEntry)) {
            usernameId = node.autofillId
        }

        // Detect password field
        if (passwordId == null && isPasswordField(autofillHints, viewHint, viewIdEntry)) {
            passwordId = node.autofillId
        }

        // Recurse into child nodes
        val childCount = node.childCount
        for (i in 0 until childCount) {
            val child = node.getChildAt(i) ?: continue
            traverseNode(child, depth + 1)
        }
    }

    private fun isUsernameField(
        hints: Array<out CharSequence>?,
        viewHint: String,
        viewId: String
    ): Boolean {
        // Check Android autofill hints
        if (hints != null) {
            for (hint in hints) {
                val h = hint.toString().lowercase()
                if (h.contains("username") || h.contains("email") ||
                    h.contains("user") || h.contains("login")
                ) {
                    return true
                }
            }
        }

        // Fallback: check view hint and ID
        val combined = "$viewHint $viewId"
        return combined.contains("user") || combined.contains("email") ||
                combined.contains("login") || combined.contains("account")
    }

    private fun isPasswordField(
        hints: Array<out CharSequence>?,
        viewHint: String,
        viewId: String
    ): Boolean {
        if (hints != null) {
            for (hint in hints) {
                val h = hint.toString().lowercase()
                if (h.contains("password") || h.contains("pass") ||
                    h.contains("secret")
                ) {
                    return true
                }
            }
        }

        val combined = "$viewHint $viewId"
        return combined.contains("pass") || combined.contains("secret")
    }
}

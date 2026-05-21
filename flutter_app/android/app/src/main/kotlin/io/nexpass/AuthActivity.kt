package io.nexpass

import android.app.Activity
import android.os.Bundle

/**
 * Stub biometric auth activity.
 * Full implementation will use BiometricPrompt before
 * releasing credentials to the AutofillService.
 */
class AuthActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        finish()
    }
}

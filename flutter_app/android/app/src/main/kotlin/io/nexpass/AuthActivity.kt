package io.nexpass

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Transparent activity launched by [NexPassAutofillService] to trigger
 * biometric authentication before releasing credentials.
 *
 * After successful authentication, it invokes the Dart-side
 * `autofill/fillCredential` method channel and finishes itself.
 */
class AuthActivity : Activity() {

    companion object {
        private const val CHANNEL = "io.nexpass.app/autofill"
        private const val EXTRA_PACKAGE_NAME = "PACKAGE_NAME"
    }

    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val targetPackage = intent?.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""

        // In production, this would show a BiometricPrompt.
        // For the stub, we simulate immediate success and query Dart directly.
        queryDartForCredentials(targetPackage)
    }

    private fun queryDartForCredentials(targetPackage: String) {
        // Access the Flutter engine's method channel
        val engine = FlutterEngine(this)

        // For a real app, we would use the existing engine from the FlutterActivity.
        // Here we demonstrate the channel protocol.
        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.invokeMethod(
            "queryMatchingCredentials",
            mapOf("domain" to targetPackage)
        ) { result ->
            if (result.isSuccess) {
                val credentials = result.getOrNull() as? List<*> ?: emptyList<Any>()
                // In production: inject the first matching credential
                // back to the calling AutofillService via FillCallback.
                finish()
            } else {
                finish()
            }
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
}

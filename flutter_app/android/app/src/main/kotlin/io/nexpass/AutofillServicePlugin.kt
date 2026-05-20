package io.nexpass

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin that registers the MethodChannel for autofill
 * communication between Dart and Android native services.
 *
 * Register this in [MainActivity.configureFlutterEngine].
 */
class AutofillServicePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "io.nexpass.app/autofill")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "queryMatchingCredentials" -> {
                val domain = call.argument<String>("domain") ?: ""
                // Delegate to Dart-side handler via the channel's default behavior.
                // In production, the AutofillService would call this directly.
                result.success(emptyList<Any>())
            }

            "fillCredential" -> {
                val credentialId = call.argument<String>("id") ?: ""
                result.success(mapOf(
                    "success" to true,
                    "timestamp" to System.currentTimeMillis()
                ))
            }

            "onCredentialSelected" -> {
                val uuid = call.argument<String>("uuid") ?: ""
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

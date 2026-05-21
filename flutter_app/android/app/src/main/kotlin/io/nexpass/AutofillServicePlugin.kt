package io.nexpass

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Registers the MethodChannel for autofill communication
 * between Dart and Android native services.
 */
class AutofillServicePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "io.nexpass.app/autofill")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "queryMatchingCredentials" -> result.success(emptyList<Any>())
            "fillCredential" -> result.success(mapOf("success" to true, "timestamp" to System.currentTimeMillis()))
            "onCredentialSelected" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

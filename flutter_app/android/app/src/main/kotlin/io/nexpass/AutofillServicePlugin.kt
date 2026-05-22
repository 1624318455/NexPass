package io.nexpass

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Registers the MethodChannel for autofill communication
 * between Dart and Android native services.
 */
class AutofillServicePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private var pluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        pluginBinding = binding
        channel = MethodChannel(binding.binaryMessenger, "io.nexpass.app/autofill")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "queryMatchingCredentials" -> result.success(emptyList<Any>())
            "fillCredential" -> result.success(mapOf("success" to true, "timestamp" to System.currentTimeMillis()))
            "onCredentialSelected" -> result.success(null)
            "openAutofillSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_SET_AUTOFILL_SERVICE)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    pluginBinding?.applicationContext?.startActivity(intent)
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
        pluginBinding = null
    }
}

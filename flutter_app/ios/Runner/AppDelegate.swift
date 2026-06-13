import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    /// MethodChannel for communicating URL scheme events to Flutter.
    private var urlSchemeChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // MARK: - URL Scheme Handling

    /// Handles `nexpass://autofill/<uuid>` URLs from the CredentialProvider extension.
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        guard url.scheme == "nexpass" else { return false }

        NSLog("[AppDelegate] Handling URL: \(url.absoluteString)")

        switch url.host {
        case "autofill":
            let uuid = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard !uuid.isEmpty else { return false }

            // Forward to Flutter via MethodChannel
            if let engine = self.flutterEngine {
                let channel = FlutterMethodChannel(
                    name: "io.nexpass.app/url_scheme",
                    binaryMessenger: engine.binaryMessenger
                )
                channel.invokeMethod("autofillRequest", arguments: uuid)
            }
            return true

        default:
            return false
        }
    }

    // MARK: - MethodChannel for PasswordCache

    /// Sets up a MethodChannel so Flutter can manage the password cache.
    /// Called lazily when Flutter engine is available.
    private func getOrCreateChannel() -> FlutterMethodChannel? {
        if let existing = urlSchemeChannel { return existing }

        guard let engine = self.flutterEngine else { return nil }

        let channel = FlutterMethodChannel(
            name: "io.nexpass.app/password_cache",
            binaryMessenger: engine.binaryMessenger
        )

        channel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "cachePasswords":
                self?.handleCachePasswords(call: call, result: result)
            case "clearPasswordCache":
                PasswordCache.clear()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        urlSchemeChannel = channel
        return channel
    }

    private func handleCachePasswords(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [[String: Any]] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected array", details: nil))
            return
        }

        let credentials = args.compactMap { dict -> (uuid: String, username: String, password: String)? in
            guard let uuid = dict["uuid"] as? String,
                  let username = dict["username"] as? String,
                  let password = dict["password"] as? String else {
                return nil
            }
            return (uuid: uuid, username: username, password: password)
        }

        PasswordCache.savePasswords(credentials)
        result(true)
    }
}

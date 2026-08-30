import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let fileChannel = "notey/device"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      setupMethodChannel(controller: controller)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func setupMethodChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(name: fileChannel, binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "openFile":
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "badArgs", message: "path is required", details: nil))
          return
        }
        result(self?.openFile(path: path) ?? false)
      case "openBiometricSettings":
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func openFile(path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else { return false }
    let controller = UIApplication.shared.keyWindow?.rootViewController
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    controller?.present(activityVC, animated: true)
    return true
  }
}

import Flutter
import UIKit
import Firebase
import CoreTelephony

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()   // <- Do this
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let phoneChannel = FlutterMethodChannel(
      name: "com.roomify.app/phone",
      binaryMessenger: controller.binaryMessenger
    )
    
    phoneChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "getPhoneNumber" else {
        result(FlutterMethodNotImplemented)
        return
      }
      
      // iOS doesn't provide direct access to phone number for privacy reasons
      // Return empty string to indicate no phone number available
      result("")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

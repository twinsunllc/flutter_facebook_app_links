import FBSDKCoreKit
import Flutter
import UIKit


public class SwiftFlutterFacebookAppLinksPlugin: NSObject, FlutterPlugin {

  var deepLinkUrl:String = ""

  public static func register(with registrar: FlutterPluginRegistrar) {

    let instance = SwiftFlutterFacebookAppLinksPlugin()
    let channel = FlutterMethodChannel(name: "plugins.remedia.it/flutter_facebook_app_links", binaryMessenger: registrar.messenger())

    // Get user consent
    print("FB APP LINK registering plugin")

    instance.initializeSDK()
    
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addApplicationDelegate(instance)
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    // detach
  }

  public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {

      Settings.shared.isAdvertiserTrackingEnabled = false
      print("FB APP LINKS: ⚠️ Advertiser tracking DISABLED by default. Call setAdvertiserTrackingEnabled(true) after ATT permission to enable Facebook attribution!")

      // Call Facebook SDK's didFinishLaunchingWithOptions via dynamic Objective-C selector
      // This is needed because the Swift method is gated behind Swift 6.2+ NonescapableTypes feature
      let selector = NSSelectorFromString("application:didFinishLaunchingWithOptions:")
      if ApplicationDelegate.shared.responds(to: selector) {
          let launchOptionsForFacebook = launchOptions as? [UIApplication.LaunchOptionsKey: Any]
          _ = ApplicationDelegate.shared.perform(selector, with: application, with: launchOptionsForFacebook)
      } else {
          // Fallback to initializeSDK if method not available
          ApplicationDelegate.shared.initializeSDK()
      }

      AppLinkUtility.fetchDeferredAppLink{ (url, error) in
          if let error = error{
              print("Error %a", error)
          }
          if let url = url {
              self.deepLinkUrl = url.absoluteString
              // self.sendMessageToStream(link: self.deepLinkUrl)
          }
      }
      return true
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    // CUSTOM PRIVACY METHODS
    case "consentProvided":
        Settings.shared.isAutoLogAppEventsEnabled = true
        ApplicationDelegate.shared.initializeSDK()
        result(nil)
    case "consentRevoked":
        Settings.shared.isAutoLogAppEventsEnabled = false
        ApplicationDelegate.shared.initializeSDK()
        result(nil)
    case "setAdvertiserTrackingEnabled":
        if let arguments = call.arguments as? [String: Any],
           let enabled = arguments["enabled"] as? Bool {
            ApplicationDelegate.shared.initializeSDK()
            Settings.shared.isAdvertiserTrackingEnabled = enabled
            print("FB APP LINKS: Advertiser tracking set to \(enabled ? "ENABLED" : "DISABLED") for Facebook attribution")
            result(nil)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Expected boolean 'enabled' parameter",
                              details: nil))
        }

    // UPSTREAM FACEBOOK SDK 18 METHODS
    case "getPlatformVersion":
        handleGetPlatformVersion(call, result: result)
    case "initFBLinks":
        ApplicationDelegate.shared.initializeSDK()
        result("")
    case "getDeepLinkUrl":
        result(deepLinkUrl)
    case "activateApp":
        AppEvents.shared.activateApp()
        result(true)
    default:
        result(FlutterMethodNotImplemented)
    }
  }


  private func handleGetPlatformVersion(_: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }

  public func initializeSDK() {
    ApplicationDelegate.shared.initializeSDK()
  }
}

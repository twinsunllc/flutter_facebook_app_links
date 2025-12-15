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
      let launchOptionsForFacebook = launchOptions as? [UIApplication.LaunchOptionsKey: Any]
      ApplicationDelegate.shared.application(
          application,
          didFinishLaunchingWithOptions:
              launchOptionsForFacebook
      )
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
        result(nil)
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

  private func handleFBAppLinks(_: FlutterMethodCall, result: @escaping FlutterResult) {
    print("FB APP LINKS Starting ")

    AppLinkUtility.fetchDeferredAppLink { url, error in
      if let error = error {
        print("Received error while fetching deferred app link %@", error)
        result(nil)
      }

      if let url = url {
        print("FB APP LINKS getting url: ", String(url.absoluteString))

        var mapData: [String: String?] = ["deeplink": url.absoluteString, "promotionalCode": nil]

        if let code = AppLinkUtility.appInvitePromotionCode(from: url) {
          print("promotional code " + String(code))
          mapData["promotionalCode"] = code
        } else { // nil
        }

        if #available(iOS 10, *) {
          result(mapData)
        } else {
          result(mapData)
        }
      } else {
        // no deep link received
        result(nil)
      }
    }
  }


  public func initializeSDK() {
    ApplicationDelegate.shared.initializeSDK()
  }

  private func handleGetDeepLinkUrl(_: FlutterMethodCall, result: @escaping FlutterResult) {
    print("FB APP LINKS getDeepLinkUrl Starting ")

    AppLinkUtility.fetchDeferredAppLink { url, error in
      if let error = error {
        print("Received error while fetching deferred app link %@", error)
        result("")
      }

      if let url = url {
        print("FB APP LINKS getDeepLinkUrl getting url: ", String(url.absoluteString))
        result(url.absoluteString)
      } else {
        // no deep link received
        result("")
      }
    }
  }
}

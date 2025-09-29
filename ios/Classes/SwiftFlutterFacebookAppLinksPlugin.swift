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
    case "consentProvided":
      Settings.shared.isAutoLogAppEventsEnabled = true
      ApplicationDelegate.shared.initializeSDK()
      result(nil)
    case "consentRevoked":
      Settings.shared.isAutoLogAppEventsEnabled = false
      ApplicationDelegate.shared.initializeSDK()
      result(nil)
    case "getPlatformVersion":
      handleGetPlatformVersion(call, result: result)
    case "initFBLinks":
      print("FB APP LINK launched")
      handleFBAppLinks(call, result: result)
    case "getDeepLinkUrl":
      print("FB APP LINK getDeepLinkUrl called")
      result(deepLinkUrl)
    case "activateApp":
      AppEvents.shared.activateApp()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleGetPlatformVersion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }

  private func handleFBAppLinks(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("FB APP LINKS Starting ")

    AppLinkUtility.fetchDeferredAppLink { url, error in
      if let error = error {
        print("Received error while fetching deferred app link %@", error)
        result("")
      }

      if let url = url {
        print("FB APP LINKS getting url: ", String(url.absoluteString))
        result(url.absoluteString)
      } else {
        // no deep link received
        result("")
      }
    }
  }

  public func initializeSDK() {
    ApplicationDelegate.shared.initializeSDK()
  }
}

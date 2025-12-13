import FBSDKCoreKit
import Flutter
import UIKit

public class SwiftFlutterFacebookAppLinksPlugin: NSObject, FlutterPlugin {
  // fileprivate var resulter: FlutterResult? = nil

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "plugins.remedia.it/flutter_facebook_app_links", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterFacebookAppLinksPlugin()

    // Get user consent
    print("FB APP LINK registering plugin")
    ApplicationDelegate.shared.initializeSDK()

    registrar.addMethodCallDelegate(instance, channel: channel)
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
    case "setAdvertiserTrackingEnabled":
      if let arguments = call.arguments as? [String: Any],
         let enabled = arguments["enabled"] as? Bool {
        // Ensure SDK is initialized before setting tracking preferences
        ApplicationDelegate.shared.initializeSDK()
        Settings.shared.isAdvertiserTrackingEnabled = enabled
        result(nil)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENTS",
                          message: "Expected boolean 'enabled' parameter",
                          details: nil))
      }
    case "logEvent":
      handleLogEvent(call, result: result)
    case "getPlatformVersion":
      handleGetPlatformVersion(call, result: result)
    case "initFBLinks":
      print("FB APP LINK launched")
      handleFBAppLinks(call, result: result)
    case "getDeepLinkUrl":
      print("FB APP LINK getDeepLinkUrl called")
      handleGetDeepLinkUrl(call, result: result)
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

  private func handleLogEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let eventName = arguments["eventName"] as? String,
          !eventName.isEmpty else {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                        message: "Event name cannot be null or empty",
                        details: nil))
      return
    }

    // Ensure SDK is initialized before logging events
    ApplicationDelegate.shared.initializeSDK()

    // Get parameters dictionary (can be nil/empty)
    let parameters = arguments["parameters"] as? [String: Any] ?? [:]

    // Convert parameters to proper types for AppEvents
    var eventParameters: [AppEvents.ParameterName: Any] = [:]

    for (key, value) in parameters {
      // Create custom parameter name from the key string
      let parameterName = AppEvents.ParameterName(rawValue: key)

      // Add the value with proper type handling
      if let stringValue = value as? String {
        eventParameters[parameterName] = stringValue
      } else if let numberValue = value as? NSNumber {
        eventParameters[parameterName] = numberValue
      } else if let intValue = value as? Int {
        eventParameters[parameterName] = intValue
      } else if let doubleValue = value as? Double {
        eventParameters[parameterName] = doubleValue
      } else if let boolValue = value as? Bool {
        eventParameters[parameterName] = boolValue
      } else {
        // Fallback: convert to string
        eventParameters[parameterName] = String(describing: value)
      }
    }

    // Log the event
    AppEvents.shared.logEvent(AppEvents.Name(rawValue: eventName), parameters: eventParameters)

    result(nil)
  }
}

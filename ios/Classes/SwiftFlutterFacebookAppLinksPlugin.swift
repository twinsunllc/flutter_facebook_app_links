import FBSDKCoreKit
import Flutter
import UIKit


public class SwiftFlutterFacebookAppLinksPlugin: NSObject, FlutterPlugin {

  // Cached deep link URL from app launch (populated in didFinishLaunchingWithOptions)
  // Provides fast access while maintaining thread safety (only accessed from main thread)
  var cachedDeepLinkUrl: String = ""

  public static func register(with registrar: FlutterPluginRegistrar) {

    let instance = SwiftFlutterFacebookAppLinksPlugin()
    let channel = FlutterMethodChannel(name: "plugins.remedia.it/flutter_facebook_app_links", binaryMessenger: registrar.messenger())

    // Get user consent
    print("FB APP LINK registering plugin")

    // Removed redundant initializeSDK() call - SDK is initialized in didFinishLaunchingWithOptions
    // and individual methods call initializeSDK() as needed

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

      // Cache deep link URL for fast access during app lifecycle
      // This provides immediate response for initFBLinks while avoiding blocking UI
      AppLinkUtility.fetchDeferredAppLink{ (url, error) in
          if let error = error {
              print("FB APP LINKS: Error fetching deferred deep link: \(error)")
          } else if let url = url {
              self.cachedDeepLinkUrl = url.absoluteString
              print("FB APP LINKS: Cached deep link URL: \(self.cachedDeepLinkUrl)")
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
    case "logEvent":
      handleLogEvent(call, result: result)
    
    // UPSTREAM FACEBOOK SDK 18 METHODS
    case "getPlatformVersion":
        handleGetPlatformVersion(call, result: result)
    case "initFBLinks":
        ApplicationDelegate.shared.initializeSDK()
        // HYBRID APPROACH: Return cached value immediately for fast UX,
        // fallback to on-demand fetch only if cache is empty
        // This provides platform consistency with Android while avoiding blocking UI
        if !cachedDeepLinkUrl.isEmpty {
            // ✅ FAST: Return cached value from app launch immediately
            result(cachedDeepLinkUrl)
        } else {
            // Fallback: Fetch on-demand (only if cache not populated yet)
            // This handles edge cases where initFBLinks is called before didFinishLaunchingWithOptions
            AppLinkUtility.fetchDeferredAppLink{ (url, error) in
                if let error = error {
                    print("FB APP LINKS: Error fetching deferred deep link: \(error)")
                    result("")
                } else if let url = url {
                    self.cachedDeepLinkUrl = url.absoluteString  // Cache for future calls
                    result(url.absoluteString)
                } else {
                    result("")
                }
            }
        }
    case "getDeepLinkUrl":
        // Always fetch on-demand to eliminate race conditions and ensure fresh data
        AppLinkUtility.fetchDeferredAppLink{ (url, error) in
            if let error = error {
                print("FB APP LINKS: Error fetching deferred deep link: \(error)")
                result("")
            } else if let url = url {
                result(url.absoluteString)
            } else {
                result("")
            }
        }
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

  private func handleLogEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let eventName = arguments["eventName"] as? String,
          !eventName.isEmpty else {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                        message: "Event name cannot be null or empty",
                        details: nil))
      return
    }

    // Validate event name format (defense in depth - mirror Dart validation)
    if eventName.count > 40 {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                        message: "Event name must be 1-40 characters",
                        details: nil))
      return
    }

    // Validate event name contains only alphanumeric characters and underscores
    let eventNamePattern = "^[a-zA-Z0-9_]+$"
    let eventNameRegex = try? NSRegularExpression(pattern: eventNamePattern, options: [])
    let eventNameRange = NSRange(location: 0, length: eventName.count)
    if eventNameRegex?.firstMatch(in: eventName, options: [], range: eventNameRange) == nil {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                        message: "Event name must contain only alphanumeric characters and underscores",
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

      // Check specific types first to avoid NSNumber overlap
      if let stringValue = value as? String {
        eventParameters[parameterName] = stringValue
      } else if let intValue = value as? Int {
        eventParameters[parameterName] = intValue
      } else if let doubleValue = value as? Double {
        eventParameters[parameterName] = doubleValue
      } else if let boolValue = value as? Bool {
        eventParameters[parameterName] = boolValue
      } else {
        // Fallback for unexpected types
        eventParameters[parameterName] = String(describing: value)
      }
    }

    // Log the event
    AppEvents.shared.logEvent(AppEvents.Name(rawValue: eventName), parameters: eventParameters)

    result(nil)
  }
}

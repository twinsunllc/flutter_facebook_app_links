import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

class FlutterFacebookAppLinks {
  static const MethodChannel _channel = const MethodChannel("plugins.remedia.it/flutter_facebook_app_links");

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> initFBLinks() async {
    try {
      var data = await _channel.invokeMethod('initFBLinks');
      debugPrint('Deferred FB Link: $data');
      return data ?? '';
    } catch (e) {
      debugPrint("Error initializing FlutterFacebookAppLinks: $e");

      return '';
    }
  }

  static Future<String> getDeepLink() async {
    try {
      var data = await _channel.invokeMethod('getDeepLinkUrl');
      debugPrint('Deferred FB Link: $data');
      return data ?? '';
    } catch (e) {
      debugPrint("Error retrieving deferred deep link: $e");

      return '';
    }
  }

  static Future<dynamic> consentProvided() {
    return _channel.invokeMethod('consentProvided');
  }

  static Future<dynamic> consentRevoked() {
    return _channel.invokeMethod('consentRevoked');
  }

  /// Sets the advertiser tracking enabled status for Facebook SDK.
  ///
  /// This method controls advertiser tracking permissions with platform-specific behavior:
  ///
  /// **iOS**: Controls `Settings.shared.isAdvertiserTrackingEnabled`
  /// - Determines whether the SDK reports tracking as enabled to Facebook
  /// - Required for proper attribution after ATT permission approval
  /// - Set after obtaining user consent via App Tracking Transparency
  ///
  /// **Android**: Controls `FacebookSdk.setAdvertiserIDCollectionEnabled`
  /// - Enables/disables collection of the advertising ID by the SDK
  /// - Controls privacy-sensitive advertising identifier usage
  /// - Set based on user privacy preferences
  ///
  /// This method automatically initializes the Facebook SDK if not already initialized.
  /// Call this after obtaining ATT permission on iOS and before calling consentProvided()
  /// or consentRevoked().
  ///
  /// [enabled] - Whether advertiser tracking should be enabled based on user consent
  ///
  /// Throws [PlatformException] if the platform-specific call fails, for example
  /// if there are permission issues or platform errors
  static Future<void> setAdvertiserTrackingEnabled(bool enabled) async {
    await _channel.invokeMethod('setAdvertiserTrackingEnabled', {'enabled': enabled});
  }

  static Future<void> activateSDK() async {
    try {
      debugPrint('Activating SDK');
      await _channel.invokeMethod('activateApp');
    } catch (e) {
      debugPrint("Error activating SDK: $e");
    }
  }
}

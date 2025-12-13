import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterFacebookAppLinks {
  static const MethodChannel _channel = const MethodChannel("plugins.remedia.it/flutter_facebook_app_links");

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<dynamic> initFBLinks() async {
    try {
      var data = await _channel.invokeMethod('initFBLinks');

      if (data == null) return null;

      final Map<String, String> result = new Map.from(data);
      return result;
    } catch (e) {
      debugPrint("Error retrieving deferred deep link: $e");

      return null;
    }
  }

  static Future<String> getDeepLink() async {
    try {
      var data = await _channel.invokeMethod('getDeepLinkUrl');
      print('Deferred FB Link: $data');
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

  /// Logs a custom event with Facebook Analytics.
  ///
  /// This method allows you to track custom events and user actions in your app.
  /// Events can be used for analytics, optimization, and creating custom audiences.
  ///
  /// **Important**: Ensure you have called [consentProvided] and obtained necessary
  /// user permissions before logging events to comply with privacy regulations.
  ///
  /// **Platform Support**: Both iOS and Android
  ///
  /// Common event names include:
  /// - Standard events: 'fb_mobile_complete_registration', 'fb_mobile_add_to_cart',
  ///   'fb_mobile_purchase', 'fb_mobile_initiated_checkout'
  /// - Custom events: Any string describing the action (e.g., 'trial_started', 'level_achieved')
  ///
  /// [eventName] - The name of the event to log. Use standard Facebook event names
  ///               or create custom event names (max 40 characters, alphanumeric + underscore)
  ///
  /// [parameters] - Optional map of parameters to attach to the event.
  ///                Common parameter keys include:
  ///                - '_valueToSum': Numeric value for aggregation (e.g., price)
  ///                - 'fb_currency': Three-letter ISO 4217 currency code (e.g., 'USD')
  ///                - 'fb_content_type': Type of content (e.g., 'product', 'article')
  ///                - 'fb_content_id': ID of the content
  ///                - Custom parameters: Any key-value pairs relevant to your event
  ///
  /// Example:
  /// ```dart
  /// // Log a simple event
  /// await FlutterFacebookAppLinks.logEvent('trial_started');
  ///
  /// // Log an event with parameters
  /// await FlutterFacebookAppLinks.logEvent('product_viewed', {
  ///   'fb_content_id': 'product_123',
  ///   'fb_content_type': 'product',
  ///   '_valueToSum': 29.99,
  ///   'fb_currency': 'USD'
  /// });
  /// ```
  ///
  /// Throws [PlatformException] if the platform-specific call fails
  static Future<void> logEvent(String eventName, [Map<String, dynamic>? parameters]) async {
    try {
      await _channel.invokeMethod('logEvent', {
        'eventName': eventName,
        'parameters': parameters ?? {},
      });
    } catch (e) {
      debugPrint("Error logging Facebook event '$eventName': $e");
      rethrow;
    }
  }

  /// Logs a purchase event with Facebook Analytics.
  ///
  /// This is a convenience method for logging purchase events, which are crucial
  /// for tracking conversions and ROI from Facebook ads.
  ///
  /// **Important**: Ensure you have called [consentProvided] before logging events.
  ///
  /// [amount] - The purchase amount (e.g., 29.99)
  /// [currency] - Three-letter ISO 4217 currency code (e.g., 'USD', 'EUR', 'GBP')
  /// [parameters] - Optional additional parameters (e.g., content_id, content_type, num_items)
  ///
  /// Example:
  /// ```dart
  /// await FlutterFacebookAppLinks.logPurchaseEvent(
  ///   49.99,
  ///   'USD',
  ///   {'fb_content_id': 'sku_12345', 'fb_num_items': 2}
  /// );
  /// ```
  ///
  /// Throws [PlatformException] if the platform-specific call fails
  static Future<void> logPurchaseEvent(
    double amount,
    String currency, [
    Map<String, dynamic>? parameters,
  ]) async {
    try {
      final Map<String, dynamic> params = Map.from(parameters ?? {});
      params['fb_currency'] = currency;
      params['_valueToSum'] = amount;

      await _channel.invokeMethod('logEvent', {
        'eventName': 'fb_mobile_purchase',
        'parameters': params,
      });
    } catch (e) {
      debugPrint("Error logging Facebook purchase event: $e");
      rethrow;
    }
  }

  /// Logs a registration completion event with Facebook Analytics.
  ///
  /// Use this method when a user completes the registration process in your app.
  /// This is a standard Facebook event used for conversion tracking.
  ///
  /// **Important**: Ensure you have called [consentProvided] before logging events.
  ///
  /// [registrationMethod] - Optional method used for registration (e.g., 'email', 'facebook', 'google')
  ///
  /// Example:
  /// ```dart
  /// await FlutterFacebookAppLinks.logCompleteRegistration('email');
  /// ```
  ///
  /// Throws [PlatformException] if the platform-specific call fails
  static Future<void> logCompleteRegistration([String? registrationMethod]) async {
    try {
      final Map<String, dynamic> params = {};
      if (registrationMethod != null) {
        params['fb_registration_method'] = registrationMethod;
      }

      await _channel.invokeMethod('logEvent', {
        'eventName': 'fb_mobile_complete_registration',
        'parameters': params,
      });
    } catch (e) {
      debugPrint("Error logging Facebook registration event: $e");
      rethrow;
    }
  }
}

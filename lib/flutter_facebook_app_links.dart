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
  /// This method controls whether the Facebook SDK reports advertiser tracking
  /// as enabled to Facebook servers. Call this after obtaining ATT permission
  /// on iOS and before calling consentProvided() or consentRevoked().
  ///
  /// On iOS: Controls Settings.shared.isAdvertiserTrackingEnabled
  /// On Android: Controls FacebookSdk.setAdvertiserIDCollectionEnabled
  ///
  /// [enabled] - Whether advertiser tracking should be enabled based on user consent
  ///
  /// Throws [PlatformException] if the platform-specific call fails, for example
  /// if the Facebook SDK is not properly initialized or if there are permission issues
  static Future<void> setAdvertiserTrackingEnabled(bool enabled) async {
    await _channel.invokeMethod('setAdvertiserTrackingEnabled', {'enabled': enabled});
  }
}

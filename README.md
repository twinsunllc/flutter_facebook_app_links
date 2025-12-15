# Flutter Facebook App Links

Flutter plugin for [Facebook App Links SDK](https://developers.facebook.com/docs/app-ads/deep-linking/). This plugin must be used to catch deferred deeplinks sent from Facebook after your app has been installed from a FB ADS.

## Getting Started

First of all, if you don't have one already, you must first create an app at Facebook developers: https://developers.facebook.com/

## ⚠️ CRITICAL: Default iOS Tracking Behavior (Affects Facebook Attribution)

**Facebook advertising tracking is DISABLED by default on iOS.** If you do not implement the proper ATT permission flow and call `setAdvertiserTrackingEnabled(true)`, Facebook attribution (including StoreKit2 purchase events) will not work.

### Required iOS Initialization for Attribution

```dart
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

// In your app's main initialization:
if (Platform.isIOS) {
  // 1. Request ATT permission
  var status = await AppTrackingTransparency.requestTrackingAuthorization();
  
  // 2. Enable Facebook tracking after consent (REQUIRED for attribution!)
  if (status == TrackingStatus.authorized) {
    await FlutterFacebookAppLinks.setAdvertiserTrackingEnabled(true);  // <-- THIS IS CRITICAL
    await FlutterFacebookAppLinks.consentProvided();
  }
}

Get your app id (referred to as `[APP_ID]` below)

### Configure Android

For Android configuration, you can follow the same instructions of the Flutter Facebook App Events plugin:
Read through the "[Getting Started with App Events for Android](https://developers.facebook.com/docs/app-events/getting-started-app-events-android)" tutuorial and in particular, follow [step 2](https://developers.facebook.com/docs/app-events/getting-started-app-events-android#2--add-your-facebook-app-id) by adding the following into `/app/res/values/strings.xml` (or into respective `debug` or `release` build flavor)

configure inside android/app/main/res/values/strings.xml the above values (without square brackets):
```xml
<string name="facebook_app_id">[your_app_id]</string>
<!-- Find your client token at: Facebook App Dashboard > Settings > Advanced > Security -->
<string name="facebook_client_token">[your_client_token]</string>
```

then, add that string resource reference to your main `AndroidManifest.xml` file, within <application>...</application>

```xml
<meta-data android:name="com.facebook.sdk.ApplicationId" android:value="@string/facebook_app_id" />
<meta-data android:name="com.facebook.sdk.ClientToken" android:value="@string/facebook_client_token"/>
```

If you want to delay event collection (e.g. to obtain GDPR consent), add the following to `AndroidManifest.xml` inside the `<application>` tag:

```xml
<meta-data android:name="com.facebook.sdk.AutoInitEnabled" android:value="false" />
<meta-data android:name="com.facebook.sdk.AutoLogAppEventsEnabled"
           android:value="false"/>
```

Then after consent is obtained, call the following methods in order:

**For iOS (with ATT permission):**
1. Request ATT permission using iOS `ATTrackingManager`
2. Call `FlutterFacebookAppLinks.setAdvertiserTrackingEnabled(true/false)` based on user consent
3. Call `FlutterFacebookAppLinks.consentProvided()` or `consentRevoked()`

**For Android:**
1. Call `FlutterFacebookAppLinks.setAdvertiserTrackingEnabled(true/false)` based on user consent
2. Call `FlutterFacebookAppLinks.consentProvided()` or `consentRevoked()`

## Platform-Specific Behavior

The `setAdvertiserTrackingEnabled()` method has platform-specific implementations with different semantics:

### iOS
- **API**: `Settings.shared.isAdvertiserTrackingEnabled`
- **Behavior**: Controls whether the SDK reports advertiser tracking as enabled to Facebook
- **Purpose**: Required for proper Facebook attribution after ATT permission
- **Timing**: Set after obtaining ATT permission from iOS, before `consentProvided()`

### Android
- **API**: `FacebookSdk.setAdvertiserIDCollectionEnabled`
- **Behavior**: Controls whether the SDK collects the advertising ID
- **Purpose**: Enables/disables advertising ID collection based on user consent
- **Timing**: Set before `consentProvided()` to respect user privacy settings

### ATT Compliance Note
Both iOS and Android implementations should be set based on the user's App Tracking Transparency (ATT) consent status on iOS, or equivalent privacy settings on Android. This ensures proper GDPR compliance and Facebook attribution functionality.

### Configure iOS

For iOS configuration, you can follow the same instructions of the Flutter Facebook App Events plugin:
Read through the "[Getting Started with App Events for iOS](https://developers.facebook.com/docs/app-events/getting-started-app-events-ios)" tutuorial and in particular, follow [step 4](https://developers.facebook.com/docs/app-events/getting-started-app-events-ios#plist-config) by opening `info.plist` "As Source Code" and add the following

- If your code does not have `CFBundleURLTypes`, add the following just before the final `</dict>` element:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
  <key>CFBundleURLSchemes</key>
  <array>
    <string>fb[APP_ID]</string>
  </array>
  </dict>
</array>
<key>FacebookAppID</key>
<string>[APP_ID]</string>
<key>FacebookDisplayName</key>
<string>[APP_NAME]</string>
```

- If your code already contains `CFBundleURLTypes`, insert the following:

```xml
<array>
 <dict>
 <key>CFBundleURLSchemes</key>
 <array>
   <string>fb[APP_ID]</string>
 </array>
 </dict>
</array>
<key>FacebookAppID</key>
<string>[APP_ID]</string>
<key>FacebookDisplayName</key>
<string>[APP_NAME]</string>
```

- After obtaining ATT permission, follow the same pattern as Android above: call `FlutterFacebookAppLinks.setAdvertiserTrackingEnabled(true/false)` based on user consent, then call `FlutterFacebookAppLinks.consentProvided()` or `consentRevoked()`.

## How to use
```dart
import 'dart:io' show Platform;
...
...
/// FB Deferred Deeplinks
void initFBDeferredDeeplinks() async {

  String deepLinkUrl;
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {

    deepLinkUrl = await FlutterFacebookAppLinks.initFBLinks();
    if(Platform.isIOS)
      deepLinkUrl = await FlutterFacebookAppLinks.getDeepLink();

    /// do what you need with the deeplink...
    /// ...
  }catch(e){
    /// in case of error...
  }
}
```

## About Facebook App Links

Please refer to the official SDK documentation for [Android](https://developers.facebook.com/docs/app-ads/deep-linking/) and [iOS](https://developers.facebook.com/docs/app-ads/deep-linking/).

## IMPORTANT NOTES

### User privacy [DO NOT IGNORE]

How documented on Facebook [docs](https://developers.facebook.com/docs/app-ads/deep-linking/), starting from v5.0.0 of the SDK, they introduce a flag for disabling automatic SDK initialization to be GDPR compliant.
It means that you should collect user consent before you use call the method `initFBLinks()` of this plugin and save the user choice. Moreover, you should give the user a chance to revoke their consent in the future.
Please keep in mind that this plugin uses `FacebookSDK.setAutoInitEnabled(true)` in Android and `Settings.isAutoInitEnabled = true` in iOS by default, so the consent must be granted in your Dart code before you call `FlutterFacebookAppLinks.initFBLinks()`.

### Testing deferred deep links

To correctly test deferred deeplinks, DO NOT use the preview of your FB ADS campaign.
Instead, use this tool [APP ADS HELPER](https://developers.facebook.com/tools/app-ads-helper)

At the end of the page you will find a "Test deep link" button,
click on it and type your custom url scheme (deeplink), for example: myawesomeapp://screen/login

Select the second checkbox (or both). Remember that to make it works, you'll need the Facebook app installed on your device (Android or iPhone) and you must be logged in with the same account you're using in the Facebook Developers console.

Your app doesn't need to be published on the store, simply uninstall it and re-install using Android Studio/VSCode or XCode after you've sent the deferred deep link.

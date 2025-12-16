# Flutter Facebook App Links

Flutter plugin for [Facebook App Links SDK](https://developers.facebook.com/docs/app-ads/deep-linking/). This plugin must be used to catch deferred deeplinks sent from Facebook after your app has been installed from a FB ADS.

## Getting Started

First of all, if you don't have one already, you must first create an app at Facebook developers: https://developers.facebook.com/

## System Prerequisites

### Java Development Kit (JDK)
- **Android Builds**: Java 11 is required for Android compilation
- **Environment Variable**: `JAVA_HOME` should point to JDK 11 installation  
- **Android Gradle Plugin**: AGP 8.x requires JDK 11 (configured in `android/build.gradle`)
- **Verification**: Run `java -version` to confirm JDK 11.x is active

### iOS Development
- **Xcode**: Version 12.0+ for Swift 5.0 compatibility
- **iOS Deployment Target**: iOS 11.0 minimum (optimized for iOS 12.0+)

### Flutter
- **Flutter SDK**: 3.2.2+ (Flutter 3.x required for Facebook SDK 18)
- **Dart SDK**: 3.2.2+ (nullable safety and modern language features)

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

#### 📱 Additional Dependencies Required

##### For iOS ATT Compliance
Your app needs the `app_tracking_transparency` package to handle ATT permission requests:

```yaml
dependencies:
  flutter_facebook_app_links: ^3.2.0
  app_tracking_transparency: ^2.0.4  # Required for iOS ATT compliance

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

## Facebook Analytics Event Logging

This plugin includes comprehensive Facebook Analytics event logging capabilities, allowing you to track user behavior, conversions, and app performance metrics directly in your Flutter app.

### ⚠️ Privacy Compliance Required

**Important**: Event logging requires explicit user consent for privacy compliance (GDPR, CCPA, ATT). Always obtain user consent before logging events.

```dart
import 'dart:io' show Platform;
import 'package:flutter_facebook_app_links/flutter_facebook_app_links.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

// Initialize Facebook SDK with proper consent
Future<void> initializeFacebookSDK() async {
  if (Platform.isIOS) {
    // Request ATT permission first
    var status = await AppTrackingTransparency.requestTrackingAuthorization();
    var trackingEnabled = status == TrackingStatus.authorized;

    // Set advertiser tracking based on consent
    await FlutterFacebookAppLinks.setAdvertiserTrackingEnabled(trackingEnabled);

    // Provide consent to enable event logging
    await FlutterFacebookAppLinks.consentProvided();
  } else {
    // Android: Enable tracking and provide consent
    await FlutterFacebookAppLinks.setAdvertiserTrackingEnabled(true);
    await FlutterFacebookAppLinks.consentProvided();
  }

  // Now event logging is allowed
}
```

### Logging Custom Events

Track any user action or app event:

```dart
// Simple event
await FlutterFacebookAppLinks.logEvent('trial_started');

// Event with parameters
await FlutterFacebookAppLinks.logEvent('feature_used', {
  'feature_name': 'premium_filter',
  'user_type': 'pro',
  'session_duration': 300
});
```

### Logging Purchase Events

Track revenue and purchase conversions:

```dart
// Log purchases with currency and amount
await FlutterFacebookAppLinks.logPurchaseEvent(
  49.99,
  'USD',
  {
    'fb_content_id': 'product_12345',
    'fb_content_type': 'product',
    'fb_num_items': 2,
    'fb_content_category': 'electronics'
  }
);
```

### Logging Registration Events

Track user acquisition:

```dart
// Log user registrations
await FlutterFacebookAppLinks.logCompleteRegistration('email');
await FlutterFacebookAppLinks.logCompleteRegistration('facebook');
```

### Using Facebook Standard Events

Use predefined constants to avoid typos and ensure proper event naming:

```dart
// Standard commerce events
await FlutterFacebookAppLinks.logEvent(FacebookEvents.purchase, {
  FacebookParameters.contentId: 'product_123',
  FacebookParameters.contentType: 'product',
  FacebookParameters.currency: 'USD',
  '_valueToSum': 29.99,  // Standard Facebook parameter
});

await FlutterFacebookAppLinks.logEvent(FacebookEvents.addToCart, {
  FacebookParameters.contentId: 'product_456',
  FacebookParameters.contentType: 'product',
  FacebookParameters.numItems: 1
});

// Standard engagement events
await FlutterFacebookAppLinks.logEvent(FacebookEvents.completeRegistration, {
  FacebookParameters.registrationMethod: 'email'
});

await FlutterFacebookAppLinks.logEvent(FacebookEvents.viewContent, {
  FacebookParameters.contentId: 'article_789',
  FacebookParameters.contentType: 'article'
});
```

### Available Facebook Standard Events

The `FacebookEvents` class provides constants for all major Facebook events:

**Commerce Events:**
- `FacebookEvents.purchase` - Track revenue
- `FacebookEvents.addToCart` - Add to cart actions
- `FacebookEvents.addToWishlist` - Wishlist additions
- `FacebookEvents.initiateCheckout` - Checkout starts

**Engagement Events:**
- `FacebookEvents.completeRegistration` - User signups
- `FacebookEvents.viewContent` - Content views
- `FacebookEvents.search` - Search actions
- `FacebookEvents.contact` - Contact form submissions

**Achievement Events:**
- `FacebookEvents.completeTutorial` - Tutorial completion
- `FacebookEvents.achieveLevel` - Level progression

**Custom Events:**
- `FacebookEvents.trialStarted` - Trial initiations
- `FacebookEvents.featureUsed` - Feature usage
- `FacebookEvents.screenViewed` - Screen tracking

### Using Facebook Parameter Constants

The `FacebookParameters` class provides constants for standard Facebook parameter names to prevent typos:

**Content Parameters:**
- `FacebookParameters.contentId` - Content identifier (`fb_content_id`)
- `FacebookParameters.contentType` - Content type/category (`fb_content_type`)
- `FacebookParameters.contentCategory` - Content category (`fb_content_category`)

**Commerce Parameters:**
- `FacebookParameters.numItems` - Number of items (`fb_num_items`)
- `FacebookParameters.currency` - Currency code (`fb_currency`)
- `FacebookParameters.value` - Monetary value (`fb_value`)

**User Parameters:**
- `FacebookParameters.registrationMethod` - Registration method (`fb_registration_method`)
- `FacebookParameters.searchString` - Search query (`fb_search_string`)
- `FacebookParameters.description` - Description (`fb_description`)

### Event Validation

The plugin includes comprehensive validation:

- **Event Names**: 1-40 characters, alphanumeric + underscores only
- **Currencies**: Must be valid 3-letter ISO codes (USD, EUR, GBP, etc.)
- **Amounts**: Must be >= 0 for purchases
- **Consent**: Events require prior consent via `consentProvided()`

Invalid inputs throw `ArgumentError` or `StateError` with clear messages.

### Facebook Analytics Reference

For complete event specifications and best practices:
- [Facebook Analytics Events Reference](https://developers.facebook.com/docs/facebook-pixel/reference)
- [App Events Best Practices](https://developers.facebook.com/docs/app-events/best-practices/)
- [Facebook Analytics Help Center](https://developers.facebook.com/docs/analytics/)

## Facebook App Links Usage

### ⚡ Platform-Specific Performance Notes

#### iOS initFBLinks() Hybrid Caching

**Important Behavioral Change**: iOS `initFBLinks()` now uses a hybrid caching strategy for optimal performance and platform consistency:

- **Fast Path**: Returns cached deep link immediately if available (populated during app launch)
- **Fallback Path**: Performs network fetch if no cached link exists (~2-5 seconds blocking)
- **Platform Consistency**: Now matches Android behavior while avoiding UI freezes

**Performance Characteristics:**
- **During App Launch**: Fast cached response (recommended usage)
- **Before App Launch Completes**: May perform network fetch (potentially blocking)
- **After Cache Population**: Always immediate response

**Migration Notes:**
- **Before**: Method returned empty strings (cached-only limitation)
- **After**: Actually returns deep link results via hybrid approach
- **Error Handling**: Now properly throws exceptions (previously silent failures)

```dart
import 'dart:io' show Platform;

/// FB Deferred Deeplinks - Updated for iOS hybrid caching
void initFBDeferredDeeplinks() async {
  String deepLinkUrl;

  try {
    // iOS: Hybrid caching - fast cached response or network fallback
    // Android: Consistent network fetch behavior
    deepLinkUrl = await FlutterFacebookAppLinks.initFBLinks();

    // Note: iOS no longer requires separate getDeepLink() call
    // The method now actually returns deep link results

    if (deepLinkUrl.isNotEmpty) {
      // Handle successful deep link
      navigateToDeepLink(deepLinkUrl);
    } else {
      // No deep link available (normal case)
      proceedWithNormalFlow();
    }

  } catch (e) {
    // Network errors or SDK issues now properly propagated
    // (Previously: Silent failures with empty strings)
    handleDeepLinkError(e);
  }
}
```

**Best Practices:**
- Call `initFBLinks()` during app initialization for optimal performance
- Handle exceptions appropriately (network issues, SDK errors)
- Test on slow networks to ensure acceptable user experience

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

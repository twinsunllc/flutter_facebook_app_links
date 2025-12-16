## 3.2.0

* **[Migration Guide]**: Major merge of upstream Mapk26/flutter_facebook_app_links master branch
  * **From**: Your fork's 1.2.0+1 customizations (ATT/privacy features)  
  * **To**: Upstream's Facebook SDK 18.0.0 (StoreKit2 IAP support) + Flutter 3.x modernizations
  * **What's Preserved**: All privacy/compliance methods from your fork (v1.2.0+1)
    - `setAdvertiserTrackingEnabled()` - ATT compliance for iOS privacy
    - `consentProvided()` / `consentRevoked()` - GDPR compliance
    - Enhanced example app with ATT flow demonstrations
  * **What's Added**: Facebook SDK 18.0.0 features
    - StoreKit2 purchase event logging support (fixes attribution drop-off)
    - Modern Flutter 3.x plugin architecture
    - `activateSDK()` method for explicit SDK initialization
  * **API Compatibility**: 100% backward compatible - existing Flutter code continues working
  * **Breaking Changes**: None - all APIs preserved and enhanced

* Merged upstream Mapk26 master branch - Facebook SDK upgraded to 18.0.0
* Improved support for in-app purchase events for Original StoreKit APIs and StoreKit 2 APIs
* Added `setAdvertiserTrackingEnabled()` method to fix Facebook iOS attribution issues after Flutter 3.27→3.32.5 upgrade
* **iOS**: Controls `Settings.shared.isAdvertiserTrackingEnabled` - determines SDK tracking reporting to Facebook (required for attribution)  
* **Android**: Controls `FacebookSdk.setAdvertiserIDCollectionEnabled` - enables/disables advertising ID collection
* Added platform-specific semantic explanations for proper ATT compliance and privacy handling
* Updated README with proper method call order and platform-specific semantics
* Enhanced example app to demonstrate ATT permission flow and tracking consent patterns
* Added unit tests for new `setAdvertiserTrackingEnabled()` method with error handling
* Android: Updated to Facebook SDK 18.1.3, MinSDK 21, CompileSDK 35
* Modernized plugin configuration with explicit platform declarations
* Added Facebook event logging functionality for analytics and conversion tracking
* New `logEvent()` method to log custom events with parameters
* New `logPurchaseEvent()` convenience method for tracking purchases with amount and currency
* New `logCompleteRegistration()` convenience method for tracking user registrations
* New `FacebookEvents` class with constants for standard Facebook event names
* New `FacebookParameters` class with constants for standard Facebook parameter names
* Added input validation for `logEvent()` (Facebook event name format requirements)
* Added input validation for `logPurchaseEvent()` (currency format and positive amounts)
* Added defensive null context check in Android implementation
* **Added event batching controls**: New `flushEvents()` method provides control over Facebook SDK event batching for performance tuning and debugging
* **Added native-side validation**: Defense in depth validation in iOS and Android prevents invalid data from reaching Facebook SDK
* **Fixed iOS deep link fetching**: Reverted to non-blocking cached-only approach to prevent UI freezes during app launch
* **Fixed critical iOS race condition**: Implemented thread-safe DispatchQueue synchronization for cachedDeepLinkUrl to prevent crashes and data corruption
* **Optimized iOS initialization**: Removed redundant SDK initialization call for better performance
* **Cleaned up Android initialization**: Removed unnecessary SDK initialization check for better code clarity
* **Enhanced iOS selector dispatch logging**: Added detection logging for Objective-C selector fallback to monitor attribution reliability
* **Enhanced error messages**: Improved event logging error messages to include event name and parameter count for better debugging
* **Added comprehensive debug logging**: SDK initialization, consent state changes, and event logging details for troubleshooting
* **Improved type safety**: Replaced hardcoded Facebook parameter strings with constants to prevent typos
* **Standardized error handling**: All methods now consistently rethrow exceptions instead of silently catching some and rethrowing others
* **Privacy Compliance Enforcement**: Event logging now requires explicit user consent via `consentProvided()`
* **Consistent Error Handling**: All methods now rethrow exceptions for predictable API behavior
* Support for standard Facebook event names and custom events
* Full parameter support for event metadata (content IDs, values, currencies, etc.)
* **iOS**: Event logging using `AppEvents.shared.logEvent()` from FBSDKCoreKit
* **Android**: Event logging using `AppEventsLogger` from Facebook SDK
* Events require prior SDK initialization via `consentProvided()` for privacy compliance

## 3.1.0
* Android: MinSDK 21, CompileSDK 35
* Android Facebook SDK 18.1.3
* Update example folder

## 3.0.8
* FBSDKCoreKit 17.4- -> 18.0

## 3.0.3
* FBSDKCoreKit 16.0- -> 17.4
* Added methos activateSDK()

## 3.0.2
* initFBLinks() now returns, for Android, an empty String when the deferred link is not available. 
Before this update, the method could return a null value in case of errors.
For iOS use method getDeepLink().

## 3.0.1+8
* FBSDKCoreKit 15.1- -> 16.3
* Android Facebook SDK -> 16.3

## 3.0.1+7
* FBSDKCoreKit 15.1- -> 16.0 

## 3.0.1+6
* FBSDKCoreKit 14.1.0- -> 15.1 

## 3.0.0+5
* README updated

## 3.0.0+4
* FBSDKCoreKit 14.1.0
* Code refactoring
* BREAKING CHANGE: in Android the method initFBLinks() will return a String with the url of the deferred deep link (empty otherwise). 
For iOS it is necessary to call getDeepLink() after initFBLinks().

## 2.0.0+2

* Null safety

## 1.2.0+1

* Added `setAdvertiserTrackingEnabled()` method to fix Facebook iOS attribution issues after Flutter 3.27→3.32.5 upgrade.
* **iOS**: Controls `Settings.shared.isAdvertiserTrackingEnabled` - determines SDK tracking reporting to Facebook (required for attribution)
* **Android**: Controls `FacebookSdk.setAdvertiserIDCollectionEnabled` - enables/disables advertising ID collection
* Added platform-specific semantic explanations for proper ATT compliance and privacy handling
* Updated README with proper method call order and platform-specific semantics
* Enhanced example app to demonstrate ATT permission flow and tracking consent patterns
* Added unit tests for new `setAdvertiserTrackingEnabled()` method with error handling

## 1.1.1+4

* Updated FBSDK v7 to v9

## 1.1.1+3

* Updated FBSDK v5 to v7
* Added MIT License

## 1.1.0+1

* Fixed an error caused from iterating on a null data.

## 1.1.0

* BREAKING CHANGE: it's not necessary anymore to split the code for Android and iOS. In either cases it will return `null` when any deferred deep link is available, or a map containing `deeplink` and `promotionalCode`. The `promotionalCode` can be `null`.
* README: adding important notes on how to manage user privacy using this plugin.

## 1.0.2+1

* Removed Log from Java code.

## 1.0.2

* Fixed a bug on Android where the Future does not complete when no deferred deep link is retrieved. Not it returns `null`.

## 1.0.1+1

* Removed the deprecated `author:` field from pubspec.yaml

## 1.0.1

* Added example code.

## 1.0.0

* Initial release.

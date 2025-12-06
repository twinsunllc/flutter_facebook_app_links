## 1.2.0+1

* Added `setAdvertiserTrackingEnabled()` method to fix Facebook iOS attribution issues after Flutter 3.27→3.32.5 upgrade.
* **iOS**: Controls `Settings.shared.isAdvertiserTrackingEnabled` - determines SDK tracking reporting to Facebook (required for attribution)
* **Android**: Controls `FacebookSdk.setAdvertiserIDCollectionEnabled` - enables/disables advertising ID collection
* Added platform-specific semantic explanations for proper ATT compliance and privacy handling
* Updated README with proper method call order and platform-specific semantics
* Enhanced example app to demonstrate ATT permission flow and tracking consent patterns
* Added unit tests for new `setAdvertiserTrackingEnabled()` method with error handling

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

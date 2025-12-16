import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

class FlutterFacebookAppLinks {
  static const MethodChannel _channel = const MethodChannel("plugins.remedia.it/flutter_facebook_app_links");

  /// Tracks whether user consent for Facebook tracking has been provided.
  /// This is used to enforce privacy compliance before allowing event logging.
  static bool _hasConsent = false;

  /// Tracks whether we've synchronized consent state with native SDK after hot restart
  static bool _consentStateSynced = false;

  /// Synchronizes the Dart consent state with the native SDK state.
  /// This handles the case where Flutter hot restart resets Dart state
  /// but the native Facebook SDK maintains its consent state.
  static Future<void> _syncConsentState() async {
    if (_consentStateSynced) return; // Already synced

    try {
      final nativeConsent = await _channel.invokeMethod('getConsentState');
      _hasConsent = nativeConsent == true;
      _consentStateSynced = true;
      debugPrint('Synced consent state with native SDK: $_hasConsent');
    } catch (e) {
      // If sync fails, keep current state (default to false for safety)
      debugPrint('Failed to sync consent state: $e');
    }
  }

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
      rethrow;
    }
  }

  static Future<String> getDeepLink() async {
    try {
      var data = await _channel.invokeMethod('getDeepLinkUrl');
      debugPrint('Deferred FB Link: $data');
      return data ?? '';
    } catch (e) {
      debugPrint("Error retrieving deferred deep link: $e");
      rethrow;
    }
  }

  /// Provides user consent for Facebook tracking and analytics.
  ///
  /// This method must be called after obtaining explicit user consent for tracking
  /// to comply with privacy regulations (GDPR, CCPA, ATT, etc.).
  ///
  /// **Required before logging events**: All event logging methods ([logEvent],
  /// [logPurchaseEvent], [logCompleteRegistration]) require consent to be provided first.
  ///
  /// **Platform effects**:
  /// - Enables Facebook SDK auto event logging
  /// - Allows manual event logging via this plugin
  /// - Required for proper attribution and analytics
  ///
  /// **Usage**:
  /// ```dart
  /// // After obtaining user consent (ATT, GDPR dialog, etc.)
  /// await FlutterFacebookAppLinks.consentProvided();
  ///
  /// // Now event logging is allowed
  /// await FlutterFacebookAppLinks.logEvent('purchase');
  /// ```
  ///
  /// Throws [PlatformException] if the platform-specific call fails
  static Future<dynamic> consentProvided() async {
    _hasConsent = true;
    return _channel.invokeMethod('consentProvided');
  }

  /// Revokes user consent for Facebook tracking and analytics.
  ///
  /// This method should be called when users withdraw consent or opt-out of tracking.
  /// After revocation, event logging methods will throw [StateError] until consent
  /// is provided again.
  ///
  /// **Platform effects**:
  /// - Disables Facebook SDK auto event logging
  /// - Prevents manual event logging via this plugin
  /// - Stops attribution and analytics collection
  ///
  /// **Usage**:
  /// ```dart
  /// // When user opts out or withdraws consent
  /// await FlutterFacebookAppLinks.consentRevoked();
  ///
  /// // Event logging will now fail
  /// await FlutterFacebookAppLinks.logEvent('purchase'); // Throws StateError
  /// ```
  ///
  /// Throws [PlatformException] if the platform-specific call fails
  static Future<dynamic> consentRevoked() async {
    _hasConsent = false;
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

  /// Activates the Facebook SDK for app events and analytics.
  ///
  /// This method initializes the Facebook SDK and prepares it for event logging.
  /// It should be called early in the app lifecycle, typically in main() or
  /// after obtaining necessary permissions.
  ///
  /// Note: This method is automatically called internally by other methods
  /// when needed, but can be called explicitly for early initialization.
  ///
  /// Throws [PlatformException] if the platform-specific call fails
  static Future<void> activateSDK() async {
    try {
      debugPrint('Activating SDK');
      await _channel.invokeMethod('activateApp');
    } catch (e) {
      debugPrint("Error activating SDK: $e");
      rethrow;
    }
  }

  /// Logs a custom event with Facebook Analytics.
  ///
  /// This method allows you to track custom events and user actions in your app.
  /// Events can be used for analytics, optimization, and creating custom audiences.
  ///
  /// **Privacy Compliance Required**: You MUST call [consentProvided] after obtaining
  /// user consent before logging any events. Failure to do so may violate GDPR,
  /// CCPA, and other privacy regulations.
  ///
  /// **Platform Support**: Both iOS and Android
  ///
  /// Common event names include:
  /// - Standard events: 'fb_mobile_complete_registration', 'fb_mobile_add_to_cart',
  ///   'fb_mobile_purchase', 'fb_mobile_initiated_checkout'
  /// - Custom events: Any string describing the action (e.g., 'trial_started', 'level_achieved')
  ///
  /// [eventName] - The name of the event to log. Must be 1-40 characters containing only
  ///               alphanumeric characters and underscores. Use standard Facebook event names
  ///               or create custom event names following Facebook's naming conventions.
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
  /// // After obtaining user consent
  /// await FlutterFacebookAppLinks.consentProvided();
  ///
  /// // Now event logging is allowed
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
  /// Throws [StateError] if user consent has not been provided
  /// Throws [ArgumentError] if event name format is invalid
  /// Throws [PlatformException] if the platform-specific call fails
  static Future<void> logEvent(String eventName, [Map<String, dynamic>? parameters]) async {
    // Sync consent state with native SDK to handle hot restart scenarios
    await _syncConsentState();

    // Enforce privacy compliance - require explicit consent
    if (!_hasConsent) {
      throw StateError('Facebook tracking consent must be provided before logging events. '
          'Call consentProvided() after obtaining user consent to comply with '
          'GDPR, CCPA, and other privacy regulations.');
    }

    // Validate event name according to Facebook requirements
    if (eventName.isEmpty || eventName.length > 40) {
      throw ArgumentError('Event name must be 1-40 characters');
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(eventName)) {
      throw ArgumentError('Event name must contain only alphanumeric characters and underscores');
    }

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
  /// **Privacy Compliance Required**: You MUST call [consentProvided] after obtaining
  /// user consent before logging any events. Failure to do so may violate GDPR,
  /// CCPA, and other privacy regulations.
  ///
  /// [amount] - The purchase amount (must be >= 0, e.g., 29.99)
  /// [currency] - Three-letter ISO 4217 currency code (e.g., 'USD', 'EUR', 'GBP')
  /// [parameters] - Optional additional parameters (e.g., content_id, content_type, num_items)
  ///
  /// Example:
  /// ```dart
  /// // After obtaining user consent
  /// await FlutterFacebookAppLinks.consentProvided();
  ///
  /// // Now purchase logging is allowed
  /// await FlutterFacebookAppLinks.logPurchaseEvent(
  ///   49.99,
  ///   'USD',
  ///   {'fb_content_id': 'sku_12345', 'fb_num_items': 2}
  /// );
  /// ```
  ///
  /// Throws [StateError] if user consent has not been provided
  /// Throws [ArgumentError] if amount is negative or currency format is invalid
  /// Throws [PlatformException] if the platform-specific call fails
  static Future<void> logPurchaseEvent(
    double amount,
    String currency, [
    Map<String, dynamic>? parameters,
  ]) async {
    // Sync consent state with native SDK to handle hot restart scenarios
    await _syncConsentState();

    // Enforce privacy compliance - require explicit consent
    if (!_hasConsent) {
      throw StateError('Facebook tracking consent must be provided before logging events. '
          'Call consentProvided() after obtaining user consent to comply with '
          'GDPR, CCPA, and other privacy regulations.');
    }

    // Validate inputs to ensure data quality
    if (amount < 0) {
      throw ArgumentError('Purchase amount cannot be negative');
    }
    if (currency.length != 3 || !RegExp(r'^[A-Z]+$').hasMatch(currency)) {
      throw ArgumentError('Currency must be a 3-letter ISO 4217 code (e.g., USD, EUR, GBP)');
    }

    try {
      final Map<String, dynamic> params = Map.from(parameters ?? {});
      params[FacebookParameters.currency] = currency;
      params[FacebookParameters.valueToSum] = amount;

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
  /// **Privacy Compliance Required**: You MUST call [consentProvided] after obtaining
  /// user consent before logging any events. Failure to do so may violate GDPR,
  /// CCPA, and other privacy regulations.
  ///
  /// [registrationMethod] - Optional method used for registration (e.g., 'email', 'facebook', 'google')
  ///
  /// Example:
  /// ```dart
  /// // After obtaining user consent
  /// await FlutterFacebookAppLinks.consentProvided();
  ///
  /// // Now registration logging is allowed
  /// await FlutterFacebookAppLinks.logCompleteRegistration('email');
  /// ```
  ///
  /// Throws [StateError] if user consent has not been provided
  /// Throws [PlatformException] if the platform-specific call fails
  static Future<void> logCompleteRegistration([String? registrationMethod]) async {
    // Sync consent state with native SDK to handle hot restart scenarios
    await _syncConsentState();

    // Enforce privacy compliance - require explicit consent
    if (!_hasConsent) {
      throw StateError('Facebook tracking consent must be provided before logging events. '
          'Call consentProvided() after obtaining user consent to comply with '
          'GDPR, CCPA, and other privacy regulations.');
    }

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

  /// Forces immediate sending of all pending batched events to Facebook.
  ///
  /// The Facebook SDK automatically batches events for optimal performance and
  /// network efficiency. This method forces immediate transmission of all
  /// pending events, bypassing the normal batching delay.
  ///
  /// **Use Cases:**
  /// - Critical events that must be sent immediately (e.g., purchases)
  /// - App termination to ensure events are sent before shutdown
  /// - Debugging to verify event transmission
  /// - Session changes (logout/login) to send pending events
  ///
  /// **Performance Note:**
  /// Frequent flushing reduces the benefits of batching. Use only when
  /// immediate delivery is required.
  ///
  /// **Privacy Compliance:**
  /// This method respects consent settings - events are only sent if
  /// consent has been previously provided.
  ///
  /// Example:
  /// ```dart
  /// // Log a critical purchase event
  /// await FlutterFacebookAppLinks.logPurchaseEvent(99.99, 'USD');
  ///
  /// // Force immediate sending (bypasses batching)
  /// await FlutterFacebookAppLinks.flushEvents();
  /// ```
  ///
  /// Throws [PlatformException] if the platform-specific call fails
  static Future<void> flushEvents() async {
    try {
      debugPrint('Flushing Facebook events (forcing immediate send)');
      await _channel.invokeMethod('flushEvents');
    } catch (e) {
      debugPrint("Error flushing Facebook events: $e");
      rethrow;
    }
  }
}

/// Convenience constants for Facebook Analytics event names.
///
/// This class provides constants for standard Facebook event names to prevent
/// typos and improve developer experience with auto-completion.
///
/// **Standard Facebook Events:**
/// Use these predefined events for common user actions that Facebook recognizes
/// for analytics, optimization, and audience creation.
///
/// **Custom Events:**
/// Create your own event names for app-specific actions. Follow Facebook's
/// naming conventions: max 40 characters, alphanumeric + underscore.
///
/// **Usage:**
/// ```dart
/// // Standard event
/// await FlutterFacebookAppLinks.logEvent(FacebookEvents.purchase, {
///   FacebookParameters.contentId: 'product_123',
///   FacebookParameters.currency: 'USD',
/// });
///
/// // Custom event
/// await FlutterFacebookAppLinks.logEvent(FacebookEvents.trialStarted);
/// ```
class FacebookEvents {
  // Standard Facebook commerce events
  static const String purchase = 'fb_mobile_purchase';
  static const String addToCart = 'fb_mobile_add_to_cart';
  static const String addToWishlist = 'fb_mobile_add_to_wishlist';
  static const String initiateCheckout = 'fb_mobile_initiated_checkout';

  // Standard Facebook engagement events
  static const String completeRegistration = 'fb_mobile_complete_registration';
  static const String search = 'fb_mobile_search';
  static const String viewContent = 'fb_mobile_content_view';
  static const String rate = 'fb_mobile_rate';
  static const String contact = 'fb_mobile_contact';
  static const String customizeProduct = 'fb_mobile_customize_product';
  static const String donate = 'fb_mobile_donate';
  static const String findLocation = 'fb_mobile_find_location';
  static const String schedule = 'fb_mobile_schedule';
  static const String startTrial = 'fb_mobile_start_trial';
  static const String submitApplication = 'fb_mobile_submit_application';
  static const String subscribe = 'fb_mobile_subscribe';
  static const String adClick = 'fb_mobile_ad_click';
  static const String adImpression = 'fb_mobile_ad_impression';

  // Achievement events
  static const String achieveLevel = 'fb_mobile_achievement_unlocked';
  static const String unlockAchievement = 'fb_mobile_achievement_unlocked';
  static const String completeTutorial = 'fb_mobile_tutorial_completion';

  // Common custom events (examples - create your own)
  static const String trialStarted = 'trial_started';
  static const String levelAchieved = 'level_achieved';
  static const String tutorialCompleted = 'tutorial_completed';
  static const String featureUsed = 'feature_used';
  static const String screenViewed = 'screen_viewed';
  static const String buttonClicked = 'button_clicked';
  static const String formSubmitted = 'form_submitted';
  static const String videoPlayed = 'video_played';
  static const String fileDownloaded = 'file_downloaded';
}

/// Convenience constants for Facebook Analytics event parameters.
///
/// This class provides constants for standard Facebook event parameter names
/// to prevent typos and improve developer experience with auto-completion.
///
/// **Content Parameters:**
/// Used to describe content being interacted with (products, articles, etc.)
///
/// **Commerce Parameters:**
/// Used for purchase and transaction tracking
///
/// **User Parameters:**
/// Used for user attribution and behavior tracking
///
/// **Usage:**
/// ```dart
/// // Purchase event with parameters
/// await FlutterFacebookAppLinks.logEvent(FacebookEvents.purchase, {
///   FacebookParameters.contentId: 'product_123',
///   FacebookParameters.contentType: 'product',
///   FacebookParameters.numItems: 2,
///   FacebookParameters.currency: 'USD',
///   '_valueToSum': 49.99,  // Standard Facebook parameter
/// });
///
/// // Content view event
/// await FlutterFacebookAppLinks.logEvent(FacebookEvents.viewContent, {
///   FacebookParameters.contentId: 'article_456',
///   FacebookParameters.contentType: 'article',
/// });
/// ```
class FacebookParameters {
  // Content identification
  static const String contentId = 'fb_content_id';
  static const String contentType = 'fb_content_type';
  static const String contentCategory = 'fb_content_category';

  // Commerce and quantity
  static const String numItems = 'fb_num_items';
  static const String currency = 'fb_currency';
  static const String value = 'fb_value';

  // User and attribution
  static const String registrationMethod = 'fb_registration_method';
  static const String searchString = 'fb_search_string';
  static const String description = 'fb_description';

  // Success and status
  static const String success = 'fb_success';

  // Standard Facebook parameters (commonly used)
  static const String valueToSum = '_valueToSum';
  static const String orderId = 'fb_order_id';
  static const String predictedLtv = 'fb_predicted_ltv';

  // App-specific parameters (commonly used)
  static const String level = 'fb_level';
  static const String score = 'fb_score';
  static const String maxRatingValue = 'fb_max_rating_value';
  static const String paymentInfoAvailable = 'fb_payment_info_available';
}

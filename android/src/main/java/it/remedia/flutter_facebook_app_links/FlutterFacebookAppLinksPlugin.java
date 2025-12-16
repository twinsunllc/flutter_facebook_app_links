package it.remedia.flutter_facebook_app_links;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.util.Log;
import androidx.annotation.NonNull;

import com.facebook.applinks.AppLinkData;
import com.facebook.FacebookSdk;
import com.facebook.appevents.AppEventsLogger;

import android.os.Bundle;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** FlutterFacebookAppLinksPlugin */
public class FlutterFacebookAppLinksPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

  private Context mContext;
  private Activity mActivity;
  private String deeplinkUrl = "";
  private MethodChannel methodChannel;

  private static final String CHANNEL = "plugins.remedia.it/flutter_facebook_app_links";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    methodChannel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    methodChannel.setMethodCallHandler(this);
    mContext = binding.getApplicationContext();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    methodChannel.setMethodCallHandler(null);
    methodChannel = null;
    mContext = null;
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding binding) {
    mActivity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    mActivity = null;
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    mActivity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    mActivity = binding.getActivity();
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if(call.method.equals("initFBLinks")){
      initFBLinks(result);
    } else if (call.method.equals("getDeepLinkUrl")) {
      getDeepLinkUrl(result);
    } else if (call.method.equals("consentProvided")) {
      FacebookSdk.setAutoLogAppEventsEnabled(true);
      FacebookSdk.setAutoInitEnabled(true);
      FacebookSdk.fullyInitialize();
      Log.d("FB_APP_LINKS", "Consent provided - event logging enabled");
      result.success("");
    } else if (call.method.equals("consentRevoked")) {
      FacebookSdk.setAutoLogAppEventsEnabled(false);
      FacebookSdk.setAutoInitEnabled(false);
      FacebookSdk.fullyInitialize();
      Log.d("FB_APP_LINKS", "Consent revoked - event logging disabled");
      result.success("");
    } else if (call.method.equals("setAdvertiserTrackingEnabled")) {
      Boolean enabled = call.argument("enabled");
      if (enabled != null) {
        // Ensure SDK is initialized before setting tracking preferences
        FacebookSdk.fullyInitialize();
        FacebookSdk.setAdvertiserIDCollectionEnabled(enabled);
        result.success(null);
      } else {
        result.error("INVALID_ARGUMENTS", "Expected boolean 'enabled' parameter", null);
      }
    } else if(call.method.equals("activateApp")){
      activateSDK();
      result.success(true);
    } else if (call.method.equals("logEvent")) {
      logEvent(call, result);
    } else if (call.method.equals("getConsentState")) {
      // Query native SDK consent state for hot restart synchronization
      boolean hasConsent = FacebookSdk.getAutoLogAppEventsEnabled();
      result.success(hasConsent);
    } else {
      result.notImplemented();
    }
  }

  private void activateSDK(){
    FacebookSdk.setAutoLogAppEventsEnabled(false);
    FacebookSdk.setAutoInitEnabled(true);
    FacebookSdk.fullyInitialize();
  }

  private void getDeepLinkUrl(Result result) {
    //Log.d("FB_APP_LINKS", "Facebook App Links getDeepLinkUrl called");

    final Result resultDelegate = result;
    // Get a handler that can be used to post to the main thread
    final Handler mainHandler = new Handler(mContext.getMainLooper());

    // Get user consent
    FacebookSdk.fullyInitialize();
    AppLinkData.fetchDeferredAppLinkData(mContext,
      new AppLinkData.CompletionHandler() {
        @Override
        public void onDeferredAppLinkDataFetched(AppLinkData appLinkData) {
          // Process app link data
          if(appLinkData!=null && appLinkData.getTargetUri()!=null){
            //Log.d("FB_APP_LINKS", "Deep Link URL Received: " + appLinkData.getTargetUri().toString());
            Runnable myRunnable = new Runnable() {
              @Override
              public void run() {
                if(resultDelegate!=null)
                  resultDelegate.success(appLinkData.getTargetUri().toString());
              }
            };
            mainHandler.post(myRunnable);
          }else{
            Runnable myRunnable = new Runnable() {
              @Override
              public void run() {
                if(resultDelegate!=null)
                  resultDelegate.success("");
              }
            };
            mainHandler.post(myRunnable);
          }
        }
      }
    );
  }

  private void initFBLinks(Result result) {
    //Log.d("FB_APP_LINKS", "Facebook App Links initialized");

    final Result resultDelegate = result;
    // Get a handler that can be used to post to the main thread
    final Handler mainHandler = new Handler(mContext.getMainLooper());

    // Get user consent
    activateSDK();
    AppLinkData.fetchDeferredAppLinkData(mContext,
      new AppLinkData.CompletionHandler() {
        @Override
        public void onDeferredAppLinkDataFetched(AppLinkData appLinkData) {
          // Process app link data
          if(appLinkData!=null && appLinkData.getTargetUri()!=null){
            //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: " + appLinkData.getTargetUri().toString());
            deeplinkUrl = appLinkData.getTargetUri().toString();
          }

          Runnable myRunnable = new Runnable() {
            @Override
            public void run() {
              if(resultDelegate!=null)
                resultDelegate.success(deeplinkUrl);
            }
          };
          mainHandler.post(myRunnable);
        }
      }
    );
  }

  private void logEvent(MethodCall call, Result result) {
    // Defensive check for null context
    if (mContext == null) {
      result.error("CONTEXT_NULL", "Plugin context is not initialized", null);
      return;
    }

    try {
      // Ensure SDK is initialized before logging events
      FacebookSdk.fullyInitialize();

      String eventName = call.argument("eventName");
      Map<String, Object> parameters = call.argument("parameters");

      if (eventName == null || eventName.isEmpty()) {
        result.error("INVALID_ARGUMENTS", "Event name cannot be null or empty", null);
        return;
      }

      // Defense in depth validation - mirror Dart validation
      if (eventName.length() > 40) {
        result.error("INVALID_ARGUMENTS", "Event name must be 1-40 characters", null);
        return;
      }

      // Validate event name contains only alphanumeric characters and underscores
      if (!eventName.matches("^[a-zA-Z0-9_]+$")) {
        result.error("INVALID_ARGUMENTS", "Event name must contain only alphanumeric characters and underscores", null);
        return;
      }

      // Create AppEventsLogger instance
      AppEventsLogger logger = AppEventsLogger.newLogger(mContext);

      // Convert parameters to Bundle
      Bundle params = new Bundle();
      if (parameters != null && !parameters.isEmpty()) {
        for (Map.Entry<String, Object> entry : parameters.entrySet()) {
          String key = entry.getKey();
          Object value = entry.getValue();

          if (value instanceof String) {
            params.putString(key, (String) value);
          } else if (value instanceof Integer) {
            params.putInt(key, (Integer) value);
          } else if (value instanceof Double) {
            params.putDouble(key, (Double) value);
          } else if (value instanceof Long) {
            params.putLong(key, (Long) value);
          } else if (value instanceof Boolean) {
            params.putBoolean(key, (Boolean) value);
          } else if (value != null) {
            // Fallback: convert to string
            params.putString(key, value.toString());
          }
        }
      }

      // Log the event
      logger.logEvent(eventName, params);
      // Safe parameter count logging to prevent null pointer exceptions
      int paramCount = parameters != null ? parameters.size() : 0;
      Log.d("FB_APP_LINKS", "Logged event '" + eventName + "' with " + paramCount + " parameters");
      result.success(null);

    } catch (Exception e) {
      // Include event name and parameter count in error message for better debugging
      // Safe parameter count to prevent null pointer exceptions in error logging
      int paramCount = parameters != null ? parameters.size() : 0;
      result.error("EVENT_LOGGING_ERROR",
          "Failed to log event '" + eventName + "' with " + paramCount + " parameters: " + e.getMessage(),
          null);
    }
  }
}

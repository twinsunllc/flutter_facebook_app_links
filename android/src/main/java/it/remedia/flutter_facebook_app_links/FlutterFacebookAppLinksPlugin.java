package it.remedia.flutter_facebook_app_links;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
//import android.util.Log;

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
  private MethodChannel channel;

  private static final String CHANNEL = "plugins.remedia.it/flutter_facebook_app_links";

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
    channel.setMethodCallHandler(this);
    mContext = binding.getApplicationContext();
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    channel = null;
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
      result.success("");
    } else if (call.method.equals("consentRevoked")) {
      FacebookSdk.setAutoLogAppEventsEnabled(false);
      FacebookSdk.setAutoInitEnabled(false);
      FacebookSdk.fullyInitialize();
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
    } else if (call.method.equals("logEvent")) {
      logEvent(call, result);
    } else {
      result.notImplemented();
    }
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
            //Log.d("FB_APP_LINKS", "Deep Link URL Received: null link");

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

    final Map<String, String> data = new HashMap<>();
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
          if(appLinkData!=null) {

            if(appLinkData.getTargetUri()!=null){
              //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: " + appLinkData.getTargetUri().toString());
              data.put("deeplink", appLinkData.getTargetUri().toString());
            }

            //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: " + appLinkData.getPromotionCode());
            if(appLinkData.getPromotionCode()!=null)
              data.put("promotionalCode", appLinkData.getPromotionCode());
            else
              data.put("promotionalCode", "");

            Runnable myRunnable = new Runnable() {
              @Override
              public void run() {
                if(resultDelegate!=null)
                  resultDelegate.success(data);
              }
            };

            mainHandler.post(myRunnable);

          }else{
            //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: null link");

            Runnable myRunnable = new Runnable() {
              @Override
              public void run() {
                if(resultDelegate!=null)
                  resultDelegate.success(null);
              }
            };

            mainHandler.post(myRunnable);

          }

        }
      }
    );
  }

  private void logEvent(MethodCall call, Result result) {
    try {
      // Ensure SDK is initialized before logging events
      if (!FacebookSdk.isInitialized()) {
        FacebookSdk.fullyInitialize();
      }

      String eventName = call.argument("eventName");
      Map<String, Object> parameters = call.argument("parameters");

      if (eventName == null || eventName.isEmpty()) {
        result.error("INVALID_ARGUMENTS", "Event name cannot be null or empty", null);
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
      result.success(null);

    } catch (Exception e) {
      result.error("EVENT_LOGGING_ERROR", "Failed to log event: " + e.getMessage(), null);
    }
  }

}

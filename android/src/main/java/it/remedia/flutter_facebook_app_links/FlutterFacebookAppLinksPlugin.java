package it.remedia.flutter_facebook_app_links;

import android.app.Activity;
import android.content.Context;
import android.os.Handler;
import android.util.Log;
import androidx.annotation.NonNull;

import com.facebook.applinks.AppLinkData;
import com.facebook.FacebookSdk;

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

  private static String TAG = "FlutterFacebookAppLinksPlugin";
  private static final String CHANNEL = "plugins.remedia.it/flutter_facebook_app_links";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    Log.d(TAG, "onAttachedToEngine...");
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
      result.success(deeplinkUrl);
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
    } else if(call.method.equals("activateApp")){
      activateSDK();
      result.success(true);
    } else {
      result.notImplemented();
    }
  }

  private void activateSDK(){
    FacebookSdk.setAutoLogAppEventsEnabled(false);
    FacebookSdk.setAutoInitEnabled(true);
    FacebookSdk.fullyInitialize();
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
          if(appLinkData!=null) {

            if(appLinkData.getTargetUri()!=null){
              //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: " + appLinkData.getTargetUri().toString());
              deeplinkUrl = appLinkData.getTargetUri().toString();
            }

            //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: " + appLinkData.getPromotionCode());

            Runnable myRunnable = new Runnable() {
              @Override
              public void run() {
                if(resultDelegate!=null)
                  resultDelegate.success(deeplinkUrl);
              }
            };

            mainHandler.post(myRunnable);

          }else{
            //Log.d("FB_APP_LINKS", "Deferred Deeplink Received: null link");

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
      }
    );
  }

}

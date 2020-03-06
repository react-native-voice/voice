package com.wenkesj.voice;

import android.Manifest;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Bundle;
import android.os.Handler;
import android.speech.RecognitionListener;
import android.speech.RecognitionService;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import androidx.annotation.NonNull;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.modules.core.PermissionAwareActivity;
import com.facebook.react.modules.core.PermissionListener;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import javax.annotation.Nullable;

public class VoiceModule extends ReactContextBaseJavaModule implements RecognitionListener {

  final ReactApplicationContext reactContext;
  private SpeechRecognizer speech = null;
  private boolean isRecognizing = false;
  private String locale = null;

  public VoiceModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  private String getLocale(String locale) {
    if (locale != null && !locale.equals("")) {
      return locale;
    }

    return Locale.getDefault().toString();
  }

  private void startListening(ReadableMap opts) {
    if (speech != null) {
      speech.destroy();
      speech = null;
    }
    
    if(opts.hasKey("RECOGNIZER_ENGINE")) {
      switch (opts.getString("RECOGNIZER_ENGINE")) {
        case "GOOGLE": {
          speech = SpeechRecognizer.createSpeechRecognizer(this.reactContext, ComponentName.unflattenFromString("com.google.android.googlequicksearchbox/com.google.android.voicesearch.serviceapi.GoogleRecognitionService"));
          break;
        }
        default:
          speech = SpeechRecognizer.createSpeechRecognizer(this.reactContext);
      }
    } else {
      speech = SpeechRecognizer.createSpeechRecognizer(this.reactContext);
    }

    speech.setRecognitionListener(this);

    final Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);

    // Load the intent with options from JS
    ReadableMapKeySetIterator iterator = opts.keySetIterator();
    while (iterator.hasNextKey()) {
      String key = iterator.nextKey();
      switch (key) {
        case "EXTRA_LANGUAGE_MODEL":
          switch (opts.getString(key)) {
            case "LANGUAGE_MODEL_FREE_FORM":
              intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
              break;
            case "LANGUAGE_MODEL_WEB_SEARCH":
              intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_WEB_SEARCH);
              break;
            default:
              intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
              break;
          }
          break;
        case "EXTRA_MAX_RESULTS": {
          Double extras = opts.getDouble(key);
          intent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, extras.intValue());
          break;
        }
        case "EXTRA_PARTIAL_RESULTS": {
          intent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, opts.getBoolean(key));
          break;
        }
        case "EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS": {
          Double extras = opts.getDouble(key);
          intent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, extras.intValue());
          break;
        }
        case "EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS": {
          Double extras = opts.getDouble(key);
          intent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, extras.intValue());
          break;
        }
        case "EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS": {
          Double extras = opts.getDouble(key);
          intent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, extras.intValue());
          break;
        }
      }
    }

    intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, getLocale(this.locale));
    speech.startListening(intent);
  }

  private void startSpeechWithPermissions(final String locale, final ReadableMap opts, final Callback callback) {
    this.locale = locale;

    Handler mainHandler = new Handler(this.reactContext.getMainLooper());
    mainHandler.post(new Runnable() {
      @Override
      public void run() {
        try {
          startListening(opts);
          isRecognizing = true;
          callback.invoke(false);
        } catch (Exception e) {
          callback.invoke(e.getMessage());
        }
      }
    });
  }

  @Override
  public String getName() {
    return "RCTVoice";
  }

  @ReactMethod
  public void startSpeech(final String locale, final ReadableMap opts, final Callback callback) {
    if (!isPermissionGranted() && opts.getBoolean("REQUEST_PERMISSIONS_AUTO")) {
      String[] PERMISSIONS = {Manifest.permission.RECORD_AUDIO};
      if (this.getCurrentActivity() != null) {
        ((PermissionAwareActivity) this.getCurrentActivity()).requestPermissions(PERMISSIONS, 1, new PermissionListener() {
          public boolean onRequestPermissionsResult(final int requestCode,
                                                    @NonNull final String[] permissions,
                                                    @NonNull final int[] grantResults) {
            boolean permissionsGranted = true;
            for (int i = 0; i < permissions.length; i++) {
              final boolean granted = grantResults[i] == PackageManager.PERMISSION_GRANTED;
              permissionsGranted = permissionsGranted && granted;
            }
            startSpeechWithPermissions(locale, opts, callback);
            return permissionsGranted;
          }
        });
      }
      return;
    }
    startSpeechWithPermissions(locale, opts, callback);
  }

  @ReactMethod
  public void stopSpeech(final Callback callback) {
    Handler mainHandler = new Handler(this.reactContext.getMainLooper());
    mainHandler.post(new Runnable() {
      @Override
      public void run() {
        try {
          if (speech != null) {
            speech.stopListening();
          }
          isRecognizing = false;
          callback.invoke(false);
        } catch(Exception e) {
          callback.invoke(e.getMessage());
        }
      }
    });
  }

  @ReactMethod
  public void cancelSpeech(final Callback callback) {
    Handler mainHandler = new Handler(this.reactContext.getMainLooper());
    mainHandler.post(new Runnable() {
      @Override
      public void run() {
        try {
          if (speech != null) {
            speech.cancel();
          }
          isRecognizing = false;
          callback.invoke(false);
        } catch(Exception e) {
          callback.invoke(e.getMessage());
        }
      }
    });
  }

  @ReactMethod
  public void destroySpeech(final Callback callback) {
    Handler mainHandler = new Handler(this.reactContext.getMainLooper());
    mainHandler.post(new Runnable() {
      @Override
      public void run() {
        try {
          if (speech != null) {
            speech.destroy();
          }
          speech = null;
          isRecognizing = false;
          callback.invoke(false);
        } catch(Exception e) {
          callback.invoke(e.getMessage());
        }
      }
    });
  }

  @ReactMethod
  public void isSpeechAvailable(final Callback callback) {
    final VoiceModule self = this;
    Handler mainHandler = new Handler(this.reactContext.getMainLooper());
    mainHandler.post(new Runnable() {
      @Override
      public void run() {
        try {
          Boolean isSpeechAvailable = SpeechRecognizer.isRecognitionAvailable(self.reactContext);
          callback.invoke(isSpeechAvailable, false);
        } catch(Exception e) {
          callback.invoke(false, e.getMessage());
        }
      }
    });
  }

  @ReactMethod
  public void getSpeechRecognitionServices(Promise promise) {
    final List<ResolveInfo> services = this.reactContext.getPackageManager()
        .queryIntentServices(new Intent(RecognitionService.SERVICE_INTERFACE), 0);
    WritableArray serviceNames = Arguments.createArray();
    for (ResolveInfo service : services) {
      serviceNames.pushString(service.serviceInfo.packageName);
    }

    promise.resolve(serviceNames);
  }

  private boolean isPermissionGranted() {
    String permission = Manifest.permission.RECORD_AUDIO;
    int res = getReactApplicationContext().checkCallingOrSelfPermission(permission);
    return res == PackageManager.PERMISSION_GRANTED;
  }

  @ReactMethod
  public void isRecognizing(Callback callback) {
    callback.invoke(isRecognizing);
  }

  private void sendEvent(String eventName, @Nullable WritableMap params) {
    this.reactContext
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
      .emit(eventName, params);
  }

  @Override
  public void onBeginningOfSpeech() {
    WritableMap event = Arguments.createMap();
    event.putBoolean("error", false);
    sendEvent("onSpeechStart", event);
    Log.d("ASR", "onBeginningOfSpeech()");
  }

  @Override
  public void onBufferReceived(byte[] buffer) {
    WritableMap event = Arguments.createMap();
    event.putBoolean("error", false);
    sendEvent("onSpeechRecognized", event);
    Log.d("ASR", "onBufferReceived()");
  }

  @Override
  public void onEndOfSpeech() {
    WritableMap event = Arguments.createMap();
    event.putBoolean("error", false);
    sendEvent("onSpeechEnd", event);
    Log.d("ASR", "onEndOfSpeech()");
    isRecognizing = false;
  }

  @Override
  public void onError(int errorCode) {
    String errorMessage = String.format("%d/%s", errorCode, getErrorText(errorCode));
    WritableMap error = Arguments.createMap();
    error.putString("message", errorMessage);
    WritableMap event = Arguments.createMap();
    event.putMap("error", error);
    sendEvent("onSpeechError", event);
    Log.d("ASR", "onError() - " + errorMessage);
  }

  @Override
  public void onEvent(int arg0, Bundle arg1) { }

  @Override
  public void onPartialResults(Bundle results) {
    WritableArray arr = Arguments.createArray();

    ArrayList<String> matches = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
    for (String result : matches) {
      arr.pushString(result);
    }

    WritableMap event = Arguments.createMap();
    event.putArray("value", arr);
    sendEvent("onSpeechPartialResults", event);
    Log.d("ASR", "onPartialResults()");
  }

  @Override
  public void onReadyForSpeech(Bundle arg0) {
    WritableMap event = Arguments.createMap();
    event.putBoolean("error", false);
    sendEvent("onSpeechStart", event);
    Log.d("ASR", "onReadyForSpeech()");
  }

  @Override
  public void onResults(Bundle results) {
    WritableArray arr = Arguments.createArray();

    ArrayList<String> matches = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION);
    for (String result : matches) {
      arr.pushString(result);
    }

    WritableMap event = Arguments.createMap();
    event.putArray("value", arr);
    sendEvent("onSpeechResults", event);
    Log.d("ASR", "onResults()");
  }

  @Override
  public void onRmsChanged(float rmsdB) {
    WritableMap event = Arguments.createMap();
    event.putDouble("value", (double) rmsdB);
    sendEvent("onSpeechVolumeChanged", event);
  }

  public static String getErrorText(int errorCode) {
    String message;
    switch (errorCode) {
      case SpeechRecognizer.ERROR_AUDIO:
        message = "Audio recording error";
        break;
      case SpeechRecognizer.ERROR_CLIENT:
        message = "Client side error";
        break;
      case SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS:
        message = "Insufficient permissions";
        break;
      case SpeechRecognizer.ERROR_NETWORK:
        message = "Network error";
        break;
      case SpeechRecognizer.ERROR_NETWORK_TIMEOUT:
        message = "Network timeout";
        break;
      case SpeechRecognizer.ERROR_NO_MATCH:
        message = "No match";
        break;
      case SpeechRecognizer.ERROR_RECOGNIZER_BUSY:
        message = "RecognitionService busy";
        break;
      case SpeechRecognizer.ERROR_SERVER:
        message = "error from server";
        break;
      case SpeechRecognizer.ERROR_SPEECH_TIMEOUT:
        message = "No speech input";
        break;
      default:
        message = "Didn't understand, please try again.";
        break;
    }
    return message;
  }
}

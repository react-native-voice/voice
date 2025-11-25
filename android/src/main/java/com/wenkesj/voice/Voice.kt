package com.wenkesj.voice

import android.Manifest
import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.speech.RecognitionListener
import android.speech.RecognitionService
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.annotation.Nullable
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext.RCTDeviceEventEmitter
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.PermissionAwareActivity
import java.util.Locale


/**
 * Voice - Android Speech Recognition implementation
 * Handles speech-to-text using Android's SpeechRecognizer API
 * Events are emitted via RCTDeviceEventEmitter to JavaScript
 */
class Voice(context: ReactApplicationContext) : RecognitionListener {
  val reactContext: ReactApplicationContext = context
  private var speech: SpeechRecognizer? = null
  private var isRecognizing = false
  private var locale: String? = null

  private fun getLocale(locale: String?): String {
    if (locale != null && locale.isNotEmpty()) {
      // Normalize locale format (e.g., "id" -> "id-ID", "ur" -> "ur-PK")
      val normalizedLocale = normalizeLocale(locale)
      Log.d("ASR", "Using provided locale: $locale -> $normalizedLocale")
      return normalizedLocale
    }
    val defaultLocale = Locale.getDefault().toString()
    Log.d("ASR", "Using default locale: $defaultLocale")
    return defaultLocale
  }
  
  private fun normalizeLocale(locale: String): String {
    // Handle common locale formats
    val parts = locale.split("-", "_")
    val language = parts[0].lowercase()
    
    // Map common language codes to full locale codes
    val localeMap = mapOf(
      "id" to "id-ID",  // Indonesian
      "in" to "id-ID",  // Indonesian (alternative)
      "ur" to "ur-PK",  // Urdu (Pakistan)
      "hi" to "hi-IN",  // Hindi
      "en" to "en-US",  // English (default to US)
      "ms" to "ms-MY",  // Malay (Malaysia)
      "ar" to "ar-SA",  // Arabic
      "bn" to "bn-BD",  // Bengali
    )
    
    // If it's already in format "lang-COUNTRY", return as is
    if (parts.size >= 2) {
      return locale.replace("_", "-")
    }
    
    // Otherwise, try to map it
    return localeMap[language] ?: locale
  }

  private fun startListening(opts: ReadableMap) {
    Log.d("ASR", "startListening called with locale: ${this.locale}")
    if (speech != null) {
      speech?.destroy()
      speech = null
    }

    // Check if speech recognition is available
    if (!SpeechRecognizer.isRecognitionAvailable(this.reactContext)) {
      throw Exception("Speech recognition is not available on this device")
    }

    speech = if (opts.hasKey("RECOGNIZER_ENGINE")) {
      when (opts.getString("RECOGNIZER_ENGINE")) {
        "GOOGLE" -> {
          SpeechRecognizer.createSpeechRecognizer(
            this.reactContext,
            ComponentName.unflattenFromString("com.google.android.googlequicksearchbox/com.google.android.voicesearch.serviceapi.GoogleRecognitionService")
          )
        }

        else -> SpeechRecognizer.createSpeechRecognizer(this.reactContext)
      }
    } else {
      SpeechRecognizer.createSpeechRecognizer(this.reactContext)
    }

    if (speech == null) {
      throw Exception("Failed to create SpeechRecognizer")
    }

    speech?.setRecognitionListener(this)
    Log.d("ASR", "startListening() - RecognitionListener set")

    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
    Log.d("ASR", "startListening() - Intent created")
    
    // Set default language model if not specified
    var languageModelSet = false

    // Load the intent with options from JS
    val iterator = opts.keySetIterator()
    while (iterator.hasNextKey()) {
      val key = iterator.nextKey()
      when (key) {
        "EXTRA_LANGUAGE_MODEL" -> {
          languageModelSet = true
          when (opts.getString(key)) {
            "LANGUAGE_MODEL_FREE_FORM" -> intent.putExtra(
              RecognizerIntent.EXTRA_LANGUAGE_MODEL,
              RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )

            "LANGUAGE_MODEL_WEB_SEARCH" -> intent.putExtra(
              RecognizerIntent.EXTRA_LANGUAGE_MODEL,
              RecognizerIntent.LANGUAGE_MODEL_WEB_SEARCH
            )

            else -> intent.putExtra(
              RecognizerIntent.EXTRA_LANGUAGE_MODEL,
              RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
          }
        }

        "EXTRA_MAX_RESULTS" -> {
          val extras = opts.getDouble(key)
          intent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, extras.toInt())
        }

        "EXTRA_PARTIAL_RESULTS" -> {
          intent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, opts.getBoolean(key))
        }

        "EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS" -> {
          val extras = opts.getDouble(key)
          intent.putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, extras.toInt())
        }

        "EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS" -> {
          val extras = opts.getDouble(key)
          intent.putExtra(
            RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS,
            extras.toInt()
          )
        }

        "EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS" -> {
          val extras = opts.getDouble(key)
          intent.putExtra(
            RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS,
            extras.toInt()
          )
        }
      }
    }
    
    // Set default language model if not specified
    if (!languageModelSet) {
      intent.putExtra(
        RecognizerIntent.EXTRA_LANGUAGE_MODEL,
        RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
      )
    }

    // Set locale - ensure it's in the correct format
    val localeString = getLocale(this.locale)
    Log.d("ASR", "Setting locale to: $localeString")
    intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeString)
    
    // Add language preference hint for better recognition
    intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, localeString)
    
    // Enable partial results by default for better UX
    if (!opts.hasKey("EXTRA_PARTIAL_RESULTS")) {
      intent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
      Log.d("ASR", "startListening() - Partial results enabled by default")
    }
    
    Log.d("ASR", "startListening() - Calling speech?.startListening()")
    speech?.startListening(intent)
    Log.d("ASR", "startListening() - startListening() called")
  }

  private fun startSpeechWithPermissions(locale: String, opts: ReadableMap, callback: Callback) {
    this.locale = locale
    Log.d("ASR", "startSpeechWithPermissions() - Locale: $locale")

    val mainHandler = Handler(reactContext.mainLooper)
    mainHandler.post {
      try {
        Log.d("ASR", "startSpeechWithPermissions() - Starting recognition")
        startListening(opts)
        isRecognizing = true
        Log.d("ASR", "startSpeechWithPermissions() - Recognition started successfully")
        callback.invoke(false)
      } catch (e: Exception) {
        Log.e("ASR", "startSpeechWithPermissions() - Error: ${e.message}", e)
        callback.invoke(e.message)
      }
    }
  }

  fun startSpeech(locale: String?, opts: ReadableMap, callback: Callback?) {
    if (!isPermissionGranted() && opts.getBoolean("REQUEST_PERMISSIONS_AUTO")) {
      val PERMISSIONS = arrayOf<String>(Manifest.permission.RECORD_AUDIO)
      if (reactContext.currentActivity != null) {
        (reactContext.currentActivity as PermissionAwareActivity).requestPermissions(
          PERMISSIONS, 1
        ) { requestCode, permissions, grantResults ->
          var permissionsGranted = true
          for (i in permissions.indices) {
            val granted = grantResults[i] == PackageManager.PERMISSION_GRANTED
            permissionsGranted = permissionsGranted && granted
          }
          if (permissionsGranted) {
            startSpeechWithPermissions(locale!!, opts, callback!!)
          } else {
            val errorMessage = "Permission denied: RECORD_AUDIO permission is required"
            callback?.invoke(errorMessage)
          }
          permissionsGranted
        }
      } else {
        val errorMessage = "Current activity is null, cannot request permissions"
        callback?.invoke(errorMessage)
      }
      return
    }
    
    // Check if permission is granted before starting
    if (!isPermissionGranted()) {
      val errorMessage = "RECORD_AUDIO permission is required but not granted"
      callback?.invoke(errorMessage)
      return
    }
    
    startSpeechWithPermissions(locale!!, opts, callback!!)
  }


  fun stopSpeech(callback: Callback) {
    val mainHandler = Handler(reactContext.mainLooper)
    mainHandler.post {
      try {
        if (speech != null) {
          speech!!.stopListening()
        }
        isRecognizing = false
        callback.invoke(false)
      } catch (e: java.lang.Exception) {
        callback.invoke(e.message)
      }
    }
  }

  fun cancelSpeech(callback: Callback) {
    val mainHandler = Handler(reactContext.mainLooper)
    mainHandler.post {
      try {
        if (speech != null) {
          speech!!.cancel()
        }
        isRecognizing = false
        callback.invoke(false)
      } catch (e: java.lang.Exception) {
        callback.invoke(e.message)
      }
    }
  }

  fun destroySpeech(callback: Callback) {
    val mainHandler = Handler(reactContext.mainLooper)
    mainHandler.post {
      try {
        if (speech != null) {
          speech!!.destroy()
        }
        speech = null
        isRecognizing = false
        callback.invoke(false)
      } catch (e: java.lang.Exception) {
        callback.invoke(e.message)
      }
    }
  }

  fun isSpeechAvailable(callback: Callback) {
    val self: Voice = this
    val mainHandler = Handler(reactContext.mainLooper)
    mainHandler.post {
      try {
        val isSpeechAvailable = SpeechRecognizer.isRecognitionAvailable(self.reactContext)
        callback.invoke(isSpeechAvailable, false)
      } catch (e: java.lang.Exception) {
        callback.invoke(false, e.message)
      }
    }
  }

  fun getSpeechRecognitionServices(promise: Promise) {
    val mainHandler = Handler(reactContext.mainLooper)
    mainHandler.post {
      try {
        Log.d("ASR", "getSpeechRecognitionServices() - Starting to query services")
        // RecognitionService.SERVICE_INTERFACE is the action string for recognition services
        val intent = Intent(RecognitionService.SERVICE_INTERFACE)
        // Use MATCH_DEFAULT_ONLY to get only services that can handle the intent by default
        val services = reactContext.packageManager
          .queryIntentServices(intent, PackageManager.MATCH_DEFAULT_ONLY)
        
        Log.d("ASR", "getSpeechRecognitionServices() - Found ${services.size} services")
        val serviceNames = Arguments.createArray()
        
        if (services.isEmpty()) {
          Log.w("ASR", "getSpeechRecognitionServices() - No recognition services found on device")
        } else {
          for (service in services) {
            val packageName = service.serviceInfo.packageName
            Log.d("ASR", "getSpeechRecognitionServices() - Service: $packageName")
            serviceNames.pushString(packageName)
          }
        }

        Log.d("ASR", "getSpeechRecognitionServices() - Resolving promise with ${serviceNames.size()} services")
        promise.resolve(serviceNames)
      } catch (e: Exception) {
        Log.e("ASR", "getSpeechRecognitionServices() - Error: ${e.message}", e)
        e.printStackTrace()
        promise.reject("GET_SERVICES_ERROR", e.message ?: "Failed to get speech recognition services", e)
      }
    }
  }

  private fun isPermissionGranted(): Boolean {
    val permission = Manifest.permission.RECORD_AUDIO
    val res: Int = ContextCompat.checkSelfPermission(reactContext, permission)
    return res == PackageManager.PERMISSION_GRANTED
  }

  fun isRecognizing(callback: Callback) {
    callback.invoke(isRecognizing)
  }

  /**
   * Send an event to JavaScript via RCTDeviceEventEmitter
   * Works with both Bridge mode and Bridgeless mode (new architecture)
   */
  private fun sendEvent(eventName: String, params: WritableMap) {
    // Use main thread handler - required for RCTDeviceEventEmitter
    val mainHandler = Handler(reactContext.mainLooper)
    mainHandler.post {
      try {
        val deviceEventEmitter = reactContext.getJSModule(RCTDeviceEventEmitter::class.java)
        if (deviceEventEmitter == null) {
          Log.e("ASR", "sendEvent($eventName) - DeviceEventEmitter is null!")
          return@post
        }
        
        // Emit the event
        deviceEventEmitter.emit(eventName, params)
        
        // Only log non-volume events to avoid log spam
        if (eventName != "onSpeechVolumeChanged") {
          Log.d("ASR", "sendEvent($eventName) - Event emitted to JS")
        }
      } catch (e: Exception) {
        Log.e("ASR", "sendEvent($eventName) - Error: ${e.message}", e)
      }
    }
  }

  private fun getErrorText(errorCode: Int): String {
    val message = when (errorCode) {
      SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
      SpeechRecognizer.ERROR_CLIENT -> "Client side error"
      SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
      SpeechRecognizer.ERROR_NETWORK -> "Network error"
      SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
      SpeechRecognizer.ERROR_NO_MATCH -> "No match"
      SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "RecognitionService busy"
      SpeechRecognizer.ERROR_SERVER -> "error from server"
      SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
      else -> "Didn't understand, please try again."
    }
    return message
  }


  override fun onReadyForSpeech(params: Bundle?) {
    val event = Arguments.createMap()
    event.putBoolean("error", false)
    sendEvent("onSpeechStart", event)
    Log.d("ASR", "onReadyForSpeech()")
  }

  override fun onBeginningOfSpeech() {
    val event = Arguments.createMap()
    event.putBoolean("error", false)
    sendEvent("onSpeechStart", event)
    Log.d("ASR", "onBeginningOfSpeech()")
  }

  override fun onRmsChanged(rmsdB: Float) {
    val event = Arguments.createMap()
    event.putDouble("value", rmsdB.toDouble())
    sendEvent("onSpeechVolumeChanged", event)
  }

  override fun onBufferReceived(buffer: ByteArray?) {
    val event = Arguments.createMap()
    event.putBoolean("isFinal", false)
    sendEvent("onSpeechRecognized", event)
    Log.d("ASR", "onBufferReceived()")
  }

  override fun onEndOfSpeech() {
    val event = Arguments.createMap()
    event.putBoolean("error", false)
    sendEvent("onSpeechEnd", event)
    Log.d("ASR", "onEndOfSpeech()")
    isRecognizing = false
  }


  override fun onError(error: Int) {
    isRecognizing = false
    val errorMessage = String.format("%d/%s", error, getErrorText(error))
    val errorData = Arguments.createMap()
    errorData.putString("message", errorMessage)
    errorData.putString("code", java.lang.String.valueOf(error))
    val event = Arguments.createMap()
    event.putMap("error", errorData)
    sendEvent("onSpeechError", event)
    Log.d("ASR", "onError() - $errorMessage")
  }

  override fun onResults(results: Bundle?) {
    isRecognizing = false
    Log.d("ASR", "onResults() called")
    
    val arr = Arguments.createArray()
    
    if (results != null) {
      val matches = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
      
      if (matches != null && matches.isNotEmpty()) {
        for (result in matches) {
          if (!result.isNullOrEmpty()) {
            arr.pushString(result)
          }
        }
        Log.d("ASR", "onResults() - ${arr.size()} results: ${matches.firstOrNull()}")
      }
    }
    
    val event = Arguments.createMap()
    event.putArray("value", arr)
    sendEvent("onSpeechResults", event)
  }

  override fun onPartialResults(partialResults: Bundle?) {
    val arr = Arguments.createArray()
    
    if (partialResults != null) {
      val matches = partialResults.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
      
      if (matches != null && matches.isNotEmpty()) {
        for (result in matches) {
          if (!result.isNullOrEmpty()) {
            arr.pushString(result)
          }
        }
      }
    }
    
    val event = Arguments.createMap()
    event.putArray("value", arr)
    sendEvent("onSpeechPartialResults", event)
  }

  override fun onEvent(eventType: Int, params: Bundle?) {
    TODO("Not yet implemented")
  }
}

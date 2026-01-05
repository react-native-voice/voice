package com.wenkesj.voice

import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReactMethod

/**
 * React Native Voice Module
 * Provides speech recognition functionality for both old and new architectures
 */
class VoiceModule internal constructor(context: ReactApplicationContext) :
  VoiceSpec(context) {
  
  // Single Voice instance - created once and reused
  private val voiceInstance: Voice by lazy { Voice(context) }

  // For new architecture - provides the Voice instance to the base class
  override fun getVoice(): Voice = voiceInstance

  @ReactMethod
  override fun destroySpeech(callback: Callback) {
    voiceInstance.destroySpeech(callback)
  }

  @ReactMethod
  override fun startSpeech(locale: String, opts: ReadableMap, callback: Callback) {
    voiceInstance.startSpeech(locale, opts, callback)
  }

  @ReactMethod
  override fun stopSpeech(callback: Callback) {
    voiceInstance.stopSpeech(callback)
  }

  @ReactMethod
  override fun cancelSpeech(callback: Callback) {
    voiceInstance.cancelSpeech(callback)
  }

  @ReactMethod
  override fun isSpeechAvailable(callback: Callback) {
    voiceInstance.isSpeechAvailable(callback)
  }

  @ReactMethod
  override fun getSpeechRecognitionServices(promise: Promise) {
    voiceInstance.getSpeechRecognitionServices(promise)
  }

  @ReactMethod
  override fun isRecognizing(callback: Callback) {
    voiceInstance.isRecognizing(callback)
  }

  @ReactMethod
  override fun addListener(eventType: String) {
    // Required for NativeEventEmitter - no-op since we use DeviceEventEmitter
  }

  @ReactMethod
  override fun removeListeners(count: Double) {
    // Required for NativeEventEmitter - no-op since we use DeviceEventEmitter
  }

  override fun getName(): String {
    return NAME
  }

  companion object {
    const val NAME = "Voice"
  }
}

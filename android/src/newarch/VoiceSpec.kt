package com.wenkesj.voice

import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap

/**
 * TurboModule spec for Voice (New Architecture)
 * This is an abstract base class - VoiceModule will provide the actual Voice instance
 */
abstract class VoiceSpec internal constructor(context: ReactApplicationContext) :
  NativeVoiceAndroidSpec(context) {

  // Abstract method to get Voice instance - VoiceModule will provide this
  protected abstract fun getVoice(): Voice

  override fun destroySpeech(callback: Callback) {
    getVoice().destroySpeech(callback)
  }

  override fun startSpeech(locale: String, opts: ReadableMap, callback: Callback) {
    getVoice().startSpeech(locale, opts, callback)
  }

  override fun stopSpeech(callback: Callback) {
    getVoice().stopSpeech(callback)
  }

  override fun cancelSpeech(callback: Callback) {
    getVoice().cancelSpeech(callback)
  }

  override fun isSpeechAvailable(callback: Callback) {
    getVoice().isSpeechAvailable(callback)
  }

  override fun getSpeechRecognitionServices(promise: Promise) {
    getVoice().getSpeechRecognitionServices(promise)
  }

  override fun isRecognizing(callback: Callback) {
    getVoice().isRecognizing(callback)
  }

  override fun addListener(eventType: String) {
    // Required for NativeEventEmitter
  }

  override fun removeListeners(count: Double) {
    // Required for NativeEventEmitter
  }

  override fun getName(): String {
    return NAME
  }

  companion object {
    const val NAME = "Voice"
  }
}

package com.wenkesj.voice

import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.ReactMethod;

class VoiceModule internal constructor(context: ReactApplicationContext) :
  VoiceSpec(context) {
  private val voice = Voice(context)

  @ReactMethod
  override fun destroySpeech(callback: Callback) {
    voice.destroySpeech(callback)
  }

  @ReactMethod
  override fun startSpeech(locale: String, opts: ReadableMap, callback: Callback) {
    voice.startSpeech(locale,opts,callback)
  }

  @ReactMethod
  override fun stopSpeech(callback: Callback) {
    voice.stopSpeech(callback)
  }

  @ReactMethod
  override fun cancelSpeech(callback: Callback) {
    voice.cancelSpeech(callback)
  }

  @ReactMethod
  override fun isSpeechAvailable(callback: Callback) {
    voice.isSpeechAvailable(callback)
  }

  @ReactMethod
  override fun getSpeechRecognitionServices(promise: Promise) {
    voice.getSpeechRecognitionServices(promise)
  }

  @ReactMethod
  override fun isRecognizing(callback: Callback) {
    voice.isRecognizing(callback)
  }

  override fun addListener(eventType: String) {

  }

  override fun removeListeners(count: Double) {

  }

  override fun getName(): String {
    return NAME
  }

  companion object {
    const val NAME = "Voice"
  }
}

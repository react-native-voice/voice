package com.wenkesj.voice

import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReadableMap

abstract class VoiceSpec internal constructor(context: ReactApplicationContext) :
  NativeVoiceAndroidSpec(context) {
  private val voice = Voice(context)

  override fun destroySpeech(callback: Callback) {
    voice.destroySpeech(callback)
  }

  override fun startSpeech(locale: String, opts: ReadableMap, callback: Callback) {
    voice.startSpeech(locale,opts,callback)
  }

  override fun stopSpeech(callback: Callback) {
    voice.stopSpeech(callback)
  }

  override fun cancelSpeech(callback: Callback) {
    voice.cancelSpeech(callback)
  }

  override fun isSpeechAvailable(callback: Callback) {
    voice.isSpeechAvailable(callback)
  }

  override fun getSpeechRecognitionServices(promise: Promise) {
    voice.getSpeechRecognitionServices(promise)
  }

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

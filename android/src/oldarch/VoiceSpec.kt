package com.wenkesj.voice

import com.facebook.react.bridge.Callback
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReadableMap

/**
 * Native Module spec for Voice (Old Architecture / Bridge)
 * This is an abstract base class - VoiceModule will provide the actual implementation
 */
abstract class VoiceSpec internal constructor(context: ReactApplicationContext) :
  ReactContextBaseJavaModule(context) {

  // For compatibility with VoiceModule (shared between old/new arch)
  protected open fun getVoice(): Voice {
    throw UnsupportedOperationException("getVoice() must be implemented by subclass")
  }

  abstract fun destroySpeech(callback: Callback)

  abstract fun startSpeech(locale: String, opts: ReadableMap, callback: Callback)

  abstract fun stopSpeech(callback: Callback)

  abstract fun cancelSpeech(callback: Callback)

  abstract fun isSpeechAvailable(callback: Callback)

  abstract fun getSpeechRecognitionServices(promise: Promise)

  abstract fun isRecognizing(callback: Callback)

  abstract fun addListener(eventType: String)

  abstract fun removeListeners(count: Double)

  companion object {
    const val NAME = "Voice"
  }
}

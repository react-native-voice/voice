'use strict';
import React, {
  NativeModules,
  DeviceEventEmitter,
} from 'react-native';

const { RCTVoice } = NativeModules;

class Voice {
  constructor() {
    this._loaded = false;
    this._events = {
      'onSpeechStart': this._onSpeechStart.bind(this),
      'onSpeechRecognized': this._onSpeechRecognized.bind(this),
      'onSpeechEnd': this._onSpeechEnd.bind(this),
      'onSpeechError': this._onSpeechError.bind(this),
      'onSpeechResults': this._onSpeechResults.bind(this),
      'onSpeechPartialResults': this._onSpeechPartialResults.bind(this),
      'onSpeechVolumeChanged': this._onSpeechVolumeChanged.bind(this)
    };
  }
  destroy() {
    return RCTVoice.destroySpeech((error) => {
      if (error) {
        return error;
      }
      Object.keys(this._events)
        .map((key, index) => DeviceEventEmitter.removeListener(key));
      return null;
    });
  }
  start() {
    if (!this._loaded) {
      Object.keys(this._events)
        .map((key, index) => DeviceEventEmitter.addListener(key, this._events[key]));
    }
    return RCTVoice.startSpeech((error) => {
      if (error) {
        return error;
      }
      return null;
    });
  }
  stop() {
    return RCTVoice.stopSpeech((error) => {
      if (error) {
        return error;
      }
      return null;
    });
  }
  cancel() {
    return RCTVoice.cancelSpeech((error) => {
      if (error) {
        return error;
      }
      return null;
    });
  }
  isAvailable(callback) {
    RCTVoice.isSpeechAvailable(callback);
  }
  isRecognizing() {
    return RCTVoice.isRecognizing(isRecognizing => isRecognizing);
  }
  _onSpeechStart(e) {
    if (this.onSpeechStart) {
      this.onSpeechStart(e);
    }
  }
  _onSpeechRecognized(e) {
    if (this.onSpeechRecognized) {
      this.onSpeechRecognized(e);
    }
  }
  _onSpeechEnd(e) {
    if (this.onSpeechEnd) {
      this.onSpeechEnd(e);
    }
  }
  _onSpeechError(e) {
    if (this.onSpeechError) {
      this.onSpeechError(e);
    }
  }
  _onSpeechResults(e) {
    if (this.onSpeechResults) {
      this.onSpeechResults(e);
    }
  }
  _onSpeechPartialResults(e) {
    if (this.onSpeechPartialResults) {
      this.onSpeechPartialResults(e);
    }
  }
  _onSpeechVolumeChanged(e) {
    if (this.onSpeechVolumeChanged) {
      this.onSpeechVolumeChanged(e);
    }
  }
}

module.exports = new Voice();

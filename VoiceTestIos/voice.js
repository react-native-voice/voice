'use strict';
import React, {
  NativeModules,
  DeviceEventEmitter,
  NativeEventEmitter
} from 'react-native';

const { Voice } = NativeModules;
const voiceEmitter = new NativeEventEmitter(Voice);

class RCTVoice {
  constructor() {
    this._loaded = false;
    this._listeners = null;
    this._events = {
      'onSpeechStart': this._onSpeechStart.bind(this),
      'onSpeechRecognized': this._onSpeechRecognized.bind(this),
      'onSpeechEnd': this._onSpeechEnd.bind(this),
      'onSpeechError': this._onSpeechError.bind(this),
      'onSpeechResults': this._onSpeechResults.bind(this),
      'onSpeechPartialResults': this._onSpeechPartialResults.bind(this),
      // 'onSpeechVolumeChanged': this._onSpeechVolumeChanged.bind(this)
    };


    this.subscription = voiceEmitter.addListener(
    // this.subscription = NativeAppEventEmitter.addListener(
      'SpeechToText',
      (result) => {
        console.log(result);
        // if (result.error) {
        //   this.onSpeechError(JSON.stringify(result.error))
        //   // alert(JSON.stringify(result.error));
        // } else {
        //   if(result.isFinal) {
        //     this.onSpeechRecognized(true);
        //     this.onSpeechEnd(true);
        //     this.onSpeechResults([result.bestTranscription.formattedString]);
        //   }
        //   this.onSpeechPartialResults(result.transcriptions.map(a => { return a.formattedString}));



        //    console.log(result.bestTranscription.formattedString);
        // }



      }
    );


  }


  destroy() {
    // return Voice.destroySpeech((error) => {
    //   if (error) {
    //     return error;
    //   }
    //   if (this._listeners) {
    //     this._listeners.map((listener, index) => listener.remove());
    //     this._listeners = null;
    //   }
    //   return null;
    // });
  }
  start(locale) {
    if (!this._loaded && !this._listeners) {
      this._listeners = Object.keys(this._events)
        .map((key, index) => voiceEmitter.addListener(key, this._events[key]));
    }
    return Voice.startSpeech(locale, (error) => {
      if (error) {
        return error;
      }
      return null;
    });

  }
  stop() {
    return Voice.finishRecognition((error) => {
      if (error) {
        return error;
      }
      return null;
    });
  }
  cancel() {
    return Voice.stopSpeech((error) => {
      if (error) {
        return error;
      }
      return null;
    });
  }
  // isAvailable(callback) {
  //   Voice.isSpeechAvailable(callback);
  // }
  // isRecognizing() {
  //   return Voice.isRecognizing(isRecognizing => isRecognizing);
  // }
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
  // _onSpeechVolumeChanged(e) {
  //   if (this.onSpeechVolumeChanged) {
  //     this.onSpeechVolumeChanged(e);
  //   }
  // }

}

module.exports = new RCTVoice();

import { NativeModules, NativeEventEmitter, Platform } from 'react-native';
import invariant from 'invariant';
import {
  VoiceModule,
  SpeechEvents,
  SpeechRecognizedEvent,
  SpeechErrorEvent,
  SpeechResultsEvent,
  SpeechStartEvent,
  SpeechEndEvent,
  SpeechVolumeChangeEvent,
} from './VoiceModuleTypes';

const Voice = NativeModules.Voice as VoiceModule;

// NativeEventEmitter is only availabe on React Native platforms, so this conditional is used to avoid import conflicts in the browser/server
const voiceEmitter =
  Platform.OS !== 'web' ? new NativeEventEmitter(Voice) : null;
type SpeechEvent = keyof SpeechEvents;

class RCTVoice {
  _loaded: boolean;
  _listeners: any[] | null;
  _events: Required<SpeechEvents>;

  constructor() {
    this._loaded = false;
    this._listeners = null;
    this._events = {
      onSpeechStart: this.onSpeechStart.bind(this),
      onSpeechRecognized: this.onSpeechRecognized.bind(this),
      onSpeechEnd: this.onSpeechEnd.bind(this),
      onSpeechError: this.onSpeechError.bind(this),
      onSpeechResults: this.onSpeechResults.bind(this),
      onSpeechPartialResults: this.onSpeechPartialResults.bind(this),
      onSpeechVolumeChanged: this.onSpeechVolumeChanged.bind(this),
    };
  }

  removeAllListeners() {
    Voice.onSpeechStart = undefined;
    Voice.onSpeechRecognized = undefined;
    Voice.onSpeechEnd = undefined;
    Voice.onSpeechError = undefined;
    Voice.onSpeechResults = undefined;
    Voice.onSpeechPartialResults = undefined;
    Voice.onSpeechVolumeChanged = undefined;
  }

  destroy() {
    if (!this._loaded && !this._listeners) {
      return Promise.resolve();
    }
    return new Promise((resolve, reject) => {
      Voice.destroySpeech((error: string) => {
        if (error) {
          reject(new Error(error));
        } else {
          if (this._listeners) {
            this._listeners.map(listener => listener.remove());
            this._listeners = null;
          }
          resolve();
        }
      });
    });
  }

  start(locale: any, options = {}) {
    if (!this._loaded && !this._listeners && voiceEmitter !== null) {
      this._listeners = (Object.keys(this._events) as SpeechEvent[]).map(
        (key: SpeechEvent) => voiceEmitter.addListener(key, this._events[key]),
      );
    }

    return new Promise((resolve, reject) => {
      const callback = (error: string) => {
        if (error) {
          reject(new Error(error));
        } else {
          resolve();
        }
      };
      if (Platform.OS === 'android') {
        Voice.startSpeech(
          locale,
          Object.assign(
            {
              EXTRA_LANGUAGE_MODEL: 'LANGUAGE_MODEL_FREE_FORM',
              EXTRA_MAX_RESULTS: 5,
              EXTRA_PARTIAL_RESULTS: true,
              REQUEST_PERMISSIONS_AUTO: true,
            },
            options,
          ),
          callback,
        );
      } else {
        Voice.startSpeech(locale, callback);
      }
    });
  }
  stop() {
    if (!this._loaded && !this._listeners) {
      return Promise.resolve();
    }
    return new Promise((resolve, reject) => {
      Voice.stopSpeech(error => {
        if (error) {
          reject(new Error(error));
        } else {
          resolve();
        }
      });
    });
  }
  cancel() {
    if (!this._loaded && !this._listeners) {
      return Promise.resolve();
    }
    return new Promise((resolve, reject) => {
      Voice.cancelSpeech(error => {
        if (error) {
          reject(new Error(error));
        } else {
          resolve();
        }
      });
    });
  }
  isAvailable(): Promise<0 | 1> {
    return new Promise((resolve, reject) => {
      Voice.isSpeechAvailable((isAvailable: 0 | 1, error: string) => {
        if (error) {
          reject(new Error(error));
        } else {
          resolve(isAvailable);
        }
      });
    });
  }

  /**
   * (Android) Get a list of the speech recognition engines available on the device
   * */
  getSpeechRecognitionServices() {
    if (Platform.OS !== 'android') {
      invariant(
        Voice,
        'Speech recognition services can be queried for only on Android',
      );
      return;
    }

    return Voice.getSpeechRecognitionServices();
  }

  isRecognizing(): Promise<0 | 1> {
    return new Promise(resolve => {
      Voice.isRecognizing((isRecognizing: 0 | 1) => resolve(isRecognizing));
    });
  }
  onSpeechStart(e: SpeechStartEvent) {
    if (this.onSpeechStart) {
      this.onSpeechStart(e);
    }
  }
  onSpeechRecognized(e: SpeechRecognizedEvent) {
    if (this.onSpeechRecognized) {
      this.onSpeechRecognized(e);
    }
  }
  onSpeechEnd(e: SpeechEndEvent) {
    if (this.onSpeechEnd) {
      this.onSpeechEnd(e);
    }
  }
  onSpeechError(e: SpeechErrorEvent) {
    if (this.onSpeechError) {
      this.onSpeechError(e);
    }
  }
  onSpeechResults(e: SpeechResultsEvent) {
    if (this.onSpeechResults) {
      this.onSpeechResults(e);
    }
  }
  onSpeechPartialResults(e: SpeechResultsEvent) {
    if (this.onSpeechPartialResults) {
      this.onSpeechPartialResults(e);
    }
  }
  onSpeechVolumeChanged(e: SpeechVolumeChangeEvent) {
    if (this.onSpeechVolumeChanged) {
      this.onSpeechVolumeChanged(e);
    }
  }
}

export {
  SpeechEndEvent,
  SpeechErrorEvent,
  SpeechEvents,
  SpeechStartEvent,
  SpeechRecognizedEvent,
  SpeechResultsEvent,
  SpeechVolumeChangeEvent,
};
export default new RCTVoice();

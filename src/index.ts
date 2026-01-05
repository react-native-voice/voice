import {
  NativeModules,
  DeviceEventEmitter,
  NativeEventEmitter,
  Platform,
  type EventSubscription,
} from 'react-native';
import {
  type SpeechEvents,
  type TranscriptionEvents,
  type TranscriptionEndEvent,
  type TranscriptionErrorEvent,
  type TranscriptionStartEvent,
  type SpeechRecognizedEvent,
  type SpeechErrorEvent,
  type SpeechResultsEvent,
  type SpeechStartEvent,
  type SpeechEndEvent,
  type SpeechVolumeChangeEvent,
  type TranscriptionResultsEvent,
} from './VoiceModuleTypes';

const LINKING_ERROR =
  `The package '@react-native-voice/voice' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

//@ts-expect-error - Check if TurboModules are enabled (new architecture)
const isTurboModuleEnabled = global.__turboModuleProxy != null;

//@ts-expect-error - Check if Bridgeless mode is enabled
const isBridgelessEnabled = global.RN$Bridgeless === true;

// Try to get the native module - with fallback for Bridgeless mode
const getVoiceModule = () => {
  // Try TurboModule first if enabled
  if (isTurboModuleEnabled) {
    try {
      const turboModule = Platform.OS === 'android'
        ? require('./NativeVoiceAndroid').default
        : require('./NativeVoiceIOS').default;
      if (turboModule) {
        return turboModule;
      }
    } catch (e) {
      // TurboModule not available, fall through to NativeModules
    }
  }
  
  // Fallback to NativeModules (works in both Bridge and Bridgeless mode)
  return NativeModules.Voice;
};

const Voice = getVoiceModule() || new Proxy(
  {},
  {
    get() {
      throw new Error(LINKING_ERROR);
    },
  },
);

// Platform-specific event emitter setup:
// - iOS: Always uses RCTEventEmitter (module-specific), needs NativeEventEmitter
// - Android: Uses RCTDeviceEventEmitter (global), needs DeviceEventEmitter
const voiceEmitter = (() => {
  if (Platform.OS === 'web') {
    return null;
  }
  
  // iOS always uses NativeEventEmitter with the Voice module
  if (Platform.OS === 'ios') {
    try {
      return Voice ? new NativeEventEmitter(Voice) : DeviceEventEmitter;
    } catch (e) {
      return DeviceEventEmitter;
    }
  }
  
  // Android uses DeviceEventEmitter (global event bus)
  return DeviceEventEmitter;
})();
type SpeechEvent = keyof SpeechEvents;
type TranscriptionEvent = keyof TranscriptionEvents;

class RCTVoice {
  private _loaded: boolean;
  private _listeners: EventSubscription[];
  private _events: Required<SpeechEvents> & Required<TranscriptionEvents>;
  private _needsListenerUpdate: boolean;

  constructor() {
    this._loaded = false;
    this._listeners = [];
    this._needsListenerUpdate = false;
    this._events = {
      onSpeechStart: () => {},
      onSpeechRecognized: () => {},
      onSpeechEnd: () => {},
      onSpeechError: () => {},
      onSpeechResults: () => {},
      onSpeechPartialResults: () => {},
      onSpeechVolumeChanged: () => {},
      onTranscriptionStart: () => {},
      onTranscriptionEnd: () => {},
      onTranscriptionError: () => {},
      onTranscriptionResults: () => {},
    };
  }

  removeAllListeners() {
    if (this._listeners) {
      this._listeners.forEach((listener) => {
        if (listener?.remove) {
          listener?.remove();
        }
      });

      this._listeners = JSON.parse(JSON.stringify([]));
    }
  }

  destroy() {
    if (!this._loaded || this._listeners.length === 0) {
      return Promise.resolve();
    }
    return new Promise<void>((resolve, reject) => {
      Voice.destroySpeech((error: string) => {
        if (error) {
          reject(new Error(error));
        } else {
          this.removeAllListeners();
          resolve();
        }
      });
    });
  }
  destroyTranscription() {
    if (!this._loaded || this._listeners.length === 0) {
      return Promise.resolve();
    }
    return new Promise<void>((resolve, reject) => {
      Voice.destroyTranscription((error: string) => {
        if (error) {
          reject(new Error(error));
        } else {
          if (this._listeners?.length > 0) {
            this._listeners.forEach((listener) => listener.remove());
            this._listeners = JSON.parse(JSON.stringify([]));
          }
          resolve();
        }
      });
    });
  }

  start(locale: string, options = {}) {
    // Ensure listeners are set up BEFORE starting recognition
    this._setupListeners();
    
    return new Promise<void>((resolve, reject) => {
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
  startTranscription(url: string, locale: string, options = {}) {
    // Ensure listeners are set up BEFORE starting transcription
    this._setupListeners();

    return new Promise<void>((resolve, reject) => {
      const callback = (error: string) => {
        if (error) {
          reject(new Error(error));
        } else {
          resolve();
        }
      };
      if (Platform.OS === 'android') {
        Voice.startTranscription(
          url,
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
        Voice.startTranscription(url, locale, callback);
      }
    });
  }
  stop() {
    if (!this._loaded || this._listeners.length === 0) {
      return Promise.resolve();
    }
    return new Promise<void>((resolve, reject) => {
      Voice.stopSpeech((error?: string) => {
        if (error) {
          reject(new Error(error));
        } else {
          resolve();
        }
      });
    });
  }
  stopTranscription() {
    if (!this._loaded || this._listeners.length === 0) {
      return Promise.resolve();
    }
    return new Promise<void>((resolve, reject) => {
      Voice.stopTranscription((error?: string) => {
        if (error) {
          reject(new Error(error));
        } else {
          resolve();
        }
      });
    });
  }
  cancel() {
    if (!this._loaded || this._listeners.length === 0) {
      return Promise.resolve();
    }
    return new Promise<void>((resolve, reject) => {
      Voice.cancelSpeech((error?: string) => {
        if (error) {
          reject(new Error(error));
        } else {
          resolve();
        }
      });
    });
  }
  cancelTranscription() {
    if (!this._loaded || this._listeners.length === 0) {
      return Promise.resolve();
    }
    return new Promise<void>((resolve, reject) => {
      Voice.cancelTranscription((error?: string) => {
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
  getSpeechRecognitionServices(): Promise<string[]> {
    if (Platform.OS !== 'android') {
      return Promise.reject(
        new Error(
          'Speech recognition services can be queried for only on Android',
        ),
      );
    }

    return Voice.getSpeechRecognitionServices();
  }

  isRecognizing(): Promise<0 | 1> {
    return new Promise((resolve) => {
      Voice.isRecognizing((isRecognizing: 0 | 1) => resolve(isRecognizing));
    });
  }

  set onSpeechStart(fn: (e: SpeechStartEvent) => void) {
    if (this._events.onSpeechStart !== fn) {
      this._events.onSpeechStart = fn;
      this._needsListenerUpdate = true;
    }
  }

  set onTranscriptionStart(fn: (e: TranscriptionStartEvent) => void) {
    if (this._events.onTranscriptionStart !== fn) {
      this._events.onTranscriptionStart = fn;
      this._needsListenerUpdate = true;
    }
  }

  set onSpeechRecognized(fn: (e: SpeechRecognizedEvent) => void) {
    if (this._events.onSpeechRecognized !== fn) {
      this._events.onSpeechRecognized = fn;
      this._needsListenerUpdate = true;
    }
  }

  set onSpeechEnd(fn: (e: SpeechEndEvent) => void) {
    if (this._events.onSpeechEnd !== fn) {
      this._events.onSpeechEnd = fn;
      this._needsListenerUpdate = true;
    }
  }

  set onTranscriptionEnd(fn: (e: SpeechEndEvent) => void) {
    if (this._events.onTranscriptionEnd !== fn) {
      this._events.onTranscriptionEnd = fn;
      this._needsListenerUpdate = true;
    }
  }
  set onSpeechError(fn: (e: SpeechErrorEvent) => void) {
    if (this._events.onSpeechError !== fn) {
      this._events.onSpeechError = fn;
      this._needsListenerUpdate = true;
    }
  }

  set onTranscriptionError(fn: (e: TranscriptionErrorEvent) => void) {
    if (this._events.onTranscriptionError !== fn) {
      this._events.onTranscriptionError = fn;
      this._needsListenerUpdate = true;
    }
  }

  set onSpeechResults(fn: (e: SpeechResultsEvent) => void) {
    if (this._events.onSpeechResults !== fn) {
      this._events.onSpeechResults = fn;
      this._needsListenerUpdate = true;
    }
  }

  set onTranscriptionResults(fn: (e: TranscriptionResultsEvent) => void) {
    if (this._events.onTranscriptionResults !== fn) {
      this._events.onTranscriptionResults = fn;
      this._needsListenerUpdate = true;
    }
  }

  set onSpeechPartialResults(fn: (e: SpeechResultsEvent) => void) {
    if (this._events.onSpeechPartialResults !== fn) {
      this._events.onSpeechPartialResults = fn;
      this._needsListenerUpdate = true;
    }
  }
  set onSpeechVolumeChanged(fn: (e: SpeechVolumeChangeEvent) => void) {
    if (this._events.onSpeechVolumeChanged !== fn) {
      this._events.onSpeechVolumeChanged = fn;
      this._needsListenerUpdate = true;
    }
  }

  /**
   * Sets up event listeners for all registered event handlers.
   * This method is called before starting recognition to ensure listeners are active.
   * Listeners are only updated when handlers have changed (tracked via _needsListenerUpdate).
   */
  private _setupListeners() {
    if (voiceEmitter === null) {
      return;
    }
    
    // Only update listeners if handlers have changed or listeners haven't been set up yet
    if (!this._needsListenerUpdate && this._loaded && this._listeners.length > 0) {
      return;
    }
    
    // Remove existing listeners before setting up new ones
    if (this._listeners.length > 0) {
      this._listeners.forEach(listener => {
        try {
          listener.remove();
        } catch (e) {
          // Ignore errors when removing listeners
        }
      });
      this._listeners = [];
    }
    
    // Set up listeners for all events (both Speech and Transcription events)
    const newListeners: EventSubscription[] = [];
    const allEventKeys = [
      ...(Object.keys(this._events) as (SpeechEvent | TranscriptionEvent)[]),
    ];
    
    allEventKeys.forEach((key: SpeechEvent | TranscriptionEvent) => {
      const handler = this._events[key];
      
      if (!handler || typeof handler !== 'function') {
        return;
      }
      
      const currentHandler = handler;
      
      const listener = voiceEmitter!.addListener(key, (event: any) => {
        if (currentHandler) {
          try {
            currentHandler(event);
          } catch (error) {
            // Handler error - silently ignore
          }
        }
      });
      
      newListeners.push(listener);
    });
    
    this._listeners = newListeners;
    this._loaded = true;
    this._needsListenerUpdate = false;
  }
}

export type {
  SpeechEndEvent,
  SpeechErrorEvent,
  SpeechEvents,
  SpeechStartEvent,
  SpeechRecognizedEvent,
  SpeechResultsEvent,
  SpeechVolumeChangeEvent,
  TranscriptionEndEvent,
  TranscriptionErrorEvent,
  TranscriptionEvents,
  TranscriptionStartEvent,
  TranscriptionResultsEvent,
};
export default new RCTVoice();

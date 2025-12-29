import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  destroySpeech: (callback: (error: string) => void) => void;
  startSpeech: (locale: string, callback: (error: string) => void) => void;
  startTranscription: (
    filePath: string,
    locale: string,
    callback: (error: string) => void,
  ) => void;
  stopSpeech: (callback: (error: string) => void) => void;
  stopTranscription: (callback: (error: string) => void) => void;
  cancelSpeech: (callback: (error: string) => void) => void;
  cancelTranscription: (callback: (error: string) => void) => void;
  isSpeechAvailable: (
    callback: (isAvailable: boolean, error: string) => void,
  ) => void;
  isRecognizing: (callback: (isRecognizing: boolean) => void) => void;
  /**
   * Add an event listener for speech recognition events
   * Supported events: 'onSpeechStart', 'onSpeechRecognized', 'onSpeechEnd', 'onSpeechError', 'onSpeechResults', 'onSpeechPartialResults', 'onSpeechVolumeChanged', 'onTranscriptionStart', 'onTranscriptionEnd', 'onTranscriptionError', 'onTranscriptionResults'
   */
  addListener: (eventType: string) => void;
  removeListeners: (count: number) => void;
  destroyTranscription: (callback: (error: string) => void) => void;
}

// Use get() instead of getEnforcing() to allow graceful fallback
export default TurboModuleRegistry.get<Spec>('Voice');

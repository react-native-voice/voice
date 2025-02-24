import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  destroySpeech: (callback: (error: string) => void) => void;
  startSpeech: (locale: string, callback: (error: string) => void) => void;
  startTranscription: (
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
  isRecognizing: (callback: (Recognizing: boolean) => void) => void;
  addListener: (eventType: string) => void;
  removeListeners: (count: number) => void;
  destroyTranscription: (callback: (error: string) => void) => void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Voice');

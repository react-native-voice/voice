import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export type SpeechOptions = {
  EXTRA_LANGUAGE_MODEL?: string;
  /** 
   * Maximum number of results
   * Supports both legacy string format and new number format for backward compatibility
   * Legacy: string (e.g., "5") - will be converted to number
   * New: number (e.g., 5) - preferred format
   */
  EXTRA_MAX_RESULTS?: string | number;
  /** 
   * Enable partial results
   * Supports both legacy string format and new boolean format for backward compatibility
   * Legacy: string (e.g., "true") - will be converted to boolean
   * New: boolean (e.g., true) - preferred format
   */
  EXTRA_PARTIAL_RESULTS?: string | boolean;
  REQUEST_PERMISSIONS_AUTO?: boolean;
  RECOGNIZER_ENGINE?: string;
  EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS?: number;
  EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS?: number;
  EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS?: number;
};

export interface Spec extends TurboModule {
  destroySpeech: (callback: (error: string) => void) => void;
  startSpeech: (
    locale: string,
    opts: SpeechOptions,
    callback: (error: string) => void
  ) => void;
  stopSpeech: (callback: (error: string) => void) => void;
  cancelSpeech: (callback: (error: string) => void) => void;
  isSpeechAvailable: (
    callback: (isAvailable: boolean, error: string) => void
  ) => void;
  getSpeechRecognitionServices(): Promise<string[]>;
  isRecognizing: (callback: (isRecognizing: boolean) => void) => void;
  /**
   * Add an event listener for speech recognition events
   * Supported events: 'onSpeechStart', 'onSpeechRecognized', 'onSpeechEnd', 'onSpeechError', 'onSpeechResults', 'onSpeechPartialResults', 'onSpeechVolumeChanged'
   * Note: Android does not support transcription events
   */
  addListener: (eventType: string) => void;
  removeListeners: (count: number) => void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Voice');

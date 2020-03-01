import { EventSubscriptionVendor } from 'react-native';

type Callback = (error: string) => void;

export type VoiceModule = {
  getSpeechRecognitionServices: () => any[] | void;
  destroySpeech: (callback: Callback) => void;
  startSpeech: Function;
  stopSpeech: (callback: Callback) => void;
  cancelSpeech: (callback: Callback) => void;
  isRecognizing: Function;
  isSpeechAvailable: Function;
} & SpeechEvents &
  EventSubscriptionVendor;

export type SpeechEvents = {
  onSpeechStart?: (e: any) => void;
  onSpeechRecognized?: (e: SpeechRecognizedEvent) => void;
  onSpeechEnd?: (e: any) => void;
  onSpeechError?: (e: SpeechErrorEvent) => void;
  onSpeechResults?: (e: SpeechResultsEvent) => void;
  onSpeechPartialResults?: (e: SpeechResultsEvent) => void;
  onSpeechVolumeChanged?: (e: any) => void;
};

export type SpeechRecognizedEvent = {
  isFinal?: boolean;
};

export type SpeechResultsEvent = {
  value?: string[];
};

export type SpeechErrorEvent = {
  error?: {
    code?: 'string';
    message?: string;
  };
};

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
  onSpeechRecognized?: (e: any) => void;
  onSpeechEnd?: (e: any) => void;
  onSpeechError?: (e: any) => void;
  onSpeechResults?: (e: any) => void;
  onSpeechPartialResults?: (e: any) => void;
  onSpeechVolumeChanged?: (e: any) => void;
};

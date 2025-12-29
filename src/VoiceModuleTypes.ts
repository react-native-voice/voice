export type SpeechEvents = {
  onSpeechStart?: (e: SpeechStartEvent) => void;
  onSpeechRecognized?: (e: SpeechRecognizedEvent) => void;
  onSpeechEnd?: (e: SpeechEndEvent) => void;
  onSpeechError?: (e: SpeechErrorEvent) => void;
  onSpeechResults?: (e: SpeechResultsEvent) => void;
  onSpeechPartialResults?: (e: SpeechResultsEvent) => void;
  onSpeechVolumeChanged?: (e: SpeechVolumeChangeEvent) => void;
};

export type TranscriptionEvents = {
  onTranscriptionStart?: (e: TranscriptionStartEvent) => void;
  onTranscriptionEnd?: (e: TranscriptionEndEvent) => void;
  onTranscriptionError?: (e: TranscriptionErrorEvent) => void;
  onTranscriptionResults?: (e: TranscriptionResultsEvent) => void;
};

export type SpeechStartEvent = {
  error?: boolean;
};

export type TranscriptionStartEvent = {
  error?: boolean;
};

export type SpeechRecognizedEvent = {
  isFinal?: boolean;
};

export type SpeechResultsEvent = {
  value?: string[];
};

/**
 * Transcription segment with timing metadata (iOS only)
 * Used for file-based transcription with word-level timing information
 */
export type TranscriptionSegment = {
  transcription?: string;
  timestamp?: number;
  duration?: number;
};

/**
 * Transcription results event
 * Note: Transcription is iOS-only. Android does not support transcription.
 * 
 * Backward compatible: All fields are optional. The `segments` field is an addition
 * to the existing `transcription` field, not a replacement.
 */
export type TranscriptionResultsEvent = {
  /** Array of transcription segments with timing (iOS only, optional) */
  segments?: TranscriptionSegment[];
  /** Full transcription text (backward compatible, optional) */
  transcription?: string;
  /** Whether this is the final result (optional) */
  isFinal?: boolean;
};

export type SpeechErrorEvent = {
  error?: {
    code?: string;
    message?: string;
  };
};

export type TranscriptionErrorEvent = {
  error?: {
    code?: string;
    message?: string;
  };
};

export type SpeechEndEvent = {
  error?: boolean;
};

export type TranscriptionEndEvent = {
  error?: boolean;
};

export type SpeechVolumeChangeEvent = {
  value?: number;
};

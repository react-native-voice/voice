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
 * IMPORTANT: At runtime, `segments` is always `TranscriptionSegment[]` (objects).
 * The union type `string[] | TranscriptionSegment[]` is only for TypeScript backward
 * compatibility. The native iOS implementation never sends string arrays.
 */
export type TranscriptionResultsEvent = {
  /** 
   * Array of transcription segments (iOS only, optional)
   * 
   * Runtime type: Always TranscriptionSegment[] (objects with transcription, timestamp, duration)
   * TypeScript type: string[] | TranscriptionSegment[] (for backward compatibility)
   * 
   * Use `isTranscriptionSegmentArray()` type guard to safely check the format at runtime.
   * 
   * @example
   * ```typescript
   * Voice.onTranscriptionResults = (e) => {
   *   if (e.segments && isTranscriptionSegmentArray(e.segments)) {
   *     // TypeScript now knows e.segments is TranscriptionSegment[]
   *     e.segments.forEach(segment => {
   *       console.log(segment.transcription, segment.timestamp);
   *     });
   *   }
   * };
   * ```
   */
  segments?: string[] | TranscriptionSegment[];
  /** Full transcription text (unchanged, backward compatible, optional) */
  transcription?: string;
  /** Whether this is the final result (optional) */
  isFinal?: boolean;
};

/**
 * Type guard to check if segments is TranscriptionSegment[] format
 * 
 * At runtime, segments is always TranscriptionSegment[], but this guard helps
 * TypeScript narrow the type and provides runtime safety.
 * 
 * @param segments - The segments array to check
 * @returns true if segments is TranscriptionSegment[] format
 * 
 * @example
 * ```typescript
 * if (e.segments && isTranscriptionSegmentArray(e.segments)) {
 *   // TypeScript knows e.segments is TranscriptionSegment[]
 *   e.segments.forEach(segment => {
 *     console.log(segment.transcription, segment.timestamp);
 *   });
 * }
 * ```
 */
export function isTranscriptionSegmentArray(
  segments: string[] | TranscriptionSegment[] | undefined
): segments is TranscriptionSegment[] {
  if (!segments || segments.length === 0) {
    return false;
  }
  // Check if first element is an object (TranscriptionSegment) or string
  const first = segments[0];
  return typeof first === 'object' && first !== null && 'transcription' in first;
}

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

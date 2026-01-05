import {useEffect, useState, useCallback} from 'react';
import {
  StyleSheet,
  Text,
  View,
  Image,
  TouchableHighlight,
  ScrollView,
  Platform,
} from 'react-native';

import Voice, {
  type SpeechRecognizedEvent,
  type SpeechResultsEvent,
  type SpeechErrorEvent,
} from '@react-native-voice/voice';

// Set to true to enable debug logging
const DEBUG = __DEV__;

function VoiceTest() {
  const [recognized, setRecognized] = useState('');
  const [pitch, setPitch] = useState<number | undefined>(undefined);
  const [error, setError] = useState('');
  const [end, setEnd] = useState('');
  const [started, setStarted] = useState('');
  const [results, setResults] = useState<string[]>([]);
  const [partialResults, setPartialResults] = useState<string[]>([]);

  const log = useCallback((message: string) => {
    if (DEBUG) {
      console.log('[Voice]', message);
    }
  }, []);

  const onSpeechStart = useCallback(() => {
    log('Speech started');
    setStarted('√');
  }, [log]);

  const onSpeechRecognized = useCallback((_e: SpeechRecognizedEvent) => {
    setRecognized('√');
  }, []);

  const onSpeechEnd = useCallback(() => {
    log('Speech ended');
    setEnd('√');
  }, [log]);

  const onSpeechError = useCallback(
    (e: SpeechErrorEvent) => {
      log(`Error: ${JSON.stringify(e.error)}`);
      setError(JSON.stringify(e.error));
    },
    [log],
  );

  const onSpeechResults = useCallback(
    (e: SpeechResultsEvent) => {
      const newResults = e.value ?? [];
      log(`Results: ${newResults.join(', ')}`);
      setResults(newResults);
    },
    [log],
  );

  const onSpeechPartialResults = useCallback((e: SpeechResultsEvent) => {
    const newPartialResults = e.value ?? [];
    setPartialResults(newPartialResults);
  }, []);

  const onSpeechVolumeChanged = useCallback((e: {value?: number}) => {
    setPitch(e.value);
  }, []);

  useEffect(() => {
    Voice.onSpeechStart = onSpeechStart;
    Voice.onSpeechRecognized = onSpeechRecognized;
    Voice.onSpeechEnd = onSpeechEnd;
    Voice.onSpeechError = onSpeechError;
    Voice.onSpeechResults = onSpeechResults;
    Voice.onSpeechPartialResults = onSpeechPartialResults;
    Voice.onSpeechVolumeChanged = onSpeechVolumeChanged;

    return () => {
      Voice.destroy().then(Voice.removeAllListeners);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []); // Empty deps array - callbacks are stable via useCallback

  const _clearState = () => {
    setRecognized('');
    setPitch(undefined);
    setError('');
    setStarted('');
    setResults([]);
    setPartialResults([]);
    setEnd('');
  };

  const _startRecognizing = async () => {
    _clearState();
    try {
      log('Starting speech recognition...');
      await Voice.start('en-US');
      log('Speech recognition started');
    } catch (e) {
      const errorMsg = e instanceof Error ? e.message : String(e);
      log(`Error: ${errorMsg}`);
      setError(errorMsg);
    }
  };

  const _stopRecognizing = async () => {
    try {
      await Voice.stop();
      log('Speech recognition stopped');
    } catch (e) {
      if (DEBUG) console.error(e);
    }
  };

  const _cancelRecognizing = async () => {
    try {
      await Voice.cancel();
      log('Speech recognition cancelled');
    } catch (e) {
      if (DEBUG) console.error(e);
    }
  };

  const _destroyRecognizer = async () => {
    try {
      await Voice.destroy();
      log('Speech recognizer destroyed');
    } catch (e) {
      if (DEBUG) console.error(e);
    }
    _clearState();
  };

  return (
    <ScrollView contentContainerStyle={styles.scrollContainer}>
      <View style={styles.container}>
        <Text style={styles.welcome}>React Native Voice</Text>
        <Text style={styles.instructions}>
          Press the button and start speaking.
        </Text>

        {/* Status indicators */}
        <View style={styles.statusRow}>
          <Text style={styles.statusLabel}>Started:</Text>
          <Text style={[styles.statusValue, started && styles.statusActive]}>
            {started || '—'}
          </Text>
          <Text style={styles.statusLabel}>End:</Text>
          <Text style={[styles.statusValue, end && styles.statusActive]}>
            {end || '—'}
          </Text>
        </View>

        {/* Error display */}
        {error ? <Text style={styles.errorText}>Error: {error}</Text> : null}

        {/* Results */}
        <Text style={styles.sectionTitle}>Results</Text>
        <View style={styles.resultsContainer}>
          {results.length > 0 ? (
            results.map((result, index) => (
              <Text key={`result-${index}`} style={styles.resultText}>
                {result}
              </Text>
            ))
          ) : (
            <Text style={styles.placeholder}>Speak to see results...</Text>
          )}
        </View>

        {/* Partial Results */}
        <Text style={styles.sectionTitle}>Live Transcription</Text>
        <View style={styles.partialContainer}>
          {partialResults.length > 0 ? (
            <Text style={styles.partialText}>{partialResults[0]}</Text>
          ) : (
            <Text style={styles.placeholder}>...</Text>
          )}
        </View>

        {/* Volume indicator */}
        {pitch ? (
          <View style={styles.volumeContainer}>
            <View
              style={[
                styles.volumeBar,
                {width: `${Math.min(100, pitch * 10)}%`},
              ]}
            />
          </View>
        ) : null}

        {/* Controls */}
        <TouchableHighlight
          style={styles.buttonContainer}
          onPress={_startRecognizing}
          underlayColor="#ddd">
          <Image style={styles.button} source={require('./button.png')} />
        </TouchableHighlight>

        <View style={styles.actionsRow}>
          <TouchableHighlight onPress={_stopRecognizing} underlayColor="#eee">
            <Text style={styles.action}>Stop</Text>
          </TouchableHighlight>
          <TouchableHighlight onPress={_cancelRecognizing} underlayColor="#eee">
            <Text style={styles.action}>Cancel</Text>
          </TouchableHighlight>
          <TouchableHighlight onPress={_destroyRecognizer} underlayColor="#eee">
            <Text style={styles.action}>Reset</Text>
          </TouchableHighlight>
        </View>

        {Platform.OS === 'ios' && (
          <Text style={styles.hint}>
            Tip: On iOS, press Stop when done speaking
          </Text>
        )}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scrollContainer: {
    flexGrow: 1,
  },
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
    paddingVertical: 30,
    paddingHorizontal: 20,
  },
  welcome: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 10,
    color: '#333',
  },
  instructions: {
    textAlign: 'center',
    color: '#666',
    marginBottom: 20,
  },
  statusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 15,
  },
  statusLabel: {
    fontSize: 14,
    color: '#888',
    marginRight: 5,
  },
  statusValue: {
    fontSize: 14,
    color: '#ccc',
    marginRight: 15,
  },
  statusActive: {
    color: '#4CAF50',
    fontWeight: 'bold',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginTop: 15,
    marginBottom: 8,
  },
  resultsContainer: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 15,
    width: '100%',
    minHeight: 60,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 1},
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2,
  },
  resultText: {
    fontSize: 18,
    color: '#2196F3',
    textAlign: 'center',
  },
  partialContainer: {
    backgroundColor: '#E3F2FD',
    borderRadius: 10,
    padding: 15,
    width: '100%',
    minHeight: 50,
  },
  partialText: {
    fontSize: 16,
    color: '#1976D2',
    textAlign: 'center',
    fontStyle: 'italic',
  },
  placeholder: {
    fontSize: 14,
    color: '#aaa',
    textAlign: 'center',
  },
  volumeContainer: {
    width: '80%',
    height: 6,
    backgroundColor: '#E0E0E0',
    borderRadius: 3,
    marginTop: 15,
    overflow: 'hidden',
  },
  volumeBar: {
    height: '100%',
    backgroundColor: '#4CAF50',
    borderRadius: 3,
  },
  buttonContainer: {
    marginTop: 25,
    marginBottom: 15,
    borderRadius: 30,
  },
  button: {
    width: 60,
    height: 60,
  },
  actionsRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 20,
  },
  action: {
    fontSize: 16,
    color: '#2196F3',
    paddingVertical: 10,
    paddingHorizontal: 15,
  },
  errorText: {
    color: '#F44336',
    fontSize: 14,
    textAlign: 'center',
    marginBottom: 10,
  },
  hint: {
    marginTop: 20,
    fontSize: 12,
    color: '#888',
    fontStyle: 'italic',
  },
});

export default VoiceTest;

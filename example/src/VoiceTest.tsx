import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableHighlight,
} from 'react-native';

import Voice, {
  SpeechRecognizedEvent,
  SpeechResultsEvent,
  SpeechErrorEvent,
} from '@react-native-voice/voice';

type State = {
  recognized: string;
  pitch: string;
  error: string;
  end: string;
  started: string;
  results: string[];
  partialResults: string[];
  listening: boolean;
};

const initialState = {
  recognized: '',
  pitch: '',
  error: '',
  end: '',
  started: '',
  results: [],
  partialResults: [],
  listening: false,
};

export default function VoiceTest(): JSX.Element {
  const [state, setState] = useState<State>(initialState);

  useEffect(() => {
    return () => {
        Voice.destroy().then(Voice.removeAllListeners);
    };
  }, []);

  Voice.onSpeechStart = (e: any) => {
    console.log('onSpeechStart: ', e);
    setState((prev: State) => ({ ...prev, started: '√'}));
  };

  Voice.onSpeechRecognized = (e: SpeechRecognizedEvent) => {
    console.log('onSpeechRecognized: ', e);
    setState((prev: State) => ({ ...prev, recognized: '√' }));
  };

  Voice.onSpeechEnd = (e: any) => {
    console.log('onSpeechEnd: ', e);
    setState((prev: State) => ({ ...prev, end: '√' }));
  };

  Voice.onSpeechError = (e: SpeechErrorEvent) => {
    console.log('onSpeechError: ', e);
    setState((prev: State) => ({ ...prev, error: JSON.stringify(e.error) }));
  };

  Voice.onSpeechResults = (e: SpeechResultsEvent) => {
    console.log('onSpeechResults: ', e);
    setState((prev: State) => ({ ...prev, results: e.value as string[] }));
  };

  Voice.onSpeechPartialResults = (e: SpeechResultsEvent) => {
    console.log('onSpeechPartialResults: ', e);
    setState((prev: State) => ({ ...prev, partialResults: e.value as string[] }));
  };

  Voice.onSpeechVolumeChanged = (e: any) => {
    console.log('onSpeechVolumeChanged: ', e);
    setState((prev: State) => ({ ...prev, pitch: e.value }));
  };

  const _startRecognizing = async () => {
    setState({ ...initialState, listening: true });
    await Voice.start('en-US').catch(console.error);
  };

  const _stopRecognizing = async () => {
    await Voice.stop().catch(console.error);
  };

  const _cancelRecognizing = async () => {
    await Voice.cancel().catch(console.error);
  };

  const _destroyRecognizer = async () => {
    await Voice.destroy().catch(console.error);
    setState(initialState);
  };

  return (
    <View style={styles.container}>
      <Text style={styles.welcome}>Welcome to React Native Voice!</Text>
      <Text style={styles.instructions}>
        Press the button and start speaking.
      </Text>
      <Text style={styles.stat}>{`Started: ${state.started}`}</Text>
      <Text style={styles.stat}>{`Recognized: ${
        state.recognized
      }`}</Text>
      <Text style={styles.stat}>{`Pitch: ${state.pitch}`}</Text>
      <Text style={styles.stat}>{`Error: ${state.error}`}</Text>
      <Text style={styles.stat}>Results</Text>
      {state.results.map((result, index) => {
        return (
          <Text key={`result-${index}`} style={styles.stat}>
            {result}
          </Text>
        );
      })}
      <Text style={styles.stat}>Partial Results</Text>
      {state.partialResults.map((result, index) => {
        return (
          <Text key={`partial-result-${index}`} style={styles.stat}>
            {result}
          </Text>
        );
      })}
      <Text style={styles.stat}>{`End: ${state.end}`}</Text>
      {!state.listening && (<TouchableHighlight onPress={_startRecognizing}>
        <Text style={styles.action}>Start Recognizing</Text>
      </TouchableHighlight>) ||
      (<TouchableHighlight onPress={_stopRecognizing}>
        <Text style={styles.action}>Stop Recognizing</Text>
      </TouchableHighlight>)}
      <TouchableHighlight onPress={_cancelRecognizing}>
        <Text style={styles.action}>Cancel</Text>
      </TouchableHighlight>
      <TouchableHighlight onPress={_destroyRecognizer}>
        <Text style={styles.action}>Destroy</Text>
      </TouchableHighlight>
    </View>
  );
}

const styles = StyleSheet.create({
  button: {
    width: 50,
    height: 50,
  },
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  action: {
    textAlign: 'center',
    color: '#0000FF',
    marginVertical: 5,
    fontWeight: 'bold',
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
  stat: {
    textAlign: 'center',
    color: '#B0171F',
    marginBottom: 1,
  },
});

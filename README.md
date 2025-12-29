# React Native Voice

[![npm](https://img.shields.io/npm/v/@react-native-voice/voice.svg?style=flat-square)](https://npmjs.com/package/@react-native-voice/voice)

🎤 React Native Voice Recognition library for iOS and Android (Online and Offline Support)

## Features

- ✅ **New Architecture Support** - Works with Fabric and TurboModules
- ✅ **Bridgeless Mode** - Full support for React Native's Bridgeless mode
- ✅ **React Native 0.76+** - Tested and working with the latest RN versions
- ✅ **Cross-platform** - Works on both iOS and Android
- ✅ **Online and Offline** - Supports both online and offline speech recognition

## Installation

```sh
yarn add @react-native-voice/voice

# or

npm install @react-native-voice/voice --save
```

### iOS Setup

```sh
cd ios && pod install
```

### Android Setup

No additional setup required - autolinking handles everything.

## Usage

```javascript
import Voice from '@react-native-voice/voice';

// Set up event handlers
Voice.onSpeechStart = () => console.log('Speech started');
Voice.onSpeechEnd = () => console.log('Speech ended');
Voice.onSpeechResults = (e) => console.log('Results:', e.value);
Voice.onSpeechPartialResults = (e) => console.log('Partial:', e.value);
Voice.onSpeechError = (e) => console.log('Error:', e.error);

// Start listening
await Voice.start('en-US');

// Stop listening
await Voice.stop();

// Clean up
await Voice.destroy();
```

### Full Example

```javascript
import React, { useEffect, useState, useCallback } from 'react';
import { View, Text, Button } from 'react-native';
import Voice from '@react-native-voice/voice';

function SpeechToText() {
  const [results, setResults] = useState([]);
  const [isListening, setIsListening] = useState(false);

  useEffect(() => {
    Voice.onSpeechStart = () => setIsListening(true);
    Voice.onSpeechEnd = () => setIsListening(false);
    Voice.onSpeechResults = (e) => setResults(e.value ?? []);
    Voice.onSpeechError = (e) => console.error(e.error);

    return () => {
      Voice.destroy().then(Voice.removeAllListeners);
    };
  }, []);

  const startListening = async () => {
    try {
      await Voice.start('en-US');
    } catch (e) {
      console.error(e);
    }
  };

  const stopListening = async () => {
    try {
      await Voice.stop();
    } catch (e) {
      console.error(e);
    }
  };

  return (
    <View>
      <Text>{isListening ? '🎤 Listening...' : 'Press Start'}</Text>
      <Text>{results.join(' ')}</Text>
      <Button title="Start" onPress={startListening} />
      <Button title="Stop" onPress={stopListening} />
    </View>
  );
}
```

## API

| Method | Description | Platform |
|--------|-------------|----------|
| `Voice.isAvailable()` | Check if speech recognition is available | Android, iOS |
| `Voice.start(locale)` | Start listening for speech | Android, iOS |
| `Voice.stop()` | Stop listening | Android, iOS |
| `Voice.cancel()` | Cancel speech recognition | Android, iOS |
| `Voice.destroy()` | Destroy the recognizer instance | Android, iOS |
| `Voice.removeAllListeners()` | Remove all event listeners | Android, iOS |
| `Voice.isRecognizing()` | Check if currently recognizing | Android, iOS |
| `Voice.getSpeechRecognitionServices()` | Get available speech engines | Android only |

## Events

| Event | Description | Data |
|-------|-------------|------|
| `onSpeechStart` | Speech recognition started | `{ error: false }` |
| `onSpeechEnd` | Speech recognition ended | `{ error: false }` |
| `onSpeechResults` | Final results received | `{ value: ['recognized text'] }` |
| `onSpeechPartialResults` | Partial results (live) | `{ value: ['partial text'] }` |
| `onSpeechError` | Error occurred | `{ error: { code, message } }` |
| `onSpeechVolumeChanged` | Volume/pitch changed | `{ value: number }` |
| `onSpeechRecognized` | Speech was recognized | `{ isFinal: boolean }` |

## Permissions

### Android

Add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

The library automatically requests permission when starting recognition.

### iOS

Add to `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for speech recognition</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition access</string>
```

## Platform Notes

### Android
- Auto-stops after user stops speaking
- Requires Google Search app for speech recognition on most devices
- Check available services with `Voice.getSpeechRecognitionServices()`

### iOS
- Does NOT auto-stop - call `Voice.stop()` when done
- Speech recognition only works on **physical devices** (not simulators)
- Requires iOS 10+

## Expo Support

This library requires custom native code and cannot be used with Expo Go. Use a [development build](https://docs.expo.dev/develop/development-builds/introduction/) or eject.

Add to your `app.json`:

```json
{
  "expo": {
    "plugins": ["@react-native-voice/voice"]
  }
}
```

## Troubleshooting

### Android: No speech recognition services found
Install the [Google Search app](https://play.google.com/store/apps/details?id=com.google.android.googlequicksearchbox) from Play Store.

### iOS: Speech recognition not working on simulator
Use a physical iOS device - simulators don't support speech recognition.

### Events not firing
Make sure you set up event handlers **before** calling `Voice.start()`.

## Contributors

* @asafron
* @BrendanFDMoore
* @brudny
* @chitezh
* @ifsnow
* @jamsch
* @misino
* @Noitidart
* @ohtangza & @hayanmind
* @rudiedev6
* @tdonia
* @wenkesj

## License

MIT

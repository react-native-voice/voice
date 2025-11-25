# React Native Voice

[![npm](https://img.shields.io/npm/v/@dev-amirzubair/react-native-voice.svg?style=flat-square)](https://npmjs.com/package/@dev-amirzubair/react-native-voice)

A speech-to-text library for [React Native](https://reactnative.dev/) with **New Architecture (Fabric/TurboModules)** and **Bridgeless mode** support.

> **Note:** This library is a fork of [@react-native-voice/voice](https://github.com/react-native-voice/voice) with custom fixes for React Native 0.76+ and the New Architecture. [View source on GitHub](https://github.com/dev-amirzubair/voice)

## What's Different?

This fork includes the following improvements over the original library:

- ✅ **New Architecture Support** - Works with Fabric and TurboModules
- ✅ **Bridgeless Mode** - Full support for React Native's Bridgeless mode
- ✅ **React Native 0.76+** - Tested and working with the latest RN versions
- ✅ **Fixed Android Event Emission** - Events properly reach JavaScript in new architecture
- ✅ **Fixed iOS TurboModule Registration** - Proper fallback handling for iOS
- ✅ **Improved Locale Handling** - Better support for Indo-Pak region languages
- ✅ **Clean TypeScript Types** - Updated type definitions

## Installation

```sh
yarn add @dev-amirzubair/react-native-voice

# or

npm install @dev-amirzubair/react-native-voice --save
```

### iOS Setup

```sh
cd ios && pod install
```

### Android Setup

No additional setup required - autolinking handles everything.

## Usage

```javascript
import Voice from '@dev-amirzubair/react-native-voice';

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
import Voice from '@dev-amirzubair/react-native-voice';

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
    "plugins": ["@dev-amirzubair/react-native-voice"]
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

## Credits

This library is based on [@react-native-voice/voice](https://github.com/react-native-voice/voice) by the React Native Voice contributors. Special thanks to:

- @wenkesj (original author)
- @jamsch
- All original contributors

## License

MIT

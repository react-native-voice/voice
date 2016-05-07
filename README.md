# React Native Voice
A speech-to-text library for [React Native](https://facebook.github.io/react-native/).

**NOTE**, currently only supports Android. Contribute to make this a universal module!

# Install

```sh
npm i react-native-voice --save
```

## Android
- In `android/setting.gradle`

```gradle
...
include ':VoiceModule', ':app'
project(':VoiceModule').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-voice/android')
```

- In `android/app/build.gradle`

```gradle
...
dependencies {
    ...
    compile project(':VoiceModule')
}
```

- In `MainActivity.java`

```java

import com.facebook.react.ReactPackage;
...
import com.wenkesj.voice.VoicePackage; // <------ Add this!
...

public class MainActivity extends ReactActivity {
...
    @Override
    protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
        new MainReactPackage(),
        new VoicePackage() // <------ Add this!
        );
    }
}
```

# Example
Full example located in `/VoiceTest`.

# Usage

```javascript
import Voice from 'react-native-voice';
```

## Methods
Accessible methods to perform actions.

Method Name           | Description                                                                         | Platform
--------------------- | ----------------------------------------------------------------------------------- | --------
isAvailable(callback) | Checks whether a speech recognition service is available on the system.             | Android
start(locale)         | Starts listening for speech for a specific locale. Returns null if no error occurs. | Android
stop()                | Stops listening for speech. Returns null if no error occurs.                        | Android
cancel()              | Cancels the speech recognition. Returns null if no error occurs.                    | Android
destroy()             | Destroys the current SpeechRecognizer instance. Returns null if no error occurs.    | Android
isRecognizing()       | Return if the SpeechRecognizer is recognizing.                                      | Android

## Events
Methods that are invoked when a native event emitted.

Event Name                    | Description                                            | Event                                           | Platform
----------------------------- | ------------------------------------------------------ | ----------------------------------------------- | --------
onSpeechStart(event)          | Invoked when `.start()` is called without error.       | `{ error: false }`                              | Android
onSpeechRecognized(event)     | Invoked when speech is recognized.                     | `{ error: false }`                              | Android
onSpeechEnd(event)            | Invoked when SpeechRecognizer stops recognition.       | `{ error: false }`                              | Android
onSpeechError(event)          | Invoked when an error occurs.                          | `{ error: Description of error as string }`     | Android
onSpeechResults(event)        | Invoked when SpeechRecognizer is finished recognizing. | `{ value: [..., 'Speech recognized'] }`         | Android
onSpeechPartialResults(event) | Invoked when any results are computed.                 | `{ value: [..., 'Partial speech recognized'] }` | Android
onSpeechVolumeChanged(event)  | Invoked when pitch that is recognized changed.         | `{ value: pitch in dB }`                        | Android

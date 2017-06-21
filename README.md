# React Native Voice
A speech-to-text library for [React Native](https://facebook.github.io/react-native/).

## (Basically) Help Wanted
If you want to contribute, feel like this isn't going anywhere for your needs, or you just have to fork it to fix some small issue but are to lazy to "submit" a PR, let me know! Or just open an issue and bring it to my attention!

# Install

```sh
npm i react-native-voice --save
react-native link react-native-voice
```

## Manually link Android
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

- In `MainApplication.java`

```java

import com.facebook.react.ReactApplication
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

## Manually link iOS 

- Drag the Voice.xcodeproj from the react-native-voice/ios folder to the Libraries group on Xcode in your poject. [Manual linking](https://facebook.github.io/react-native/docs/linking-libraries-ios.html)

- Click on your main project file (the one that represents the .xcodeproj) select Build Phases and drag the static library, lib.Voice.a, from the Libraries/Voice.xcodeproj/Products folder to Link Binary With Libraries


# Example
Full example for Android and iOS platforms located in `/VoiceTest`.

# Usage

```javascript
import Voice from 'react-native-voice';
import {
  ...
} from 'react-native';
...
class VoiceTest extends Component {
  constructor(props) {
    Voice.onSpeechStart = this.onSpeechStartHandler.bind(this);
    Voice.onSpeechEnd = this.onSpeechEndHandler.bind(this);
    Voice.onSpeechResults = this.onSpeechResultsHandler.bind(this);
  }
  onButtonPress(e){
    const error = Voice.start('en');
  }
  ...
```

## Methods
Accessible methods to perform actions.

Method Name           | Description                                                                         | Platform
--------------------- | ----------------------------------------------------------------------------------- | --------
isAvailable(callback) | Checks whether a speech recognition service is available on the system.             | Android, iOS
start(locale)         | Starts listening for speech for a specific locale. Returns null if no error occurs. | Android, iOS
stop()                | Stops listening for speech. Returns null if no error occurs.                        | Android, iOS
cancel()              | Cancels the speech recognition. Returns null if no error occurs.                    | Android, iOS
destroy()             | Destroys the current SpeechRecognizer instance. Returns null if no error occurs.    | Android, iOS
isRecognizing()       | Return if the SpeechRecognizer is recognizing.                                      | Android, iOS

## Events
Methods that are invoked when a native event emitted.

Event Name                    | Description                                            | Event                                           | Platform
----------------------------- | ------------------------------------------------------ | ----------------------------------------------- | --------
onSpeechStart(event)          | Invoked when `.start()` is called without error.       | `{ error: false }`                              | Android, iOS
onSpeechRecognized(event)     | Invoked when speech is recognized.                     | `{ error: false }`                              | Android, iOS
onSpeechEnd(event)            | Invoked when SpeechRecognizer stops recognition.       | `{ error: false }`                              | Android, iOS
onSpeechError(event)          | Invoked when an error occurs.                          | `{ error: Description of error as string }`     | Android, iOS
onSpeechResults(event)        | Invoked when SpeechRecognizer is finished recognizing. | `{ value: [..., 'Speech recognized'] }`         | Android, iOS
onSpeechPartialResults(event) | Invoked when any results are computed.                 | `{ value: [..., 'Partial speech recognized'] }` | Android, iOS
onSpeechVolumeChanged(event)  | Invoked when pitch that is recognized changed.         | `{ value: pitch in dB }`                        | Android

## Android Permissions
While the included `VoiceTest` app works without explicit permissions checks and requests, it may be necessary to add a permission request for `RECORD_AUDIO` for some configurations.

## iOS Permissions
Need to include permissions for `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` inside Info.plist for iOS. See the included `VoiceTest` for how to handle these cases.

```xml
<dict>
  ...
  <key>NSMicrophoneUsageDescription</key>
  <string>Description of why you require the use of the microphone</string>
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>Description of why you require the use of the speech recognition</string>
  ...
</dict>
```

Please see the documentation provided by ReactNative for this: [PermissionsAndroid](http://facebook.github.io/react-native/releases/0.38/docs/permissionsandroid.html)

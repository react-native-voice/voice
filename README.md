[![npm][npm]][npm-url]
[![deps][deps]][deps-url]

<h1 align="center">React Native Voice</h1>

<p align="center">A speech-to-text library for <a href="https://facebook.github.io/react-native/">React Native.</a></p>

```sh
npm i react-native-voice --save
```

## Table of contents
  * [Linking](#linking)
    * [Manually Link Android](#manually-link-android)
    * [Manually Link iOS](#manually-link-ios)
  * [Usage](#usage)
    * [Example](#example)
  * [API](#api)
  * [Events](#events)
  * [Permissions](#permissions)
    * [Android](#android)
    * [iOS](#ios)
  * [Contibutors](#contibutors)

<h2 align="center">Linking</h2>

<p align="center">Manually or automatically link the NativeModule</p>

```sh
react-native link react-native-voice
```

### Manually Link Android
- In `android/setting.gradle`

```gradle
...
include ':react-native-voice', ':app'
project(':react-native-voice').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-voice/android')
```

- In `android/app/build.gradle`

```gradle
...
dependencies {
    ...
    compile project(':react-native-voice')
}
```

- In `MainApplication.java`

```java

import android.app.Application;
import com.facebook.react.ReactApplication;
import com.facebook.react.ReactPackage;
...
import com.wenkesj.voice.VoicePackage; // <------ Add this!
...

public class MainActivity extends Activity implements ReactApplication {
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

### Manually Link iOS

- Drag the Voice.xcodeproj from the react-native-voice/ios folder to the Libraries group on Xcode in your poject. [Manual linking](https://facebook.github.io/react-native/docs/linking-libraries-ios.html)

- Click on your main project file (the one that represents the .xcodeproj) select Build Phases and drag the static library, lib.Voice.a, from the Libraries/Voice.xcodeproj/Products folder to Link Binary With Libraries


<h2 align="center">Usage</h2>

<p align="center"><a href="https://github.com/wenkesj/react-native-voice/tree/master/VoiceTest">Full example for Android and iOS.</a></p>

### Example

```javascript
import Voice from 'react-native-voice';
import React, {Component} from 'react';

class VoiceTest extends Component {
  constructor(props) {
    Voice.onSpeechStart = this.onSpeechStartHandler.bind(this);
    Voice.onSpeechEnd = this.onSpeechEndHandler.bind(this);
    Voice.onSpeechResults = this.onSpeechResultsHandler.bind(this);
  }
  onStartButtonPress(e){
    Voice.start('en-US');
  }
  ...
}
```


<h2 align="center">API</h2>

<p align="center">Static access to the Voice API.</p>

**All methods _now_ return a `new Promise` for `async/await` compatibility.**

Method Name                          | Description                                                                                                                                                             | Platform
------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------
Voice.isAvailable()                  | Checks whether a speech recognition service is available on the system.                                                                                                 | Android, iOS
Voice.start(locale)                  | Starts listening for speech for a specific locale. Returns null if no error occurs.                                                                                     | Android, iOS
Voice.stop()                         | Stops listening for speech. Returns null if no error occurs.                                                                                                            | Android, iOS
Voice.cancel()                       | Cancels the speech recognition. Returns null if no error occurs.                                                                                                        | Android, iOS
Voice.destroy()                      | Destroys the current SpeechRecognizer instance. Returns null if no error occurs.                                                                                        | Android, iOS
Voice.removeAllListeners()           | Cleans/nullifies overridden `Voice` static methods.                                                                                                                     | Android, iOS
Voice.isRecognizing()                | Return if the SpeechRecognizer is recognizing.                                                                                                                          | Android, iOS
Voice.getSpeechRecognitionServices() | Returns a list of the speech recognition engines available on the device. (Example: `['com.google.android.googlequicksearchbox']` if Google is the only one available.) | Android
<h2 align="center">Events</h2>

<p align="center">Callbacks that are invoked when a native event emitted.</p>

Event Name                          | Description                                            | Event                                           | Platform
----------------------------------- | ------------------------------------------------------ | ----------------------------------------------- | --------
Voice.onSpeechStart(event)          | Invoked when `.start()` is called without error.       | `{ error: false }`                              | Android, iOS
Voice.onSpeechRecognized(event)     | Invoked when speech is recognized.                     | `{ error: false }`                              | Android, iOS
Voice.onSpeechEnd(event)            | Invoked when SpeechRecognizer stops recognition.       | `{ error: false }`                              | Android, iOS
Voice.onSpeechError(event)          | Invoked when an error occurs.                          | `{ error: Description of error as string }`     | Android, iOS
Voice.onSpeechResults(event)        | Invoked when SpeechRecognizer is finished recognizing. | `{ value: [..., 'Speech recognized'] }`         | Android, iOS
Voice.onSpeechPartialResults(event) | Invoked when any results are computed.                 | `{ value: [..., 'Partial speech recognized'] }` | Android, iOS
Voice.onSpeechVolumeChanged(event)  | Invoked when pitch that is recognized changed.         | `{ value: pitch in dB }`                        | Android

<h2 align="center">Permissions</h2>

<p align="center">Arguably the most important part.</p>

### Android
While the included `VoiceTest` app works without explicit permissions checks and requests, it may be necessary to add a permission request for `RECORD_AUDIO` for some configurations.
Since Android M (6.0), [user need to grant permission at runtime (and not during app installation)](https://developer.android.com/training/permissions/requesting.html).
By default, calling the `startSpeech` method will invoke `RECORD AUDIO` permission popup to the user. This can be disabled by passing `REQUEST_PERMISSIONS_AUTO: true` in the options argument.

If you're running an ejected expo/expokit app, you may run into issues with permissions on Android and get the following error `host.exp.exponent.MainActivity cannot be cast to com.facebook.react.ReactActivity
startSpeech`. This can be resolved by prompting for permssion using the `expo-permission` package before starting recogntion. 
```js
import { Permissions } from "expo";
async componentDidMount() {
	const { status, expires, permissions } = await Permissions.askAsync(
		Permissions.AUDIO_RECORDING
	);
	if (status !== "granted") {
		//Permissions not granted. Don't show the start recording button because it will cause problems if it's pressed.
		this.setState({showRecordButton: false});
	} else {
		this.setState({showRecordButton: true});
	}
}
```

### iOS
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

Please see the documentation provided by ReactNative for this: [PermissionsAndroid](http://facebook.github.io/react-native/docs/permissionsandroid.html)

[npm]: https://img.shields.io/npm/v/react-native-voice.svg
[npm-url]: https://npmjs.com/package/react-native-voice

[deps]: https://david-dm.org/wenkesj/react-native-voice.svg
[deps-url]: https://david-dm.org/wenkesj/react-native-voice.svg

<h2 align="center">Contibutors</h2>

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

![CircleCI branch][circle-ci-badge]
[![npm][npm]][npm-url]

<h1 align="center">React Native Voice</h1>
<p align="center">A speech-to-text library for <a href="https://reactnative.dev/">React Native.</a></p>

<a href="https://discord.gg/CJHKVeW6sp">
<img src="https://img.shields.io/discord/764994995098615828?label=Discord&logo=Discord&style=for-the-badge"
            alt="chat on Discord"></a>

```sh
yarn add @react-native-voice/voice

# or

npm i @react-native-voice/voice --save
```

Link the iOS package

```sh
npx pod-install
```

## Table of contents

- [Linking](#linking)
  - [Manually Link Android](#manually-link-android)
  - [Manually Link iOS](#manually-link-ios)
- [Prebuild Plugin](#prebuild-plugin)
- [Usage](#usage)
  - [Example](#example)
- [API](#api)
- [Events](#events)
- [Permissions](#permissions)
  - [Android](#android)
  - [iOS](#ios)
- [Contributors](#contributors)

<h2 align="center">Linking</h2>

<p align="center">Manually or automatically link the NativeModule</p>

```sh
react-native link @react-native-voice/voice
```

### Manually Link Android

- In `android/setting.gradle`

```gradle
...
include ':@react-native-voice_voice', ':app'
project(':@react-native-voice_voice').projectDir = new File(rootProject.projectDir, '../node_modules/@react-native-voice/voice/android')
```

- In `android/app/build.gradle`

```gradle
...
dependencies {
    ...
    compile project(':@react-native-voice_voice')
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

- Drag the Voice.xcodeproj from the @react-native-voice/voice/ios folder to the Libraries group on Xcode in your poject. [Manual linking](https://reactnative.dev/docs/linking-libraries-ios.html)

- Click on your main project file (the one that represents the .xcodeproj) select Build Phases and drag the static library, lib.Voice.a, from the Libraries/Voice.xcodeproj/Products folder to Link Binary With Libraries

<h2 align="center">Prebuild Plugin</h2>

> This package cannot be used in the "Expo Go" app because [it requires custom native code](https://docs.expo.io/workflow/customizing/).

After installing this npm package, add the [config plugin](https://docs.expo.io/guides/config-plugins/) to the [`plugins`](https://docs.expo.io/versions/latest/config/app/#plugins) array of your `app.json` or `app.config.js`:

```json
{
  "expo": {
    "plugins": ["@react-native-voice/voice"]
  }
}
```

Next, rebuild your app as described in the ["Adding custom native code"](https://docs.expo.io/workflow/customizing/) guide.

### Props

The plugin provides props for extra customization. Every time you change the props or plugins, you'll need to rebuild (and `prebuild`) the native app. If no extra properties are added, defaults will be used.

- `speechRecognition` (_string | false_): Sets the message for the `NSSpeechRecognitionUsageDescription` key in the `Info.plist` message. When undefined, a default permission message will be used. When `false`, the permission will be skipped.
- `microphone` (_string | false_): Sets the message for the `NSMicrophoneUsageDescription` key in the `Info.plist`. When undefined, a default permission message will be used. When `false`, the `android.permission.RECORD_AUDIO` will not be added to the `AndroidManifest.xml` and the iOS permission will be skipped.

### Example

```json
{
  "plugins": [
    [
      "@react-native-voice/voice",
      {
        "microphonePermission": "CUSTOM: Allow $(PRODUCT_NAME) to access the microphone",
        "speechRecognitionPermission": "CUSTOM: Allow $(PRODUCT_NAME) to securely recognize user speech"
      }
    ]
  ]
}
```

<h2 align="center">Usage</h2>

<p align="center"><a href="https://github.com/react-native-voice/voice/blob/master/example/src/VoiceTest.tsx">Full example for Android and iOS.</a></p>

### Example

```javascript
import Voice from '@react-native-voice/voice';
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

| Method Name                          | Description                                                                                                                                                             | Platform     |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| Voice.isAvailable()                  | Checks whether a speech recognition service is available on the system.                                                                                                 | Android, iOS |
| Voice.start(locale)                  | Starts listening for speech for a specific locale. Returns null if no error occurs.                                                                                     | Android, iOS |
| Voice.stop()                         | Stops listening for speech. Returns null if no error occurs.                                                                                                            | Android, iOS |
| Voice.cancel()                       | Cancels the speech recognition. Returns null if no error occurs.                                                                                                        | Android, iOS |
| Voice.destroy()                      | Destroys the current SpeechRecognizer instance. Returns null if no error occurs.                                                                                        | Android, iOS |
| Voice.removeAllListeners()           | Cleans/nullifies overridden `Voice` static methods.                                                                                                                     | Android, iOS |
| Voice.isRecognizing()                | Return if the SpeechRecognizer is recognizing.                                                                                                                          | Android, iOS |
| Voice.getSpeechRecognitionServices() | Returns a list of the speech recognition engines available on the device. (Example: `['com.google.android.googlequicksearchbox']` if Google is the only one available.) | Android      |

<h2 align="center">Events</h2>

<p align="center">Callbacks that are invoked when a native event emitted.</p>

| Event Name                          | Description                                            | Event                                           | Platform     |
| ----------------------------------- | ------------------------------------------------------ | ----------------------------------------------- | ------------ |
| Voice.onSpeechStart(event)          | Invoked when `.start()` is called without error.       | `{ error: false }`                              | Android, iOS |
| Voice.onSpeechRecognized(event)     | Invoked when speech is recognized.                     | `{ error: false }`                              | Android, iOS |
| Voice.onSpeechEnd(event)            | Invoked when SpeechRecognizer stops recognition.       | `{ error: false }`                              | Android, iOS |
| Voice.onSpeechError(event)          | Invoked when an error occurs.                          | `{ error: Description of error as string }`     | Android, iOS |
| Voice.onSpeechResults(event)        | Invoked when SpeechRecognizer is finished recognizing. | `{ value: [..., 'Speech recognized'] }`         | Android, iOS |
| Voice.onSpeechPartialResults(event) | Invoked when any results are computed.                 | `{ value: [..., 'Partial speech recognized'] }` | Android, iOS |
| Voice.onSpeechVolumeChanged(event)  | Invoked when pitch that is recognized changed.         | `{ value: pitch in dB }`                        | Android, iOS |

<h2 align="center">Permissions</h2>

<p align="center">Arguably the most important part.</p>

### Android

While the included `VoiceTest` app works without explicit permissions checks and requests, it may be necessary to add a permission request for `RECORD_AUDIO` for some configurations.
Since Android M (6.0), [user need to grant permission at runtime (and not during app installation)](https://developer.android.com/training/permissions/requesting.html).
By default, calling the `startSpeech` method will invoke `RECORD AUDIO` permission popup to the user. This can be disabled by passing `REQUEST_PERMISSIONS_AUTO: true` in the options argument.

If you're running an ejected expo/expokit app, you may run into issues with permissions on Android and get the following error `host.exp.exponent.MainActivity cannot be cast to com.facebook.react.ReactActivity startSpeech`. This can be resolved by prompting for permssion using the `expo-permission` package before starting recognition.

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

**Notes on Android**

Even after all the permissions are correct in Android, there is one last thing to make sure this libray is working fine on Android. Please make sure the device has Google Speech Recognizing Engine such as `com.google.android.googlequicksearchbox` by calling `Voice.getSpeechRecognitionServices()`. Since Android phones can be configured with so many options, even if a device has googlequicksearchbox engine, it could be configured to use other services. You can check which serivce is used for Voice Assistive App in following steps for most Android phones:

`Settings > App Management > Default App > Assistive App and Voice Input > Assistive App`

Above flow can vary depending on the Android models and manufactures. For Huawei phones, there might be a chance that the device cannot install Google Services.

**How can I get `com.google.android.googlequicksearchbox` in the device?**

Please ask users to install [Google Search App](https://play.google.com/store/apps/details?id=com.google.android.googlequicksearchbox&hl=en).

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

Please see the documentation provided by ReactNative for this: [PermissionsAndroid](https://reactnative.dev/docs/permissionsandroid.html)

[npm]: https://img.shields.io/npm/v/@react-native-voice/voice.svg?style=flat-square
[npm-url]: https://npmjs.com/package/@react-native-voice/voice
[circle-ci-badge]: https://img.shields.io/circleci/project/github/react-native-voice/voice/master.svg?style=flat-square

<h2 align="center">Contributors</h2>

- @asafron
- @BrendanFDMoore
- @brudny
- @chitezh
- @ifsnow
- @jamsch
- @misino
- @Noitidart
- @ohtangza & @hayanmind
- @rudiedev6
- @tdonia
- @wenkesj

import {
  AndroidConfig,
  ConfigPlugin,
  createRunOncePlugin,
} from '@expo/config-plugins';

const pkg = require('@react-native-voice/voice/package.json');

const MICROPHONE = 'Allow $(PRODUCT_NAME) to access the microphone';

const SPEECH_RECOGNITION =
  'Allow $(PRODUCT_NAME) to securely recognize user speech';

export type Props = {
  /**
   * `NSSpeechRecognitionUsageDescription` message.
   */
  speechRecognition?: string | false;

  /**
   * `NSMicrophoneUsageDescription` message.
   */
  microphone?: string | false;
};

/**
 * Adds `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` to the `Info.plist`.
 *
 * @param props.speechRecognition speech recognition message
 * @param props.microphone microphone permission message
 * @returns
 */
export const withPermissionsIOS: ConfigPlugin<Props> = (
  config,
  { microphone, speechRecognition } = {},
) => {
  if (!config.ios) {
    config.ios = {};
  }
  if (!config.ios.infoPlist) {
    config.ios.infoPlist = {};
  }

  if (microphone !== false) {
    config.ios.infoPlist.NSMicrophoneUsageDescription =
      microphone ||
      config.ios.infoPlist.NSMicrophoneUsageDescription ||
      MICROPHONE;
  }
  if (speechRecognition !== false) {
    config.ios.infoPlist.NSSpeechRecognitionUsageDescription =
      speechRecognition ||
      config.ios.infoPlist.NSSpeechRecognitionUsageDescription ||
      SPEECH_RECOGNITION;
  }

  return config;
};

/**
 * Adds the following to the `AndroidManifest.xml`: `<uses-permission android:name="android.permission.RECORD_AUDIO" />`
 */
export const withPermissionsAndroid: ConfigPlugin = config => {
  return AndroidConfig.Permissions.withPermissions(config, [
    'android.permission.RECORD_AUDIO',
  ]);
};

const withVoice: ConfigPlugin<Props | void> = (config, props = {}) => {
  const _props = props ? props : {};
  config = withPermissionsIOS(config, _props);
  if (_props.microphone !== false) {
    config = withPermissionsAndroid(config);
  }
  return config;
};

export default createRunOncePlugin(withVoice, pkg.name, pkg.version);


#import "Voice.h"
#import <React/RCTLog.h>
#import <AVFoundation/AVFoundation.h>
#import <Speech/Speech.h>


@implementation Voice

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}
// This RCT (React) "macro" exposes the current module to JavaScript
RCT_EXPORT_MODULE();

//// We must explicitly expose methods otherwise JavaScript can't access anything
//RCT_EXPORT_METHOD(log:(NSString *)location log2:(NSString *)location2)
//{
////    NSString* someString = @"Something";
//
//    // float volume = [AVAudioSession sharedInstance].outputVolume;
//     RCTLogInfo(@"looooggggg----:%@, %@", location, location2);
//
//}
//
//// We must explicitly expose methods otherwise JavaScript can't access anything
//RCT_EXPORT_METHOD(get:(NSString *)location callback:(RCTResponseSenderBlock)callback)
//{
////  NSString* someString = @"Something";
//
//  // float volume = [AVAudioSession sharedInstance].outputVolume;
//  // RCTLogInfo(@"The system volume level is %f", volume);
//
//  callback(@[location]);
//}


//
//
//RCT_EXPORT_METHOD(startSpeech){
//
//
//  // Initialize the Speech Recognizer with the locale, couldn't find a list of locales
//  // but I assume it's standard UTF-8 https://wiki.archlinux.org/index.php/locale
//  speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
//
//  // Set speech recognizer delegate
//  speechRecognizer.delegate = self;
//
//  // Request the authorization to make sure the user is asked for permission so you can
//  // get an authorized response, also remember to change the .plist file, check the repo's
//  // readme file or this projects info.plist
//  [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
//    switch (status) {
//      case SFSpeechRecognizerAuthorizationStatusAuthorized:
//        NSLog(@"Authorized");
//        break;
//      case SFSpeechRecognizerAuthorizationStatusDenied:
//        NSLog(@"Denied");
//        break;
//      case SFSpeechRecognizerAuthorizationStatusNotDetermined:
//        NSLog(@"Not Determined");
//        break;
//      case SFSpeechRecognizerAuthorizationStatusRestricted:
//        NSLog(@"Restricted");
//        break;
//      default:
//        break;
//    }
//  }];
//
//  // Initialize the AVAudioEngine
//  audioEngine = [[AVAudioEngine alloc] init];
//
//  // Make sure there's not a recognition task already running
//  if (recognitionTask) {
//    [recognitionTask cancel];
//    recognitionTask = nil;
//  }
//
//  // Starts an AVAudio Session
//  NSError *error;
//  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//  [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
//  [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
//
//  // Starts a recognition process, in the block it logs the input or stops the audio
//  // process if there's an error.
//  recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
//  AVAudioInputNode *inputNode = audioEngine.inputNode;
//  recognitionRequest.shouldReportPartialResults = YES;
//  recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
//    BOOL isFinal = NO;
//    if (result) {
//      // Whatever you say in the mic after pressing the button should be being logged
//      // in the console.
//      NSLog(@"RESULT:%@",result.bestTranscription.formattedString);
//      isFinal = !result.isFinal;
//    }
//    if (error) {
//      [audioEngine stop];
//      [inputNode removeTapOnBus:0];
//      recognitionRequest = nil;
//      recognitionTask = nil;
//    }
//  }];
//
//  // Sets the recording format
//  AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
//  [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
//    [recognitionRequest appendAudioPCMBuffer:buffer];
//  }];
//
//  // Starts the audio engine, i.e. it starts listening.
//  [audioEngine prepare];
//  [audioEngine startAndReturnError:&error];
//  NSLog(@"Say Something, I'm listening");
//
////  callback(@[[NSNull null]);
//}
//



RCT_EXPORT_METHOD(viewDidLoad) {
  
  // Initialize the Speech Recognizer with the locale, couldn't find a list of locales
  // but I assume it's standard UTF-8 https://wiki.archlinux.org/index.php/locale
  speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
  
  // Set speech recognizer delegate
  speechRecognizer.delegate = self;
  
  // Request the authorization to make sure the user is asked for permission so you can
  // get an authorized response, also remember to change the .plist file, check the repo's
  // readme file or this projects info.plist
  [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
    switch (status) {
      case SFSpeechRecognizerAuthorizationStatusAuthorized:
        NSLog(@"Authorized");
        break;
      case SFSpeechRecognizerAuthorizationStatusDenied:
        NSLog(@"Denied");
        break;
      case SFSpeechRecognizerAuthorizationStatusNotDetermined:
        NSLog(@"Not Determined");
        break;
      case SFSpeechRecognizerAuthorizationStatusRestricted:
        NSLog(@"Restricted");
        break;
      default:
        break;
    }
  }];
  
}



/*!
 * @brief Starts listening and recognizing user input through the phone's microphone
 */

RCT_EXPORT_METHOD(startListening) {
  
  // Initialize the AVAudioEngine
  audioEngine = [[AVAudioEngine alloc] init];
  
  // Make sure there's not a recognition task already running
  if (recognitionTask) {
    [recognitionTask cancel];
    recognitionTask = nil;
  }
  
  // Starts an AVAudio Session
  NSError *error;
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
  [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
  
  // Starts a recognition process, in the block it logs the input or stops the audio
  // process if there's an error.
  recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
  AVAudioInputNode *inputNode = audioEngine.inputNode;
  recognitionRequest.shouldReportPartialResults = YES;
  recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
    BOOL isFinal = NO;
    if (result) {
      // Whatever you say in the mic after pressing the button should be being logged
      // in the console.
      NSLog(@"RESULT:%@",result.bestTranscription.formattedString);
      isFinal = !result.isFinal;
    }
    if (error) {
      [audioEngine stop];
      [inputNode removeTapOnBus:0];
      recognitionRequest = nil;
      recognitionTask = nil;
    }
  }];
  
  // Sets the recording format
  AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
  [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
    [recognitionRequest appendAudioPCMBuffer:buffer];
  }];
  
  // Starts the audio engine, i.e. it starts listening.
  [audioEngine prepare];
  [audioEngine startAndReturnError:&error];
  NSLog(@"Say Something, I'm listening");
  
  
}



//RCT_EXPORT_METHOD(microPhoneTapped){
//  if (audioEngine.isRunning) {
//    [audioEngine stop];
//    [recognitionRequest endAudio];
//  } else {
//    [self startListening];
//  }
//}



#pragma mark - SFSpeechRecognizerDelegate Delegate Methods

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
  NSLog(@"Availability:%d",available);
}




RCT_EXPORT_METHOD(startSpeech:(NSString *)location callback:(RCTResponseSenderBlock)callback) {
  if (!audioEngine.isRunning) {
    [self startListening];
  }
  callback(false);
}


RCT_EXPORT_METHOD(stopSpeech:(RCTResponseSenderBlock)callback) {
  if (audioEngine.isRunning) {
    [audioEngine stop];
    [recognitionRequest endAudio];
  }
  callback(false);
}

@end

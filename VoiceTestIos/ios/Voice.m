
#import "Voice.h"
#import <React/RCTLog.h>
//#import <AVFoundation/AVFoundation.h>
//#import <Speech/Speech.h>

#import <UIKit/UIKit.h>
#import <React/RCTUtils.h>
#import <React/RCTBridge.h>
#import <React/RCTEventEmitter.h>
// #import <React/RCTEventDispatcher.h>
#import <Speech/Speech.h>

@interface Voice () <SFSpeechRecognizerDelegate>

@property (nonatomic) SFSpeechRecognizer* speechRecognizer;
@property (nonatomic) SFSpeechAudioBufferRecognitionRequest* recognitionRequest;
@property (nonatomic) AVAudioEngine* audioEngine;
@property (nonatomic) SFSpeechRecognitionTask* recognitionTask;
@property (nonatomic) AVAudioSession* audioSession;


@property (nonatomic, weak, readwrite) RCTBridge *
bridge;

@end

@implementation Voice
{
}


- (void) setupAndStartRecognizing:(NSString*)localeStr {
    [self teardown];
    
    NSLocale* locale = nil;
    if ([localeStr length] > 0) {
        locale = [NSLocale localeWithLocaleIdentifier:localeStr];
    }
    
    if (locale) {
        self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    } else {
        self.speechRecognizer = [[SFSpeechRecognizer alloc] init];
    }
    
    self.speechRecognizer.delegate = self;
    
    
    NSError* audioSessionError = nil;
    self.audioSession = [AVAudioSession sharedInstance];
     NSLog(@"ZZZZZZZ");

[self.audioSession requestRecordPermission:^(BOOL granted) {
    if (granted) {
        NSLog(@"granted");
    } else {
        NSLog(@"denied");
    }
}];



    [self.audioSession setCategory:AVAudioSessionCategoryRecord error:&audioSessionError];


    if (audioSessionError != nil) {
        [self sendResult:RCTMakeError([audioSessionError localizedDescription], nil, nil) :nil :nil :nil];
        return;
    }
    [self.audioSession setMode:AVAudioSessionModeMeasurement error:&audioSessionError];
    if (audioSessionError != nil) {
        [self sendResult:RCTMakeError([audioSessionError localizedDescription], nil, nil) :nil :nil :nil];
        return;
    }
    [self.audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&audioSessionError];
    if (audioSessionError != nil) {
        [self sendResult:RCTMakeError([audioSessionError localizedDescription], nil, nil) :nil :nil :nil];
        return;
    }
    
    
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    
    if (self.recognitionRequest == nil){
        [self sendResult:RCTMakeError(@"Unable to created a SFSpeechAudioBufferRecognitionRequest object", nil, nil) :nil :nil :nil];
        return;
    }
    
    if (self.audioEngine == nil) {
        self.audioEngine = [[AVAudioEngine alloc] init];
    }
    
    AVAudioInputNode* inputNode = self.audioEngine.inputNode;
    if (inputNode == nil) {
        [self sendResult:RCTMakeError(@"Audio engine has no input node", nil, nil) :nil :nil :nil];
        return;
    }
    
    // Configure request so that results are returned before audio recording is finished
    self.recognitionRequest.shouldReportPartialResults = YES;
    
    [self sendEventWithName:@"onSpeechStart" body:@"true"];

    // A recognition task represents a speech recognition session.
    // We keep a reference to the task so that it can be cancelled.
    self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
   NSLog(@"RRRUUDDDDIIEE");
        if (error != nil) {
            [self sendResult:RCTMakeError([error localizedDescription], nil, nil) :nil :nil :nil];
            [self teardown];
            return;
        }
        
        BOOL isFinal = result.isFinal;
        if (result != nil) {
            NSMutableArray* transcriptionDics = [NSMutableArray new];
            for (SFTranscription* transcription in result.transcriptions) {
                [transcriptionDics addObject:[self dicFromTranscription:transcription]];
            }
            
            [self sendResult:[NSNull null] :[self dicFromTranscription:result.bestTranscription] :transcriptionDics :@(isFinal)];
        }
        
        if (isFinal == YES) {
            [self teardown];
        }
        
        NSLog(@"CALLBACK : Final: %i, status:%i", isFinal, self.recognitionTask.state);
        
    }];

  //   recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
  //   BOOL isFinal = NO;
  //   if (result) {
  //     // Whatever you say in the mic after pressing the button should be being logged
  //     // in the console.
  //     NSLog(@"RESULT:%@",result.bestTranscription.formattedString);
  //     isFinal = !result.isFinal;
  //   }
  //   if (error) {
  //     [audioEngine stop];
  //     [inputNode removeTapOnBus:0];
  //     recognitionRequest = nil;
  //     recognitionTask = nil;
  //   }
  // }];



    
    AVAudioFormat* recordingFormat = [inputNode outputFormatForBus:0];
    
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        if (self.recognitionRequest != nil) {
            [self.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&audioSessionError];
    if (audioSessionError != nil) {
        [self sendResult:RCTMakeError([audioSessionError localizedDescription], nil, nil) :nil :nil :nil];
        return;
    }
    [self sendEventWithName:@"onSpeechEnd" body:@"true"];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"SpeechToText", @"onSpeechResults", @"onSpeechStart", @"onSpeechPartialResults", @"onSpeechError", @"onSpeechEnd", @"onSpeechRecognized"];
}

- (void) sendResult:(NSDictionary*)error :(NSDictionary*)bestTranscription :(NSArray*)transcriptions :(NSNumber*)isFinal {
//    NSString *eventName = notification.userInfo[@"name"];
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    if (error != nil && error != [NSNull null]) {
        result[@"error"] = error;
        [self sendEventWithName:@"onSpeechError" body:result[@"error"]];
    }
    if (bestTranscription != nil) {
        result[@"bestTranscription"] = bestTranscription;
        [self sendEventWithName:@"onSpeechResults" body:result[@"bestTranscription"]];
    }
    if (transcriptions != nil) {
        result[@"transcriptions"] = transcriptions;
        [self sendEventWithName:@"onSpeechPartialResults" body:result[@"transcriptions"]];
    }
    if (isFinal != nil) {
        result[@"isFinal"] = isFinal;
       
        [self sendEventWithName:@"onSpeechRecognized" body:result[@"isFinal"]];
    }
    
    // [self.bridge.eventDispatcher sendAppEventWithName:@"SpeechToText"
    //                                              body:result];


// [self sendEventWithName:@"EventReminder" body:@{@"name": eventName}];
    [self sendEventWithName:@"SpeechToText" body:result];
    
   





}

- (void) teardown {
    [self.recognitionTask cancel];
    self.recognitionTask = nil;
    [self.audioSession setCategory:AVAudioSessionCategoryAmbient error:nil];
    self.audioSession = nil;

    
    
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
        [self.recognitionRequest endAudio];
        [self.audioEngine.inputNode removeTapOnBus:0];
    }
    
    self.recognitionRequest = nil;
}

- (NSDictionary*) dicFromTranscription:(SFTranscription*) transcription {
    NSMutableArray* secgmentsDics = [NSMutableArray new];
    for (SFTranscriptionSegment* segment in transcription.segments) {
        id dic = @{@"substring":segment.substring,
                   @"substringRange":@{@"location":@(segment.substringRange.location),
                                       @"length":@(segment.substringRange.length)},
                   @"timestamp":@(segment.timestamp),
                   @"duration":@(segment.duration),

                   @"confidence":@(segment.confidence),
                   @"alternativeSubstrings":segment.alternativeSubstrings,
                   };
        [secgmentsDics addObject:dic];
    }
    
    return @{@"formattedString":transcription.formattedString,
             @"segments":secgmentsDics};
}


// Called when the availability of the given recognizer changes
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    if (available == false) {
        [self sendResult:RCTMakeError(@"Speech recognition is not available now", nil, nil) :nil :nil :nil];
    }
}

RCT_EXPORT_METHOD(finishRecognition:(RCTResponseSenderBlock)callback)
{
    // lets finish it
    [self.recognitionTask finish];
    callback(false);
}


RCT_EXPORT_METHOD(stopSpeech:(RCTResponseSenderBlock)callback) {
    [self teardown];
    callback(false);
}

RCT_EXPORT_METHOD(startSpeech:(NSString*)localeStr callback:(RCTResponseSenderBlock)callback) {
    if (self.recognitionTask != nil) {
        [self sendResult:RCTMakeError(@"Speech recognition already started!", nil, nil) :nil :nil :nil];
        return;
    }
    
//  NSLog(@"ZZZZZZZ");

// [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
//     if (granted) {
//         NSLog(@"granted");
//     } else {
//         NSLog(@"denied");
//     }
// }];


    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                [self sendResult:RCTMakeError(@"Speech recognition not yet authorized", nil, nil) :nil :nil :nil];
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                [self sendResult:RCTMakeError(@"User denied access to speech recognition", nil, nil) :nil :nil :nil];
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                [self sendResult:RCTMakeError(@"Speech recognition restricted on this device", nil, nil) :nil :nil :nil];
                break;
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                [self setupAndStartRecognizing:localeStr];
                break;
        }
    }];




    
    callback(false);
    
}




- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()



@end
  



// @implementation Voice

// - (dispatch_queue_t)methodQueue
// {
//   return dispatch_get_main_queue();
// }
// // This RCT (React) "macro" exposes the current module to JavaScript
// RCT_EXPORT_MODULE();



// RCT_EXPORT_METHOD(viewDidLoad) {
  
//   // Initialize the Speech Recognizer with the locale, couldn't find a list of locales
//   // but I assume it's standard UTF-8 https://wiki.archlinux.org/index.php/locale
//   speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
  
//   // Set speech recognizer delegate
//   speechRecognizer.delegate = self;
  
//   // Request the authorization to make sure the user is asked for permission so you can
//   // get an authorized response, also remember to change the .plist file, check the repo's
//   // readme file or this projects info.plist
//   [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
//     switch (status) {
//       case SFSpeechRecognizerAuthorizationStatusAuthorized:
//         NSLog(@"Authorized");
//         break;
//       case SFSpeechRecognizerAuthorizationStatusDenied:
//         NSLog(@"Denied");
//         break;
//       case SFSpeechRecognizerAuthorizationStatusNotDetermined:
//         NSLog(@"Not Determined");
//         break;
//       case SFSpeechRecognizerAuthorizationStatusRestricted:
//         NSLog(@"Restricted");
//         break;
//       default:
//         break;
//     }
//   }];
  
// }



// /*!
//  * @brief Starts listening and recognizing user input through the phone's microphone
//  */

// RCT_EXPORT_METHOD(startListening) {
  
//   // Initialize the AVAudioEngine
//   audioEngine = [[AVAudioEngine alloc] init];
  
//   // Make sure there's not a recognition task already running
//   if (recognitionTask) {
//     [recognitionTask cancel];
//     recognitionTask = nil;
//   }
  
//   // Starts an AVAudio Session
//   NSError *error;
//   AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//   [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
//   [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
  
//   // Starts a recognition process, in the block it logs the input or stops the audio
//   // process if there's an error.
//   recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
//   AVAudioInputNode *inputNode = audioEngine.inputNode;
//   recognitionRequest.shouldReportPartialResults = YES;
//   recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
//     BOOL isFinal = NO;
//     if (result) {
//       // Whatever you say in the mic after pressing the button should be being logged
//       // in the console.
//       NSLog(@"RESULT:%@",result.bestTranscription.formattedString);
//       isFinal = !result.isFinal;
//     }
//     if (error) {
//       [audioEngine stop];
//       [inputNode removeTapOnBus:0];
//       recognitionRequest = nil;
//       recognitionTask = nil;
//     }
//   }];
  
//   // Sets the recording format
//   AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
//   [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
//     [recognitionRequest appendAudioPCMBuffer:buffer];
//   }];
  
//   // Starts the audio engine, i.e. it starts listening.
//   [audioEngine prepare];
//   [audioEngine startAndReturnError:&error];
//   NSLog(@"Say Something, I'm listening");
  
  
// }




// #pragma mark - SFSpeechRecognizerDelegate Delegate Methods

// - (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
//   NSLog(@"Availability:%d",available);
// }




// RCT_EXPORT_METHOD(startSpeech:(NSString *)location callback:(RCTResponseSenderBlock)callback) {
//   if (!audioEngine.isRunning) {
//     [self startListening];
//   }
//   callback(false);
// }


// RCT_EXPORT_METHOD(stopSpeech:(RCTResponseSenderBlock)callback) {
//   if (audioEngine.isRunning) {
//     [audioEngine stop];
//     [recognitionRequest endAudio];
//   }
//   callback(false);
// }

// @end


#import "Voice.h"
#import <React/RCTLog.h>
#import <UIKit/UIKit.h>
#import <React/RCTUtils.h>
#import <React/RCTEventEmitter.h>
#import <Speech/Speech.h>

@interface Voice () <SFSpeechRecognizerDelegate>

@property (nonatomic) SFSpeechRecognizer* speechRecognizer;
@property (nonatomic) SFSpeechAudioBufferRecognitionRequest* recognitionRequest;
@property (nonatomic) AVAudioEngine* audioEngine;
@property (nonatomic) SFSpeechRecognitionTask* recognitionTask;
@property (nonatomic) AVAudioSession* audioSession;

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
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    if (error != nil && error != [NSNull null]) {
        result[@"error"] = error;
        [self sendEventWithName:@"onSpeechError" body:result[@"error"]];
    }
    if (bestTranscription != nil) {
        result[@"bestTranscription"] = @[bestTranscription[@"formattedString"]];
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
  




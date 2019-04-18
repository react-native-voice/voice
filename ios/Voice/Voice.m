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
/** Whether speech recognition is finishing.. */
@property (nonatomic) BOOL isTearingDown;
@property (nonatomic) BOOL continuous;

@property (nonatomic) NSString *sessionId;
/** Previous category the user was on prior to starting speech recognition */
@property (nonatomic) NSString* priorAudioCategory;


@end

@implementation Voice
{
}

/** Returns "YES" if no errors had occurred */
-(BOOL) setupAudioSession {
    if ([self isHeadsetPluggedIn] || [self isHeadSetBluetooth]){
        [self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error: nil];
    }
    else {
        [self.audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error: nil];
    }
    
    NSError* audioSessionError = nil;
    
    // Activate the audio session
    [self.audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&audioSessionError];
    
    if (audioSessionError != nil) {
        [self sendResult:@{@"code": @"audio", @"message": [audioSessionError localizedDescription]} :nil :nil :nil];
        return NO;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(teardown) name:RCTBridgeWillReloadNotification object:nil];
    
    return YES;
}

- (BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones] || [[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP])
            return YES;
    }
    return NO;
}

-(BOOL)isHeadSetBluetooth {
    NSArray *arrayInputs = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription *port in arrayInputs)
    {
        if ([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP])
        {
            return YES;
        }
    }
    return NO;
}

- (void) teardown {
    self.isTearingDown = YES;
    [self.recognitionTask cancel];
    self.recognitionTask = nil;
    
    // Set back audio session category
    [self resetAudioSession];
    
    // End recognition request
    [self.recognitionRequest endAudio];
    
    // Remove tap on bus
    [self.audioEngine.inputNode removeTapOnBus:0];
    [self.audioEngine.inputNode reset];
    
    // Stop audio engine and dereference it for re-allocation
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
        [self.audioEngine reset];
        self.audioEngine = nil;
    }
    
    self.recognitionRequest = nil;
    self.sessionId = nil;
    self.isTearingDown = NO;
}

-(void) resetAudioSession {
    if (self.audioSession == nil) {
        self.audioSession = [AVAudioSession sharedInstance];
    }
    // Set audio session to inactive and notify other sessions
    // [self.audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error: nil];
    NSString* audioCategory = [self.audioSession category];
    // Category hasn't changed -- do nothing
    if ([self.priorAudioCategory isEqualToString:audioCategory]) return;
    // Reset back to the previous category
    if ([self isHeadsetPluggedIn] || [self isHeadSetBluetooth]) {
        [self.audioSession setCategory:self.priorAudioCategory withOptions:AVAudioSessionCategoryOptionAllowBluetooth error: nil];
    } else {
        [self.audioSession setCategory:self.priorAudioCategory withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error: nil];
    }
    // Remove pointer reference
    self.audioSession = nil;
}

- (void) setupAndStartRecognizing:(NSString*)localeStr {
    self.audioSession = [AVAudioSession sharedInstance];
    self.priorAudioCategory = [self.audioSession category];
    // Tear down resources before starting speech recognition..
    [self teardown];
    
    self.sessionId = [[NSUUID UUID] UUIDString];
    
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
    
    // Start audio session...
    if (![self setupAudioSession]) {
        [self teardown];
        return;
    }
    
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    // Configure request so that results are returned before audio recording is finished
    self.recognitionRequest.shouldReportPartialResults = YES;
    
    if (self.recognitionRequest == nil) {
        [self sendResult:@{@"code": @"recognition_init"} :nil :nil :nil];
        [self teardown];
        return;
    }
    
    if (self.audioEngine == nil) {
        self.audioEngine = [[AVAudioEngine alloc] init];
    }
    
    AVAudioInputNode* inputNode = self.audioEngine.inputNode;
    if (inputNode == nil) {
        [self sendResult:@{@"code": @"input"} :nil :nil :nil];
        [self teardown];
        return;
    }
    
    [self sendEventWithName:@"onSpeechStart" body:nil];
    
    
    // A recognition task represents a speech recognition session.
    // We keep a reference to the task so that it can be cancelled.
    NSString *taskSessionId = self.sessionId;
    self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (![taskSessionId isEqualToString:self.sessionId]) {
            // session ID has changed, so ignore any capture results and error
            [self teardown];
            return;
        }
        if (error != nil) {
            NSString *errorMessage = [NSString stringWithFormat:@"%ld/%@", error.code, [error localizedDescription]];
            [self sendResult:@{@"code": @"recognition_fail", @"message": errorMessage} :nil :nil :nil];
            [self teardown];
            return;
        }
        
        // No result.
        if (result == nil) {
            [self sendEventWithName:@"onSpeechEnd" body:nil];
            [self teardown];
            return;
        }
        
        BOOL isFinal = result.isFinal;
        
        NSMutableArray* transcriptionDics = [NSMutableArray new];
        for (SFTranscription* transcription in result.transcriptions) {
            [transcriptionDics addObject:transcription.formattedString];
        }
        
        [self sendResult :nil :result.bestTranscription.formattedString :transcriptionDics :[NSNumber numberWithBool:isFinal]];
        
        if (isFinal || self.recognitionTask.isCancelled || self.recognitionTask.isFinishing) {
            [self sendEventWithName:@"onSpeechEnd" body:nil];
            if (!self.continuous) {
                [self teardown];
            }
            return;
        }
        
    }];
    
    AVAudioFormat* recordingFormat = [inputNode outputFormatForBus:0];
    AVAudioMixerNode *mixer = [[AVAudioMixerNode alloc] init];
    [self.audioEngine attachNode:mixer];
    
    // Start recording and append recording buffer to speech recognizer
    @try {
        [mixer installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
            // Todo: write recording buffer to file (if user opts in)
            if (self.recognitionRequest != nil) {
                [self.recognitionRequest appendAudioPCMBuffer:buffer];
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"[Error] - %@ %@", exception.name, exception.reason);
        [self sendResult:@{@"code": @"start_recording", @"message": [exception reason]} :nil :nil :nil];
        [self teardown];
        return;
    } @finally {}
    
    [self.audioEngine connect:inputNode to:mixer format:recordingFormat];
    [self.audioEngine prepare];
    NSError* audioSessionError = nil;
    [self.audioEngine startAndReturnError:&audioSessionError];
    if (audioSessionError != nil) {
        [self sendResult:@{@"code": @"audio", @"message": [audioSessionError localizedDescription]} :nil :nil :nil];
        [self teardown];
        return;
    }
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[
        @"onSpeechResults",
        @"onSpeechStart",
        @"onSpeechPartialResults",
        @"onSpeechError",
        @"onSpeechEnd",
        @"onSpeechRecognized",
        @"onSpeechVolumeChanged"
    ];
}

- (void) sendResult:(NSDictionary*)error :(NSString*)bestTranscription :(NSArray*)transcriptions :(NSNumber*)isFinal {
    if (error != nil) {
        [self sendEventWithName:@"onSpeechError" body:@{@"error": error}];
    }
    if (bestTranscription != nil) {
        [self sendEventWithName:@"onSpeechResults" body:@{@"value":@[bestTranscription]} ];
    }
    if (transcriptions != nil) {
        [self sendEventWithName:@"onSpeechPartialResults" body:@{@"value":transcriptions} ];
    }
    if (isFinal != nil) {
        [self sendEventWithName:@"onSpeechRecognized" body: @{@"isFinal": isFinal}];
    }
}

// Called when the availability of the given recognizer changes
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    if (available == false) {
        [self sendResult:RCTMakeError(@"Speech recognition is not available now", nil, nil) :nil :nil :nil];
    }
}

RCT_EXPORT_METHOD(stopSpeech:(RCTResponseSenderBlock)callback)
{
    [self.recognitionTask finish];
    callback(@[@false]);
}


RCT_EXPORT_METHOD(cancelSpeech:(RCTResponseSenderBlock)callback) {
    [self.recognitionTask cancel];
    callback(@[@false]);
}

RCT_EXPORT_METHOD(destroySpeech:(RCTResponseSenderBlock)callback) {
    [self teardown];
    callback(@[@false]);
}

RCT_EXPORT_METHOD(isSpeechAvailable:(RCTResponseSenderBlock)callback) {
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                callback(@[@true]);
                break;
            default:
                callback(@[@false]);
        }
    }];
}
RCT_EXPORT_METHOD(isRecognizing:(RCTResponseSenderBlock)callback) {
    if (self.recognitionTask != nil){
        switch (self.recognitionTask.state) {
            case SFSpeechRecognitionTaskStateRunning:
                callback(@[@true]);
                break;
            default:
                callback(@[@false]);
        }
    }
    else {
        callback(@[@false]);
    }
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
    callback(@[@false]);
}


- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()



@end

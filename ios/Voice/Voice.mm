#import "Voice.h"
#import <React/RCTLog.h>
#import <React/RCTConvert.h>
#import <Accelerate/Accelerate.h>

@interface Voice() <SFSpeechRecognizerDelegate, AVAudioRecorderDelegate>
@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic, assign) BOOL isTearingDown;
@property (nonatomic, assign) float averagePowerForChannel0;
@property (nonatomic, assign) float averagePowerForChannel1;
@end

@implementation Voice

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents {
  return @[
    @"onSpeechStart",
    @"onSpeechRecognized",
    @"onSpeechEnd",
    @"onSpeechError",
    @"onSpeechResults",
    @"onSpeechPartialResults",
    @"onSpeechVolumeChanged"
  ];
}

#pragma mark - Public API

RCT_EXPORT_METHOD(startSpeech:(NSString *)localeStr resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  if (self.audioEngine.isRunning) {
    reject(@"already_running", @"Speech recognition is already running", nil);
    return;
  }
  [self setupAndStartRecognizing:localeStr];
  resolve(@(YES));
}

RCT_EXPORT_METHOD(stopSpeech:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [self.audioEngine stop];
  [self.recognitionRequest endAudio];
  resolve(@(YES));
}

RCT_EXPORT_METHOD(cancelSpeech:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [self teardown];
  resolve(@(YES));
}

#pragma mark - Setup and Recognition

- (void)setupAndStartRecognizing:(NSString*)localeStr {
  // Cancel old task
  if (self.recognitionTask != nil) {
    [self.recognitionTask cancel];
    self.recognitionTask = nil;
  }

  // Configure audio session
  NSError *error = nil;
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  [audioSession setCategory:AVAudioSessionCategoryRecord
                withOptions:AVAudioSessionCategoryOptionDuckOthers
                      error:&error];
  [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
  [audioSession setActive:YES
              withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                    error:&error];

  if (error) {
    [self sendResult:@{@"code": @"audio_session_error", @"message": error.localizedDescription} :nil :nil :nil];
    return;
  }

  // Create request
  self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
  if (!self.recognitionRequest) {
    [self sendResult:@{@"code": @"recognition_request_nil"} :nil :nil :nil];
    return;
  }
  self.recognitionRequest.shouldReportPartialResults = YES;

  // Setup recognizer
  NSLocale *locale = [NSLocale localeWithLocaleIdentifier:localeStr ?: @"en-US"];
  self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
  self.speechRecognizer.delegate = self;

  __weak typeof(self) weakSelf = self;
  self.recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest
                                                            resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
    if (result) {
      [weakSelf handleSpeechRecognitionResult:result];
    }
    if (error) {
      [weakSelf sendResult:@{@"code": @"recognition_error", @"message": error.localizedDescription} :nil :nil :nil];
      [weakSelf teardown];
    }
  }];

  // Audio engine
  self.audioEngine = [[AVAudioEngine alloc] init];
  AVAudioInputNode *inputNode = self.audioEngine.inputNode;
  if (inputNode == nil) {
    [self sendResult:@{@"code" : @"input_node_nil"} :nil :nil :nil];
    [self teardown];
    return;
  }

  // ✅ FIX: use system-provided format
  AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];

  // Install tap
  [inputNode installTapOnBus:0
                  bufferSize:1024
                      format:recordingFormat
                       block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
    // Volume metering
    UInt32 inNumberFrames = buffer.frameLength;
    float LEVEL_LOWPASS_TRIG = 0.5;

    if (buffer.format.channelCount > 0) {
      Float32 *samples = (Float32 *)buffer.floatChannelData[0];
      Float32 avgValue = 0;
      vDSP_maxmgv(samples, 1, &avgValue, inNumberFrames);
      weakSelf.averagePowerForChannel0 =
        (LEVEL_LOWPASS_TRIG * ((avgValue == 0) ? -100 : 20.0 * log10f(avgValue))) +
        ((1 - LEVEL_LOWPASS_TRIG) * weakSelf.averagePowerForChannel0);
      weakSelf.averagePowerForChannel1 = weakSelf.averagePowerForChannel0;
    }

    if (buffer.format.channelCount > 1) {
      Float32 *samples = (Float32 *)buffer.floatChannelData[1];
      Float32 avgValue = 0;
      vDSP_maxmgv(samples, 1, &avgValue, inNumberFrames);
      weakSelf.averagePowerForChannel1 =
        (LEVEL_LOWPASS_TRIG * ((avgValue == 0) ? -100 : 20.0 * log10f(avgValue))) +
        ((1 - LEVEL_LOWPASS_TRIG) * weakSelf.averagePowerForChannel1);
    }

    weakSelf.averagePowerForChannel1 =
      [weakSelf _normalizedPowerLevelFromDecibels:weakSelf.averagePowerForChannel1] * 10;

    NSNumber *value = [NSNumber numberWithFloat:weakSelf.averagePowerForChannel1];
    [weakSelf sendEventWithName:@"onSpeechVolumeChanged" body:@{@"value" : value}];

    // Append buffer
    if (weakSelf.recognitionRequest != nil && !weakSelf.isTearingDown) {
      [weakSelf.recognitionRequest appendAudioPCMBuffer:buffer];
    }
  }];

  // Start engine
  [self.audioEngine prepare];
  [self.audioEngine startAndReturnError:&error];

  if (error) {
    [self sendResult:@{@"code": @"audio_engine_error", @"message": error.localizedDescription} :nil :nil :nil];
    [self teardown];
    return;
  }
}

#pragma mark - Helpers

- (void)handleSpeechRecognitionResult:(SFSpeechRecognitionResult *)result {
  if (result.isFinal) {
    [self sendEventWithName:@"onSpeechResults"
                       body:@{@"value": result.bestTranscription.formattedString ?: @""}];
  } else {
    [self sendEventWithName:@"onSpeechPartialResults"
                       body:@{@"value": result.bestTranscription.formattedString ?: @""}];
  }
}

- (float)_normalizedPowerLevelFromDecibels:(float)decibels {
  if (decibels < -60.0f || decibels == 0.0f) {
    return 0.0f;
  }
  float minAmp = powf(10.0f, 0.05f * -60.0f);
  float inverseAmpRange = 1.0f / (1.0f - minAmp);
  float amp = powf(10.0f, 0.05f * decibels);
  float adjAmp = (amp - minAmp) * inverseAmpRange;
  return powf(adjAmp, 1.0f / 2.0f);
}

- (void)sendResult:(NSDictionary *)error :(NSString *)recognizedText :(NSString *)isFinal :(NSString *)extra {
  [self sendEventWithName:@"onSpeechError" body:error];
}

- (void)teardown {
  self.isTearingDown = YES;

  [self.audioEngine stop];
  [self.audioEngine.inputNode removeTapOnBus:0];
  [self.recognitionRequest endAudio];
  [self.recognitionTask cancel];

  self.recognitionTask = nil;
  self.recognitionRequest = nil;
  self.audioEngine = nil;

  self.isTearingDown = NO;
}

@end

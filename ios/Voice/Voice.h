#import <React/RCTEventEmitter.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import "RNVoiceSpec.h"

@interface Voice : RCTEventEmitter <NativeVoiceIOSSpec>
#else
#import <React/RCTBridgeModule.h>

@interface Voice : RCTEventEmitter <RCTBridgeModule>
#endif

@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (nonatomic, strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic, assign) BOOL isTearingDown;
@property (nonatomic, assign) float averagePowerForChannel0;
@property (nonatomic, assign) float averagePowerForChannel1;

- (void)setupAndStartRecognizing:(NSString*)localeStr;
- (void)teardown;

@end

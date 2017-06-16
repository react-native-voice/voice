#import <React/RCTBridgeModule.h>
#import <Speech/Speech.h>

@interface Voice : NSObject <RCTBridgeModule, SFSpeechRecognizerDelegate> {
  SFSpeechRecognizer *speechRecognizer;
  SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
  SFSpeechRecognitionTask *recognitionTask;
  AVAudioEngine *audioEngine;
}
@end


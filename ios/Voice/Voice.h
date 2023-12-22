#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
@interface Voice : RCTEventEmitter <RCTBridgeModule>
@interface SFSpeechRecognitionMetadata : NSObject
@property (nonatomic, readonly) NSTimeInterval speechDuration;
@end

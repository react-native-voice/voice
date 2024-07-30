
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNVoiceSpec.h"

@interface Voice : NSObject <NativeVoiceSpec>
#else
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface Voice : RCTEventEmitter <RCTBridgeModule>
#endif
@end

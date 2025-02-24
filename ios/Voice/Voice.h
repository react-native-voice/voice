
#import <React/RCTEventEmitter.h>
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNVoiceSpec.h"


@interface Voice : RCTEventEmitter <NativeVoiceIOSSpec>
#else
#import <React/RCTBridgeModule.h>

@interface Voice : RCTEventEmitter <RCTBridgeModule>
#endif

@end

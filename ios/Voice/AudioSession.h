//
//  AudioSession.h
//  LohasAssistant
//
//  Created by 廖偉宏 on 2017/10/27.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "React/RCTBridgeModule.h"
#import <React/RCTEventEmitter.h>

@import AVFoundation;

@interface AudioSession : RCTEventEmitter <RCTBridgeModule, AVSpeechSynthesizerDelegate>

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;

@end

//
//  AudioSession.m
//  LohasAssistant
//
//  Created by 廖偉宏 on 2017/10/27.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "AudioSession.h"

#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>
#import <UIKit/UIKit.h>
#import <React/RCTUtils.h>
#import <React/RCTEventEmitter.h>
#import <Speech/Speech.h>

@implementation AudioSession
// This RCT (React) "macro" exposes the current module to JavaScript

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

-(NSArray<NSString *> *)supportedEvents
{
    return @[@"tts-start", @"tts-finish", @"tts-pause", @"tts-resume", @"tts-progress", @"tts-cancel"];
}


-(instancetype)init
{
    self = [super init];
    if (self) {
        _synthesizer = [AVSpeechSynthesizer new];
        _synthesizer.delegate = self;
    }

    return self;
}

// We must explicitly expose methods otherwise JavaScript can't access anything
RCT_EXPORT_METHOD(setSpeakReady)
{
   [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
}
RCT_EXPORT_METHOD(setListenReady)
{
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error: nil];
}

RCT_EXPORT_METHOD(setPlayAndRecord)
{
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error: nil];
}

@end

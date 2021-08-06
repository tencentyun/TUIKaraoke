//
//  KaraokeTRTCService.h
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TXKaraokeBaseDef.h"

NS_ASSUME_NONNULL_BEGIN

#define kTRTCRoleAnchorValue 20
#define kTRTCRoleAudienceValue 21

@class TRTCQualityInfo;
@class TRTCVolumeInfo;
@class TRTCAudioRecordingParams;

@protocol KaraokeTRTCServiceDelegate <NSObject>

- (void)onTRTCAnchorEnter:(NSString *)userId;
- (void)onTRTCAnchorExit:(NSString *)userId;
- (void)onTRTCAudioAvailable:(NSString *)userId available:(BOOL)available;
- (void)onError:(NSInteger)code message:(NSString *)message;
- (void)onNetWorkQuality:(TRTCQualityInfo *)trtcQuality arrayList:(NSArray<TRTCQualityInfo *> *)arrayList;
- (void)onUserVoiceVolume:(NSArray<TRTCVolumeInfo *> *)userVolumes totalVolume:(NSInteger)totalVolume;
- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message;
@end

@interface KaraokeTRTCService : NSObject

@property (nonatomic, weak) id<KaraokeTRTCServiceDelegate> delegate;

+ (instancetype)sharedInstance;

- (void)enterRoomWithSdkAppId:(UInt32)sdkAppId roomId:(NSString *)roomId userId:(NSString *)userId userSign:(NSString *)userSign role:(NSInteger)role callback:(TXKaraokeCallback _Nullable)callback;

- (void)exitRoom:(TXKaraokeCallback _Nullable)callback;

- (void)muteLocalAudio:(BOOL)isMute;

- (void)setVoiceEarMonitorEnable:(BOOL)enable;

- (void)muteRemoteAudioWithUserId:(NSString *)userId isMute:(BOOL)isMute;

- (void)muteAllRemoteAudio:(BOOL)isMute;

- (void)setAudioQuality:(NSInteger)quality;

- (void)startMicrophone;

- (void)stopMicrophone;

- (void)switchToAnchor;

- (void)switchToAudience;

- (void)setSpeaker:(BOOL)userSpeaker;

- (void)setAudioCaptureVolume:(NSInteger)volume;

- (void)setAudioPlayoutVolume:(NSInteger)volume;

- (void)startFileDumping:(TRTCAudioRecordingParams *)params;

- (void)stopFileDumping;

- (void)enableAudioEvalutation:(BOOL)enable;

- (void)sendSEIMsg:(NSData *)data;

- (void)enableBlackStream:(BOOL)enable size:(CGSize)size;
@end

NS_ASSUME_NONNULL_END

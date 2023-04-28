//
//  KaraokeTRTCService.h
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRTCKaraokeRoomDef.h"
#import "KaraokeTRTCServiceObserver.h"

NS_ASSUME_NONNULL_BEGIN

@class TXAudioEffectManager;

@interface KaraokeTRTCService : NSObject

@property (nonatomic, weak) id<KaraokeTRTCServiceObserver> observer;

- (void)updateOwnerId:(NSString *)ownerId;

- (void)enterRoomWithSdkAppId:(UInt32)sdkAppId
                       roomId:(UInt32)roomId
                       userId:(NSString *)userId
                     userSign:(NSString *)userSign
                         role:(NSInteger)role
                     callback:(KaraokeCallback _Nullable)callback;

- (void)exitRoom:(KaraokeCallback _Nullable)callback;

- (void)muteLocalAudio:(BOOL)isMute;

- (void)setVoiceEarMonitorEnable:(BOOL)enable;

- (void)muteRemoteAudioWithUserId:(NSString *)userId isMute:(BOOL)isMute;

- (void)muteAllRemoteAudio:(BOOL)isMute;

- (void)startMicrophone;

- (void)stopMicrophone;

- (void)switchToAnchor;

- (void)switchToAudience;

- (void)enableAudioEvalutation:(BOOL)enable;

- (void)sendSEIMsg:(NSData *)data;

- (void)updatePublishMediaStream;

- (void)startChorus:(NSString *)musicId originalUrl:(NSString *)originalUrl accompanyUrl:(NSString *)accompanyUrl isOwner:(BOOL)isOwner;

- (void)stopChorus;

- (TXAudioEffectManager *)getVoiceAudioEffectManager;

- (TXAudioEffectManager *)getMusicAudioEffectManager;

- (void)switchMusicAccompanimentMode:(BOOL)isOriginMusic;

@end

NS_ASSUME_NONNULL_END

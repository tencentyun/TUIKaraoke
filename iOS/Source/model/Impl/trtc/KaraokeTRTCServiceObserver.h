//
//  KaraokeTRTCServiceObserver.h
//  Pods
//
//  Created by adams on 2023/3/20.
//  Copyright © 2023 tencent. All rights reserved.
//

#ifndef KaraokeTRTCServiceObserver_h
#define KaraokeTRTCServiceObserver_h

@class TRTCQualityInfo;
@class TRTCVolumeInfo;
@class TRTCStatistics;

@protocol KaraokeTRTCServiceObserver <NSObject>
- (void)onTRTCAnchorEnter:(NSString *)userId;
- (void)onTRTCAnchorExit:(NSString *)userId;
- (void)onTRTCAudioAvailable:(NSString *)userId available:(BOOL)available;
- (void)onError:(NSInteger)code message:(NSString *)message;
- (void)onNetWorkQuality:(TRTCQualityInfo *)trtcQuality arrayList:(NSArray<TRTCQualityInfo *> *)arrayList;
- (void)onUserVoiceVolume:(NSArray<TRTCVolumeInfo *> *)userVolumes totalVolume:(NSInteger)totalVolume;
- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message;
- (void)genUserSign:(NSString *)userId completion:(void (^)(NSString *userSign))completion;
- (void)onMusicProgressUpdate:(int32_t)musicID progress:(NSInteger)progress duration:(NSInteger)durationMS;
- (void)onReceiveAnchorSendChorusMsg:(NSString *)musicID startDelay:(NSInteger)startDelay;
- (void)onMusicPlayError:(int32_t)musicID errorCode:(NSInteger)errorCode message:(NSString *)message;
- (void)onMusicPlayCompleted:(int32_t)musicID;
- (void)onStatistics:(TRTCStatistics *)statistics;
- (void)onMusicAccompanimentModeChanged:(NSString *)musicID isOriginal:(BOOL)isOriginal;
@end
#endif /* KaraokeTRTCServiceObserver_h */

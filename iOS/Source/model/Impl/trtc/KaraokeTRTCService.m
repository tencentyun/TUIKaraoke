//
//  KaraokeTRTCService.m
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "KaraokeTRTCService.h"
#import "TXLiteAVSDK_TRTC/TRTCCloud.h"
#import "KaraokeChorusExtension.h"
#import "KaraokeLogger.h"

static NSString *const kAudioBgm = @"_bgm";
static NSString *const kMixRobot = @"_robot";

static const int TC_COMPONENT_KARAOKE = 8;
static const int TC_TRTC_FRAMEWORK    = 1;

@interface KaraokeTRTCService () <TRTCCloudDelegate, KaraokeChorusExtensionObserver>

@property (nonatomic, copy) NSString *ownerId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *mixTaskId;
@property (nonatomic, copy) NSString *bgmUserSign;
@property (nonatomic, copy) NSString *mixRobotUserId;

@property (nonatomic, assign) UInt32 roomId;
@property (nonatomic, assign) BOOL isInRoom;

@property (nonatomic, copy) KaraokeCallback enterRoomCallback;
@property (nonatomic, copy) KaraokeCallback exitRoomCallback;

@property (nonatomic, strong) TRTCParams *voiceParams;
@property (nonatomic, strong) TRTCParams *bgmParams;

@property (nonatomic, strong) TRTCCloud *voiceCloud;
@property (nonatomic, strong) TRTCCloud *bgmCloud;

@property (nonatomic, strong) KaraokeChorusExtension *chorusExtension;

// 混流相关
@property (nonatomic, strong) TRTCPublishTarget *publishTarget;
@property (nonatomic, strong) TRTCStreamEncoderParam *streamEncoderParam;
@property (nonatomic, strong) TRTCStreamMixingConfig *streamMixingConfig;

@end

@implementation KaraokeTRTCService

- (void)dealloc {
    TRTCLog(@"%@ dealloc", NSStringFromClass(self.class));
}

- (void)updateOwnerId:(NSString *)ownerId {
    self.ownerId = ownerId;
}

- (void)enterRoomWithSdkAppId:(UInt32)sdkAppId
                       roomId:(UInt32)roomId
                       userId:(NSString *)userId
                     userSign:(NSString *)userSign
                         role:(NSInteger)role
                     callback:(KaraokeCallback _Nullable)callback {
    BOOL isParamError = NO;
    if (roomId == 0) {
        isParamError = YES;
    }
    if (userId == nil || [userId isEqualToString:@""]) {
        isParamError = YES;
    }
    if (userSign == nil || [userSign isEqualToString:@""]) {
        isParamError = YES;
    }
    if (isParamError) {
        TRTCLog(@"error: enter trtc room fail. params invalid. room id:%d, userId:%@, userSig is empty:%d",
                roomId,
                userId,
                (userSign == nil || [userSign isEqualToString:@""]));
        callback(-1, @"enter trtc room fail.");
        return;
    }
    self.userId = userId;
    self.roomId = roomId;
    self.mixRobotUserId = [NSString stringWithFormat:@"%d%@",roomId, kMixRobot];
    self.enterRoomCallback = callback;
    TRTCLog(@"enter room. app id:%u, room id: %d, userID: %@", (unsigned int)sdkAppId, roomId, userId);
    
    self.voiceParams = [[TRTCParams alloc] init];
    self.voiceParams.sdkAppId = sdkAppId;
    self.voiceParams.userId = userId;
    self.voiceParams.userSig = userSign;
    self.voiceParams.role = role;
    self.voiceParams.roomId = roomId;
    [self createVoiceTRTCInstanceWith:self.voiceParams];
    
    if (role == TRTCRoleAnchor) {
        NSString *bgmUserId = [NSString stringWithFormat:@"%@%@",userId,kAudioBgm];
        TRTCLog(@"Generate BgmUserId = %@",bgmUserId);
        if (self.observer && [self.observer respondsToSelector:@selector(genUserSign:completion:)]) {
            
            __weak typeof(self)weakSelf = self;
            [self.observer genUserSign:bgmUserId completion:^(NSString * _Nonnull userSign) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                strongSelf.bgmUserSign = userSign;
                
                strongSelf.bgmParams = [[TRTCParams alloc] init];
                strongSelf.bgmParams.sdkAppId = sdkAppId;
                strongSelf.bgmParams.userId = bgmUserId;
                strongSelf.bgmParams.userSig = strongSelf.bgmUserSign;
                strongSelf.bgmParams.role = role;
                strongSelf.bgmParams.roomId = roomId;
                
                [strongSelf createBGMTRTCInstanceWith:strongSelf.bgmParams];
                strongSelf.chorusExtension = [[KaraokeChorusExtension alloc] initWithVoiceCloud:strongSelf.voiceCloud
                                                                                       bgmCloud:strongSelf.bgmCloud];
                strongSelf.chorusExtension.observer = strongSelf;
                [strongSelf startPublishMediaStream:roomId bgmUserId:bgmUserId];
            }];
        }
    } else {
        self.chorusExtension = [[KaraokeChorusExtension alloc] initWithVoiceCloud:self.voiceCloud
                                                                         bgmCloud:nil];
        self.chorusExtension.observer = self;
    }
    [self internalEnterRoom];
}

- (void)updatePublishMediaStream {
    TRTCLog(@"updatePublishMediaStream:  mixTaskId = %@",self.mixTaskId);
    if (self.mixTaskId && self.mixTaskId.length > 0 &&
        self.publishTarget &&
        self.streamEncoderParam &&
        self.streamMixingConfig) {
        [self.voiceCloud updatePublishMediaStream:self.mixTaskId
                                    publishTarget:self.publishTarget
                                     encoderParam:self.streamEncoderParam
                                     mixingConfig:self.streamMixingConfig];
    }
}

- (void)exitRoom:(KaraokeCallback)callback {
    TRTCLog(@"exitRoom");
    self.exitRoomCallback = callback;
    [self stopMicrophone];
    if (self.mixTaskId.length > 0) {
        [self.voiceCloud stopPublishMediaStream:self.mixTaskId];
    }
    [self.chorusExtension stopChorus];
    // 关闭合唱模式（人声）
    [self enableChorusCallExperimentalAPI:self.voiceCloud audioSource:0 enable:NO];
    // 关闭低延时模式（人声）
    [self enableLowLatencyModeCallExperimentalAPI:self.voiceCloud enable:NO];
    
    if (self.bgmCloud) {
        // 关闭合唱模式（背景音乐）
        [self enableChorusCallExperimentalAPI:self.bgmCloud audioSource:1 enable:NO];
        // 关闭低延时模式（背景音乐）
        [self enableLowLatencyModeCallExperimentalAPI:self.bgmCloud enable:NO];
    }
    if (self.bgmCloud) {
        [self.bgmCloud exitRoom];
        [self.voiceCloud destroySubCloud:self.bgmCloud];
    }
    [self.voiceCloud exitRoom];
    [TRTCCloud destroySharedIntance];
    self.chorusExtension = nil;
}

- (void)muteLocalAudio:(BOOL)isMute {
    [self.voiceCloud muteLocalAudio:isMute];
    TRTCLog(@"mute local %d", isMute);
}

- (void)muteRemoteAudioWithUserId:(NSString *)userId isMute:(BOOL)isMute {
    [self.voiceCloud muteRemoteAudio:userId mute:isMute];
}

- (void)muteAllRemoteAudio:(BOOL)isMute {
    [self.voiceCloud muteAllRemoteAudio:isMute];
}

- (void)startChorus:(NSString *)musicId
        originalUrl:(NSString *)originalUrl
       accompanyUrl:(NSString *)accompanyUrl
            isOwner:(BOOL)isOwner {
    if (self.bgmCloud) {
        // 开启BGM黑帧推送
        [self enableBGMBlackStream:self.bgmCloud enable:YES];
    }
    [self.chorusExtension startChorus:musicId
                          originalUrl:originalUrl
                         accompanyUrl:accompanyUrl
                               reason:isOwner ? ChorusStartReasonLocal : ChorusStartReasonRemote];
}

- (void)stopChorus {
    if (self.isInRoom) {
        if (self.bgmCloud) {
            // 开启BGM黑帧推送
            [self enableBGMBlackStream:self.bgmCloud enable:NO];
        }
        [self.chorusExtension stopChorus];
    }
}

- (TXAudioEffectManager *)getVoiceAudioEffectManager {
    return [self.voiceCloud getAudioEffectManager];
}

- (TXAudioEffectManager *)getMusicAudioEffectManager {
    if (self.bgmCloud) {
        return [self.bgmCloud getAudioEffectManager];
    }
    return [self getVoiceAudioEffectManager];
}

- (void)startMicrophone {
    if (self.voiceParams.role == TRTCRoleAnchor) {
        [self.voiceCloud setSystemVolumeType:TRTCSystemVolumeTypeMedia];
        [self.voiceCloud startLocalAudio:TRTCAudioQualityDefault];
    }
}

- (void)stopMicrophone {
    [self.voiceCloud stopLocalAudio];
}

- (void)switchToAnchor {
    self.voiceParams.role = TRTCRoleAnchor;
    [self.voiceCloud switchRole:TRTCRoleAnchor];
    [self startMicrophone];
    
    // 开启合唱模式（人声）
    [self enableChorusCallExperimentalAPI:self.voiceCloud audioSource:0 enable:YES];
    // 开启低延时模式（人声）
    [self enableLowLatencyModeCallExperimentalAPI:self.voiceCloud enable:YES];
    if (self.bgmCloud) {
        // 开启合唱模式（背景音乐）
        [self enableChorusCallExperimentalAPI:self.bgmCloud audioSource:1 enable:YES];
        // 开启低延时模式（背景音乐）
        [self enableLowLatencyModeCallExperimentalAPI:self.bgmCloud enable:YES];
    }
}

- (void)switchToAudience {
    self.voiceParams.role = TRTCRoleAudience;
    [self stopMicrophone];
    [self.voiceCloud switchRole:TRTCRoleAudience];
    
    // 关闭合唱模式（人声）
    [self enableChorusCallExperimentalAPI:self.voiceCloud audioSource:0 enable:NO];
    // 关闭低延时模式（人声）
    [self enableLowLatencyModeCallExperimentalAPI:self.voiceCloud enable:NO];
    
    if (self.bgmCloud) {
        // 关闭合唱模式（背景音乐）
        [self enableChorusCallExperimentalAPI:self.bgmCloud audioSource:1 enable:NO];
        // 关闭低延时模式（背景音乐）
        [self enableLowLatencyModeCallExperimentalAPI:self.bgmCloud enable:NO];
    }
}

- (void)enableAudioEvalutation:(BOOL)enable {
    [self.voiceCloud enableAudioVolumeEvaluation:enable ? 300 : 0 enable_vad:false];
}

- (void)sendSEIMsg:(NSData *)data {
    BOOL res = [self.voiceCloud sendSEIMsg:data repeatCount:1];
    if (!res) {
        TRTCLog(@"send SEI failed");
    }
}

- (void)startRemoteVideo:(NSString *)userId {
    [self.voiceCloud startRemoteView:userId streamType:TRTCVideoStreamTypeBig view:nil];
}

- (void)stopRemoteVideo:(NSString *)userId {
    [self.voiceCloud stopRemoteView:userId streamType:TRTCVideoStreamTypeBig];
}

- (void)switchMusicAccompanimentMode:(BOOL)isOriginMusic {
    self.chorusExtension.isOriginMusic = isOriginMusic;
}

#pragma mark - private method
- (void)internalEnterRoom {
    if (self.voiceParams) {
        self.voiceCloud.delegate = self;
        [self enableAudioEvalutation:YES];
        [self setFramework];
    }
}

- (void)setFramework {
    NSDictionary *jsonDic = @{@"api": @"setFramework",
                              @"params":@{@"framework": @(TC_TRTC_FRAMEWORK),
                                          @"component": @(TC_COMPONENT_KARAOKE)}};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    TRTCLog(@"jsonString = %@",jsonString);
    [self.voiceCloud callExperimentalAPI: jsonString];
}

- (void)createVoiceTRTCInstanceWith:(TRTCParams *)trtcParams {
    TRTCLog(@"%@",[NSString stringWithFormat:@"createVoiceTRTCInstanceWith:%@", trtcParams.userId]);
    self.voiceCloud = [TRTCCloud sharedInstance];
    NSString *bgmUserId = [NSString stringWithFormat:@"%@%@",self.ownerId,kAudioBgm];
    TRTCLog(@"muteRemoteAudio bgmUserId = %@",bgmUserId);
    [self.voiceCloud muteRemoteAudio:bgmUserId mute:YES];
    [self.voiceCloud muteRemoteVideoStream:bgmUserId streamType:TRTCVideoStreamTypeBig mute:YES];
    [self.voiceCloud enterRoom:trtcParams appScene:TRTCAppSceneLIVE];
    // 设置媒体类型
    [self.voiceCloud setSystemVolumeType:TRTCSystemVolumeTypeMedia];
}

- (void)createBGMTRTCInstanceWith:(TRTCParams *)trtcParams {
    TRTCLog(@"%@",[NSString stringWithFormat:@"createBGMTRTCInstanceWith:%@", trtcParams.userId]);
    self.bgmCloud = [self.voiceCloud createSubCloud];
    [self.bgmCloud setDefaultStreamRecvMode:NO video:NO];
    [self.bgmCloud enterRoom:trtcParams appScene:TRTCAppSceneLIVE];
    //设置媒体类型
    [self.bgmCloud setSystemVolumeType:TRTCSystemVolumeTypeMedia];
    [self.bgmCloud setAudioQuality:TRTCAudioQualityMusic];
}

- (void)enableBGMBlackStream:(TRTCCloud *)trtcCloud enable:(BOOL)enable {
    NSDictionary *jsonDic = @{@"api": @"enableBlackStream",
                              @"params": @{@"enable": @(enable)}};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [trtcCloud callExperimentalAPI:jsonString];
}

- (void)enableChorusCallExperimentalAPI:(TRTCCloud *)trtcCloud
                            audioSource:(int)audioSource
                                 enable:(BOOL)enable {
    NSDictionary *jsonDic = @{@"api": @"enableChorus",
                              @"params": @{@"enable": @(enable),
                                           @"audioSource": @(audioSource)}};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [trtcCloud callExperimentalAPI:jsonString];
}

- (void)enableLowLatencyModeCallExperimentalAPI:(TRTCCloud *)trtcCloud enable:(BOOL)enable {
    NSDictionary *jsonDic = @{@"api": @"setLowLatencyModeEnabled",
                              @"params": @{@"enable": @(enable)}};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [trtcCloud callExperimentalAPI:jsonString];
}

- (BOOL)canDelegateResponseMethod:(SEL)method {
    return self.observer && [self.observer respondsToSelector:method];
}

- (void)startPublishMediaStream:(UInt32)roomId bgmUserId:(NSString *)bgmUserId {
    if (roomId == 0) {
        TRTCLog(@"startPublishMediaStream error roomId = %d",roomId);
        return;
    }
    
    TRTCUser *mixStreamRobot = [[TRTCUser alloc] init];
    mixStreamRobot.userId = self.mixRobotUserId;
    mixStreamRobot.intRoomId = roomId;
    
    self.publishTarget = [[TRTCPublishTarget alloc] init];
    self.publishTarget.mixStreamIdentity = mixStreamRobot;
    self.publishTarget.mode = TRTCPublishMixStreamToRoom;
    
    self.streamEncoderParam = [[TRTCStreamEncoderParam alloc] init];
    self.streamEncoderParam.videoEncodedFPS = 15;
    self.streamEncoderParam.videoEncodedGOP = 3;
    self.streamEncoderParam.videoEncodedKbps = 30;
    self.streamEncoderParam.audioEncodedSampleRate = 48000;
    self.streamEncoderParam.audioEncodedChannelNum = 2;
    self.streamEncoderParam.audioEncodedKbps = 128;
    self.streamEncoderParam.audioEncodedCodecType = 2;
    
    TRTCUser *mixVideoUser = [[TRTCUser alloc] init];
    mixVideoUser.userId = bgmUserId;
    mixVideoUser.intRoomId = roomId;

    TRTCVideoLayout *videoLayout = [[TRTCVideoLayout alloc] init];
    videoLayout.fixedVideoStreamType = TRTCVideoStreamTypeBig;
    videoLayout.rect = CGRectMake(0, 0, 64, 64);
    videoLayout.zOrder = 0;
    videoLayout.fixedVideoUser = mixVideoUser;
    
    self.streamMixingConfig = [[TRTCStreamMixingConfig alloc] init];
    self.streamMixingConfig.videoLayoutList = @[videoLayout];
    
    [self.voiceCloud startPublishMediaStream:self.publishTarget
                                encoderParam:self.streamEncoderParam
                                mixingConfig:self.streamMixingConfig];
}

#pragma mark - KaraokeChorusExtensionDelegate
// 合唱已开始
- (void)onChorusStart:(ChorusStartReason)reason message:(NSString *)msg {
    TRTCLog(@"onChorusStart reason = %ld message = %@",reason, msg);
}

// 音乐播放失败的回调
- (void)onMusicPlayError:(int32_t)musicID errorCode:(NSInteger)errorCode message:(NSString *)message {
    if ([self canDelegateResponseMethod:@selector(onMusicPlayError:errorCode:message:)]) {
        [self.observer onMusicPlayError:musicID errorCode:errorCode message:message];
    }
}

// 音乐播放结束的回调
- (void)onMusicPlayCompleted:(int32_t)musicID {
    if ([self canDelegateResponseMethod:@selector(onMusicPlayCompleted:)]) {
        [self.observer onMusicPlayCompleted:musicID];
    }
}

// 合唱音乐进度回调
- (void)onMusicProgressUpdate:(int32_t)musicID progress:(NSInteger)progress duration:(NSInteger)durationMS {
    if ([self canDelegateResponseMethod:@selector(onMusicProgressUpdate:progress:duration:)]) {
        [self.observer onMusicProgressUpdate:musicID progress:progress duration:durationMS];
    }
}

// 接收到发起合唱的消息的回调
- (void)onReceiveAnchorSendChorusMsg:(NSString *)musicID startDelay:(NSInteger)startDelay {
    if ([self canDelegateResponseMethod:@selector(onReceiveAnchorSendChorusMsg:startDelay:)]) {
        [self.observer onReceiveAnchorSendChorusMsg:musicID startDelay:startDelay];
    }
}

// 接收到合唱伴奏切换的消息的回调
- (void)onMusicAccompanimentModeChanged:(NSString *)musicID isOriginal:(BOOL)isOriginal {
    if ([self canDelegateResponseMethod:@selector(onMusicAccompanimentModeChanged:isOriginal:)]) {
        [self.observer onMusicAccompanimentModeChanged:musicID isOriginal:isOriginal];
    }
}

#pragma mark - TRTCCloudDelegate
- (void)onEnterRoom:(NSInteger)result {
    TRTCLog(@"on enter trtc room. result:%ld", (long)result);
    if (result > 0) {
        self.isInRoom = YES;
        if (self.enterRoomCallback) {
            self.enterRoomCallback(0, @"enter trtc room success.");
        }
    } else {
        self.isInRoom = NO;
        NSString *errorMsg = (result == ERR_TRTC_USER_SIG_CHECK_FAILED ? @"userSig invalid, please login again.":@"enter trtc room fail.");
        if (self.enterRoomCallback) {
            self.enterRoomCallback((int)result, errorMsg);
        }
    }
    self.enterRoomCallback = nil;
}

- (void)onExitRoom:(NSInteger)reason {
    TRTCLog(@"on exit trtc room. reslut: %ld", (long)reason);
    self.isInRoom = NO;
    if (self.exitRoomCallback) {
        self.exitRoomCallback(0, @"exite room success");
    }
    self.exitRoomCallback = nil;
}

- (void)onRemoteUserEnterRoom:(NSString *)userId {
    TRTCLog(@"on user enter, userid: %@", userId);
    if ([self canDelegateResponseMethod:@selector(onTRTCAnchorEnter:)]) {
        [self.observer onTRTCAnchorEnter:userId];
    }
}

- (void)onRemoteUserLeaveRoom:(NSString *)userId reason:(NSInteger)reason {
    if ([self canDelegateResponseMethod:@selector(onTRTCAnchorExit:)]) {
        [self.observer onTRTCAnchorExit:userId];
    }
}

- (void)onUserAudioAvailable:(NSString *)userId available:(BOOL)available {
    if ([self canDelegateResponseMethod:@selector(onTRTCAudioAvailable:available:)]) {
        [self.observer onTRTCAudioAvailable:userId available:available];
    }
}

- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available {
    if (![userId isEqualToString:self.mixRobotUserId]) {
        return;
    }
    if (available) {
        [self startRemoteVideo:userId];
    }
    else {
        [self stopRemoteVideo:userId];
    }
}

- (void)onError:(TXLiteAVError)errCode errMsg:(NSString *)errMsg extInfo:(NSDictionary *)extInfo{
    if ([self canDelegateResponseMethod:@selector(onError:message:)]) {
        [self.observer onError:errCode message:errMsg];
    }
}

- (void)onNetworkQuality:(TRTCQualityInfo *)localQuality remoteQuality:(NSArray<TRTCQualityInfo *> *)remoteQuality {
    if ([self canDelegateResponseMethod:@selector(onNetWorkQuality:arrayList:)]) {
        [self.observer onNetWorkQuality:localQuality arrayList:remoteQuality];
    }
}

- (void)onUserVoiceVolume:(NSArray<TRTCVolumeInfo *> *)userVolumes totalVolume:(NSInteger)totalVolume {
    if ([self canDelegateResponseMethod:@selector(onUserVoiceVolume:totalVolume:)]) {
        [self.observer onUserVoiceVolume:userVolumes totalVolume:totalVolume];
    }
}

- (void)onSetMixTranscodingConfig:(int)err errMsg:(NSString *)errMsg{
    TRTCLog(@"on set mix transcoding, code:%d, msg: %@", err, errMsg);
}

- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message {
    if ([self canDelegateResponseMethod:@selector(onRecvSEIMsg:message:)]) {
        [self.observer onRecvSEIMsg:userId message:message];
    }
}

- (void)onRecvCustomCmdMsgUserId:(NSString *)userId cmdID:(NSInteger)cmdID seq:(UInt32)seq message:(NSData *)message {
    if (![userId isEqualToString:self.userId] && self.userId.length != 0) {
        /// 观众端需要接收此回调, 用户id不能为空
        [self.chorusExtension onRecvCustomCmdMsgUserId:userId cmdID:cmdID seq:seq message:message];
    }
}

- (void)onStartPublishMediaStream:(NSString *)taskId code:(int)code message:(NSString *)message extraInfo:(nullable NSDictionary *)extraInfo {
    self.mixTaskId = taskId;
    TRTCLog(@"onStartPublishMediaStream, taskId:%@, code: %d, message: %@, extraInfo:%@", taskId, code, message, extraInfo);
}

- (void)onStatistics:(TRTCStatistics *)statistics {
    if ([self canDelegateResponseMethod:@selector(onStatistics:)]) {
        [self.observer onStatistics:statistics];
    }
}
@end

//
//  KaraokeTRTCService.m
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "KaraokeTRTCService.h"
#import "TRTCCloud.h"
#import "ChorusExtension.h"

static NSString *const kAudioBgm = @"_bgm";
static NSString *const kMixRobot = @"_robot";

static const int TC_COMPONENT_KARAOKE = 8;
static const int TC_TRTC_FRAMEWORK    = 1;

@interface KaraokeTRTCService () <TRTCCloudDelegate, ChorusExtensionDelegate>

@property (nonatomic, assign) BOOL isInRoom;

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *roomId;
@property (nonatomic, copy) NSString *mixTaskId;

@property (nonatomic, copy) NSString *mixRobotUserId;
@property (nonatomic, copy) NSString *bgmUserSign;


@property (nonatomic, copy) TXKaraokeCallback enterRoomCallback;
@property (nonatomic, copy) TXKaraokeCallback exitRoomCallback;

@property (nonatomic, strong) TRTCParams *voiceParams;
@property (nonatomic, strong) TRTCParams *bgmParams;

@property (nonatomic, weak) TRTCCloud *voiceCloud;
@property (nonatomic, weak) TRTCCloud *bgmCloud;

@property (nonatomic, strong) ChorusExtension *chorusService;

@end

@implementation KaraokeTRTCService

- (ChorusExtension *)chorusService {
    if (!_chorusService) {
        _chorusService = [[ChorusExtension alloc] init];
        _chorusService.delegate = self;
    }
    return _chorusService;
}

+ (instancetype)sharedInstance{
    static KaraokeTRTCService* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[KaraokeTRTCService alloc] init];
    });
    return instance;
}

- (void)enterRoomWithSdkAppId:(UInt32)sdkAppId
                       roomId:(NSString *)roomId
                       userId:(NSString *)userId
                     userSign:(NSString *)userSign
                         role:(NSInteger)role
                     callback:(TXKaraokeCallback)callback {
    BOOL isParamError = NO;
    if (roomId == nil || [roomId isEqualToString:@""]) {
        isParamError = YES;
    }
    if (userId == nil || [userId isEqualToString:@""]) {
        isParamError = YES;
    }
    if (userSign == nil || [userSign isEqualToString:@""]) {
        isParamError = YES;
    }
    int roomIdIntValue = [roomId intValue];
    if (roomIdIntValue == 0) {
        isParamError = YES;
    }
    if (isParamError) {
        TRTCLog(@"error: enter trtc room fail. params invalid. room id:%@, userId:%@, userSig is empty:%d", roomId, userId, (userSign == nil || [userSign isEqualToString:@""]));
        callback(-1, @"enter trtc room fail.");
        return;
    }
    self.userId = userId;
    self.roomId = roomId;
    self.enterRoomCallback = callback;
    TRTCLog(@"enter room. app id:%u, room id: %@, userID: %@", (unsigned int)sdkAppId, roomId, userId);
    
    self.voiceParams = [[TRTCParams alloc] init];
    self.voiceParams.sdkAppId = sdkAppId;
    self.voiceParams.userId = userId;
    self.voiceParams.userSig = userSign;
    self.voiceParams.role = role == 20 ? TRTCRoleAnchor : TRTCRoleAudience;
    self.voiceParams.roomId = roomIdIntValue;
    self.voiceCloud = [self.chorusService createVoiceTRTCInstanceWith:self.voiceParams];
    
    if (role == TRTCRoleAnchor) {
        NSString *bgmUserId = [NSString stringWithFormat:@"%@%@",userId,kAudioBgm];
        TRTCLog(@"Generate BgmUserId = %@",bgmUserId);
        if (self.delegate && [self.delegate respondsToSelector:@selector(genUserSign:completion:)]) {
            
            __weak typeof(self)weakSelf = self;
            [self.delegate genUserSign:bgmUserId completion:^(NSString * _Nonnull userSign) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                strongSelf.bgmUserSign = userSign;
                
                strongSelf.bgmParams = [[TRTCParams alloc] init];
                strongSelf.bgmParams.sdkAppId = sdkAppId;
                strongSelf.bgmParams.userId = bgmUserId;
                strongSelf.bgmParams.userSig = strongSelf.bgmUserSign;
                strongSelf.bgmParams.role = TRTCRoleAnchor;
                strongSelf.bgmParams.roomId = roomIdIntValue;
                
                strongSelf.bgmCloud = [strongSelf.chorusService createBGMTRTCInstanceWith:strongSelf.bgmParams];
                strongSelf.mixRobotUserId = [NSString stringWithFormat:@"%@%@",roomId, kMixRobot];
                [strongSelf startTRTCPush];
            }];
        }
    }
    [self internalEnterRoom];
}

- (void)startTRTCPush {
    int roomIdIntValue = [self.roomId intValue];
    if (roomIdIntValue == 0) {
        TRTCLog(@"startTRTCPush error roomId is %@",self.roomId);
        return;
    }
    [self.chorusService createMixStreamRobot:self.mixRobotUserId roomId:roomIdIntValue taskId:self.mixTaskId];
}

- (void)exitRoom:(TXKaraokeCallback)callback {
    TRTCLog(@"exit trtc room.");
    self.userId = nil;
    self.voiceParams = nil;
    self.bgmParams = nil;
    self.enterRoomCallback = nil;
    self.exitRoomCallback = callback;
    [self stopMicrophone];
    [self.voiceCloud stopPublishMediaStream:self.mixTaskId];
    [self.chorusService stopChorus];
    self.chorusService = nil;
    self.mixTaskId = nil;
    self.isInRoom = NO;
}

- (void)muteLocalAudio:(BOOL)isMute {
    [self.voiceCloud muteLocalAudio:isMute];
    TRTCLog(@"mute local %d", isMute);
}

- (void)setVoiceEarMonitorEnable:(BOOL)enable {
    [[self.voiceCloud getAudioEffectManager] enableVoiceEarMonitor:enable];
    TRTCLog(@"ear monitor %@", enable ? @"enable" : @"disable");
}

- (void)muteRemoteAudioWithUserId:(NSString *)userId isMute:(BOOL)isMute {
    [self.voiceCloud muteRemoteAudio:userId mute:isMute];
}

- (void)muteAllRemoteAudio:(BOOL)isMute {
    [self.voiceCloud muteAllRemoteAudio:isMute];
}

- (void)startChorus:(NSString *)musicId url:(NSString *)url isOwner:(BOOL)isOwner {
    [self.chorusService startChorus:musicId url:url reason:isOwner ? ChorusStartReasonLocal : ChorusStartReasonRemote];
}

- (void)stopChorus {
    if (self.isInRoom) {
        [self.chorusService stopChorus];
    }
}

- (TXAudioEffectManager *)getVoiceAudioEffectManager {
    return [self.voiceCloud getAudioEffectManager];
}

- (TXAudioEffectManager *)getBGMAudioEffectManager {
    if (self.bgmCloud) {
        return [self.bgmCloud getAudioEffectManager];
    }
    return [self getVoiceAudioEffectManager];
}

- (void)setAudioQuality:(NSInteger)quality {
//    TRTCAudioQuality targetQuality = TRTCAudioQualityDefault;
//    switch (quality) {
//        case 1:
//            targetQuality = TRTCAudioQualitySpeech;
//            break;
//        case 3:
//            targetQuality = TRTCAudioQualityMusic;
//        default:
//            break;
//    }
//    [self.voiceCloud setAudioQuality:targetQuality];
}

- (void)startMicrophone {
    if (self.voiceParams.role == TRTCRoleAnchor) {
        [self.voiceCloud startLocalAudio:TRTCAudioQualityMusic];
    }
}

- (void)stopMicrophone {
    [self.voiceCloud stopLocalAudio];
}

- (void)switchToAnchor {
    self.voiceParams.role = TRTCRoleAnchor;
    [self.voiceCloud switchRole:TRTCRoleAnchor];
    [self startMicrophone];
}

- (void)switchToAudience {
    self.voiceParams.role = TRTCRoleAudience;
    [self stopMicrophone];
    [self.voiceCloud switchRole:TRTCRoleAudience];
}

- (void)setSpeaker:(BOOL)userSpeaker {
    [self.voiceCloud setAudioRoute:userSpeaker ? TRTCAudioModeSpeakerphone : TRTCAudioModeEarpiece];
}

- (void)setAudioCaptureVolume:(NSInteger)volume {
    [self.voiceCloud setAudioCaptureVolume:volume];
}

- (void)setAudioPlayoutVolume:(NSInteger)volume {
    [self.voiceCloud setAudioPlayoutVolume:volume];
}

- (void)startFileDumping:(TRTCAudioRecordingParams *)params {
    [self.voiceCloud startAudioRecording:params];
}

- (void)stopFileDumping {
    [self.voiceCloud stopAudioRecording];
}

- (void)enableAudioEvalutation:(BOOL)enable {
    [self.voiceCloud enableAudioVolumeEvaluation:enable ? 300 : 0];
}

- (void)sendSEIMsg:(NSData *)data {
    BOOL res = [self.voiceCloud sendSEIMsg:data repeatCount:1];
    if (!res) {
        TRTCLog(@"___ send SEI failed");
    }
}

- (void)startRemoteVideo:(NSString *)userId {
    [self.voiceCloud startRemoteView:userId streamType:TRTCVideoStreamTypeSmall view:nil];
}

- (void)stopRemoteVideo:(NSString *)userId {
    [self.voiceCloud stopRemoteView:userId streamType:TRTCVideoStreamTypeSmall];
}

- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available {
    if (available) {
        [self startRemoteVideo:userId];
    }
    else {
        [self stopRemoteVideo:userId];
    }
}

- (void)enableBlackStream:(BOOL)enable size:(CGSize)size {
    NSDictionary *json = @{
        @"api" : @"enableBlackStream",
        @"params" : @{
                @"enable" : @(enable)
        }
    };
    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&err];
    if (!err) {
        NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self.voiceCloud callExperimentalAPI:jsonStr];
    }
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

- (BOOL)canDelegateResponseMethod:(SEL)method {
    return self.delegate && [self.delegate respondsToSelector:method];
}

#pragma mark - ChorusExtensionDelegate
// 合唱已开始
- (void)onChorusStart:(ChorusStartReason)reason message:(NSString *)msg {
    TRTCLog(@"onChorusStart reason = %ld message = %@",reason, msg);
}

// 合唱已停止
- (void)onChorusStop:(ChorusStopReason)reason message:(NSString *)msg {
    TRTCLog(@"onChorusStop reason = %ld message = %@",reason, msg);
}

// 准备播放音乐的回调
- (void)onMusicPrepareToPlay:(int32_t)musicID {
    if ([self canDelegateResponseMethod:@selector(onMusicPrepareToPlay:)]) {
        [self.delegate onMusicPrepareToPlay:musicID];
    }
}

// 音乐播放结束的回调
- (void)onMusicCompletePlaying:(int32_t)musicID {
    if ([self canDelegateResponseMethod:@selector(onMusicCompletePlaying:)]) {
        [self.delegate onMusicCompletePlaying:musicID];
    }
}

// 合唱音乐进度回调
- (void)onMusicProgressUpdate:(int32_t)musicID progress:(NSInteger)progress duration:(NSInteger)durationMS {
    if ([self canDelegateResponseMethod:@selector(onMusicProgressUpdate:progress:duration:)]) {
        [self.delegate onMusicProgressUpdate:musicID progress:progress duration:durationMS];
    }
}

// 接收到发起合唱的消息的回调
- (void)onReceiveAnchorSendChorusMsg:(NSString *)musicID startDelay:(NSInteger)startDelay {
    if ([self canDelegateResponseMethod:@selector(onReceiveAnchorSendChorusMsg:startDelay:)]) {
        [self.delegate onReceiveAnchorSendChorusMsg:musicID startDelay:startDelay];
    }
}

#pragma mark - TRTCCloudDelegate
- (void)onEnterRoom:(NSInteger)result{
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
        [self.delegate onTRTCAnchorEnter:userId];
    }
}

- (void)onRemoteUserLeaveRoom:(NSString *)userId reason:(NSInteger)reason {
    if ([self canDelegateResponseMethod:@selector(onTRTCAnchorExit:)]) {
        [self.delegate onTRTCAnchorExit:userId];
    }
}

- (void)onUserAudioAvailable:(NSString *)userId available:(BOOL)available {
    if ([self canDelegateResponseMethod:@selector(onTRTCAudioAvailable:available:)]) {
        [self.delegate onTRTCAudioAvailable:userId available:available];
    }
}

- (void)onError:(TXLiteAVError)errCode errMsg:(NSString *)errMsg extInfo:(NSDictionary *)extInfo{
    if ([self canDelegateResponseMethod:@selector(onError:message:)]) {
        [self.delegate onError:errCode message:errMsg];
    }
}

- (void)onNetworkQuality:(TRTCQualityInfo *)localQuality remoteQuality:(NSArray<TRTCQualityInfo *> *)remoteQuality {
    if ([self canDelegateResponseMethod:@selector(onNetworkQuality:remoteQuality:)]) {
        [self.delegate onNetWorkQuality:localQuality arrayList:remoteQuality];
    }
}

- (void)onUserVoiceVolume:(NSArray<TRTCVolumeInfo *> *)userVolumes totalVolume:(NSInteger)totalVolume {
    if ([self canDelegateResponseMethod:@selector(onUserVoiceVolume:totalVolume:)]) {
        [self.delegate onUserVoiceVolume:userVolumes totalVolume:totalVolume];
    }
}

- (void)onSetMixTranscodingConfig:(int)err errMsg:(NSString *)errMsg{
    TRTCLog(@"on set mix transcoding, code:%d, msg: %@", err, errMsg);
}

- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message {
    if ([self canDelegateResponseMethod:@selector(onRecvSEIMsg:message:)]) {
        [self.delegate onRecvSEIMsg:userId message:message];
    }
}

- (void)onRecvCustomCmdMsgUserId:(NSString *)userId cmdID:(NSInteger)cmdID seq:(UInt32)seq message:(NSData *)message {
    [self.chorusService onRecvCustomCmdMsgUserId:userId cmdID:cmdID seq:seq message:message];
}

- (void)onStartPublishMediaStream:(NSString *)taskId code:(int)code message:(NSString *)message extraInfo:(nullable NSDictionary *)extraInfo {
    self.mixTaskId = taskId;
    TRTCLog(@"onStartPublishMediaStream, taskId:%@, code: %d, message: %@, extraInfo:%@", taskId, code, message, extraInfo);
}
@end

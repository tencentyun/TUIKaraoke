//
//  ChorusExtension.m
//  TUIKaraoke
//
//  Created by adams on 2022/8/23.
//  Copyright © 2022 tencent. All rights reserved.
//

#import "ChorusExtension.h"
#import "TXLiveBase.h"
#import "TRTCCloud.h"
#import "TXKaraokeBaseDef.h"

//通用宏定义
#define CHORUS_WEAKIFY(x) __weak __typeof(x) weak_##x = x
#define CHORUS_STRONGIFY_OR_RETURN(x) __strong __typeof(weak_##x) x = weak_##x; if (x == nil) {return;};
#define CHORUS_LOG_TAG ChorusExtension

//麦上相关
#define CHORUS_MUSIC_START_DELAY 3000
#define CHORUS_PRELOAD_MUSIC_DELAY 400

//麦下相关
#define CHORUS_SEI_PAYLOAD_TYPE 242

static NSString *const kChorusCmd = @"cmd";
static NSString *const kChorusCmdStart = @"start_chorus";
static NSString *const kChorusCmdStop = @"stop_chorus";
static NSString *const kChorusTimestampPlay = @"start_play_music_ts";
static NSString *const kChorusTimestampStop = @"request_stop_ts";

static NSString *const kChorusMusicTotalTime = @"total_time";
static NSString *const kChorusMusicId = @"music_id";
static NSString *const kChorusMusicCurrentTime = @"current_time";
static NSString *const kChorusMusicDuration = @"music_duration";
static NSString *const kChorusMusicIsOriginMusic = @"is_origin_music";


@interface ChorusExtension()<TXLiveBaseDelegate, TRTCCloudDelegate>
//合唱麦上相关
@property (nonatomic, assign) NSInteger startPlayChorusMusicTs;
@property (nonatomic, assign) NSInteger requestStopChorusTs;
@property (nonatomic, assign) NSInteger startDelayMs;
@property (nonatomic, assign) NSInteger musicDuration;
@property (nonatomic, strong) NSTimer *chorusLongTermTimer;
@property (nonatomic, strong) dispatch_source_t delayStartChorusMusicTimer;
@property (nonatomic, strong) dispatch_source_t preloadMusicTimer;
@property (nonatomic, strong) TXAudioMusicParam *musicParam;
@property (nonatomic, strong) TXAudioMusicParam *accompanyParam;
@property (nonatomic, assign) ChorusStartReason chorusReason;
@property (nonatomic, assign) int32_t currentPlayMusicID;

/// 推送人声实例
@property (nonatomic, weak) TRTCCloud *voiceCloud;
/// 推送背景音乐实例
@property (nonatomic, weak) TRTCCloud *bgmCloud;

@property (nonatomic, assign) BOOL isStartMix;

@end

@implementation ChorusExtension
#pragma mark - lazy property
- (NSTimer *)chorusLongTermTimer {
    if (!_chorusLongTermTimer) {
        __weak typeof(self)weakSelf = self;
        _chorusLongTermTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {return;}
            [strongSelf checkMusicProgress];
            if (strongSelf.chorusReason == ChorusStartReasonLocal) {
                [strongSelf sendStartChorusMsg];
            }
        }];
    }
    return _chorusLongTermTimer;
}

#pragma mark - 初始化相关
- (instancetype)initWithVoiceCloud:(TRTCCloud *)voiceCloud bgmCloud:(TRTCCloud *)bgmCloud {
    self = [super init];
    if (self) {
        TRTCLog(@"ChorusExtension init");
        self.voiceCloud = voiceCloud;
        self.bgmCloud = bgmCloud;
        self.startPlayChorusMusicTs = -1;
        self.requestStopChorusTs = -1;
        self.musicDuration = -1;
        self.currentPlayMusicID = -1;
        self.isStartMix = NO;
        self.isOriginMusic = YES;
        [self.chorusLongTermTimer setFireDate:[NSDate distantFuture]];
        [TXLiveBase updateNetworkTime];
        [TXLiveBase sharedInstance].delegate = self;
    }
    return self;
}

- (void)dealloc {
    TRTCLog(@"ChorusExtension dealloc");
    [self stopChorus];
    [self.chorusLongTermTimer setFireDate:[NSDate distantFuture]];
    [self.chorusLongTermTimer invalidate];
    self.chorusLongTermTimer = nil;
    [self.voiceCloud stopLocalAudio];
    [self.bgmCloud stopLocalAudio];
    self.musicParam = nil;
    self.accompanyParam = nil;
    self.isStartMix = NO;
}

#pragma mark - Public Methods
- (BOOL)startChorus:(NSString *)musicId originalUrl:(NSString *)originalUrl accompanyUrl:(NSString *)accompanyUrl reason:(ChorusStartReason)reason {
    if (![self isNtpReady]) {
        TRTCLog(@"ChorusExtension startChorus failed, ntp is not ready, please call [TXLiveBase updateNetworkTime] first!");
        return NO;
    }
    self.chorusReason = reason;
    self.currentPlayMusicID = [musicId intValue];
    
    NSInteger chorusStartPlayDelay = CHORUS_MUSIC_START_DELAY;
    if (self.chorusReason == ChorusStartReasonLocal) {
        self.startPlayChorusMusicTs = [TXLiveBase getNetworkTimestamp] + CHORUS_MUSIC_START_DELAY;
        // 开启合唱模式（人声）
        [self enableChorusCallExperimentalAPI:self.voiceCloud audioSource:0 enable:YES];
        // 开启合唱模式（背景音乐）
        [self enableChorusCallExperimentalAPI:self.bgmCloud audioSource:1 enable:YES];
        // 开启低延时模式（人声）
        [self enableLowLatencyModeCallExperimentalAPI:self.voiceCloud enable:YES];
        // 开启低延时模式（背景音乐）
        [self enableLowLatencyModeCallExperimentalAPI:self.bgmCloud enable:YES];
    } else {
        chorusStartPlayDelay = self.startDelayMs;
        // 开启合唱模式（人声）
        [self enableChorusCallExperimentalAPI:self.voiceCloud audioSource:0 enable:YES];
        // 开启低延时模式（人声）
        [self enableLowLatencyModeCallExperimentalAPI:self.voiceCloud enable:YES];
    }
    
    TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension startChorus, schedule time:%ld, current_ntp:%ld", self.startPlayChorusMusicTs, [TXLiveBase getNetworkTimestamp]]);
    
    TXAudioMusicParam *param = [[TXAudioMusicParam alloc] init];
    param.ID = self.currentPlayMusicID;
    param.path = originalUrl;
    TRTCLog(@"ChorusStartReason = %ld",reason);
    param.publish = reason == ChorusStartReasonLocal;
    self.musicParam = param;
    
    TXAudioMusicParam *accompanyParam = [[TXAudioMusicParam alloc] init];
    accompanyParam.ID = self.currentPlayMusicID + 1;
    accompanyParam.path = accompanyUrl;
    accompanyParam.publish = reason == ChorusStartReasonLocal;
    self.accompanyParam = accompanyParam;
    
    self.musicDuration = [[self audioEffecManager] getMusicDurationInMS:self.musicParam.path];
    TRTCLog(@"___ chorus: start play: %@", musicId);
    [self.chorusLongTermTimer setFireDate:[NSDate distantPast]];
    [self schedulePlayMusic:chorusStartPlayDelay];
    if (self.chorusReason == ChorusStartReasonLocal) {
        [self sendStartChorusMsg];
    }
    
    // 若成功合唱，通知合唱已开始
    _isChorusOn = YES;
    if (self.chorusReason == ChorusStartReasonLocal) {
        [self asyncDelegate:^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(onChorusStart:message:)]) {
                TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension calling onChorusStart, reason:ChorusStartReasonLocal, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]);
                [self.delegate onChorusStart:ChorusStartReasonLocal message:@"local user launched chorus"];
            }
        }];
    }
    return YES;
}

- (void)stopChorus {
    if (_isChorusOn) {
        switch (self.chorusReason) {
            case ChorusStartReasonLocal:
                [self stopLocalChorus];
                break;
            case ChorusStartReasonRemote:
                [self stopRemoteChorus];
                break;
            default:
                break;
        }
    }
}

- (void)onRecvCustomCmdMsgUserId:(NSString *)userId
                           cmdID:(NSInteger)cmdId
                             seq:(UInt32)seq
                         message:(NSData *)message {
    if (![self isNtpReady]) {//ntp校时为完成，直接返回
        TRTCLog(@"ChorusExtension ignore command, ntp is not ready");
        return;
    }
    
    NSString *msg = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    if(msg == nil) {
        TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension ignore command, userId:%@, msg:%@, current_ntp:%ld", userId, msg, [TXLiveBase getNetworkTimestamp]]);
        return;
    }
    
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[msg dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    if(error) {
        TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension ignore command, userId:%@, json error:%@, current_ntp:%ld", userId, error, [TXLiveBase getNetworkTimestamp]]);
        return;
    }
    
    NSObject *cmdObj = [json objectForKey:kChorusCmd];
    if(![cmdObj isKindOfClass:[NSString class]]) {
        TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension ignore command, userId:%@, cmdObj is not a NSString, current_ntp:%ld", userId, [TXLiveBase getNetworkTimestamp]]);
        return;
    }
    
    
    NSString *musicId = [json objectForKey:kChorusMusicId];
    if ([musicId intValue] == 0) {
        TRTCLog(@"%@", [NSString stringWithFormat:@"TRTCChorus ignore command, userId:%@, musicID is zero, current_ntp:%ld", userId, [TXLiveBase getNetworkTimestamp]]);
        return;
    }
    self.musicDuration = [[json objectForKey:kChorusMusicDuration] integerValue];
    
    NSString *cmd = (NSString *)cmdObj;
    if ([cmd isEqualToString:kChorusCmdStart]) {
        NSObject *startPlayMusicTsObj = [json objectForKey:kChorusTimestampPlay];
        if (!startPlayMusicTsObj || (![startPlayMusicTsObj isKindOfClass:[NSNumber class]])){
            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension ignore start command, userId:%@, startPlayMusicTS not found, current_ntp:%ld", userId, [TXLiveBase getNetworkTimestamp]]);
            return;
        }
        NSInteger startPlayMusicTs = ((NSNumber *)startPlayMusicTsObj).longLongValue;
        if (startPlayMusicTs < self.requestStopChorusTs) {
            //当前收到的命令是在请求停止合唱之前发出的，需要忽略掉，否则会导致请求停止后又开启了合唱
            TRTCLog(@"%@",[NSString stringWithFormat:
            @"ChorusExtension receive kStartChorusMsg that sent before requesting stop, ignore. userId:%@, startPlayMusicTs:%ld, requestStopChorusTs:%ld, current_ntp:%ld",
            userId, startPlayMusicTs, self.requestStopChorusTs, [TXLiveBase getNetworkTimestamp]]);
            return;
        }
        if (self.isChorusOn == NO) {
            NSInteger startDelayMS = startPlayMusicTs - [TXLiveBase getNetworkTimestamp];
            if (startDelayMS <= -self.musicDuration) {
                //若 delayMs 为负数，代表约定的合唱开始时间在当前时刻之前
                //进一步，若 delayMs 为负，并且绝对值大于 BGM 时长，证明此时合唱已经结束了，应当忽略此次消息
                [self clearChorusState];
                TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension ignore command, chorus is over, userId:%@, startPlayMusicTs:%ld current_ntp:%ld", userId, startPlayMusicTs, [TXLiveBase getNetworkTimestamp]]);
                return;
            }
            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension schedule time:%ld, delay:%ld, current_ntp:%ld", startPlayMusicTs, startDelayMS, [TXLiveBase getNetworkTimestamp]]);
            //副唱开始合唱后，也发送 kStartChorusMsg 信令，这样若主唱重进房则可恢复合唱进度
            self.startPlayChorusMusicTs = startPlayMusicTs;
            self.startDelayMs = startDelayMS;
            if (self.chorusReason == ChorusStartReasonLocal) {
                self.chorusReason = ChorusStartReasonRemote;
            }
            [self.chorusLongTermTimer setFireDate:[NSDate distantPast]];
            [self asyncDelegate:^{
                if ([self canDelegateResponseMethod:@selector(onReceiveAnchorSendChorusMsg:startDelay:)]) {
                    [self.delegate onReceiveAnchorSendChorusMsg:musicId startDelay:startDelayMS];
                }
            }];
        }
    } else if ([cmd isEqualToString:kChorusCmdStop]) {
        NSObject *requestStopTsObj = [json objectForKey:kChorusTimestampStop];
        if (!requestStopTsObj || (![requestStopTsObj isKindOfClass:[NSNumber class]])) {
            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension ignore stop command, requestStopTS not found, userId:%@, current_ntp:%ld", userId, [TXLiveBase getNetworkTimestamp]]);
            return;
        }
        self.requestStopChorusTs = ((NSNumber *)requestStopTsObj).longLongValue;
        TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension receive stop command, userId:%@, requestStopTS:%ld, current_ntp:%ld", userId, self.requestStopChorusTs, [TXLiveBase getNetworkTimestamp]]);
        if (self.chorusReason == ChorusStartReasonLocal) {
            self.chorusReason = ChorusStartReasonRemote;
        }
        [self stopChorus];
    }
}

- (void)createMixStreamRobot:(NSString *)userId roomId:(UInt32)roomId taskId:(NSString *)taskId {
    if (!self.bgmCloud) { return; }
    TRTCUser *mixStreamRobot = [[TRTCUser alloc] init];
    //混流机器人的ID
    mixStreamRobot.userId = userId;
    mixStreamRobot.intRoomId = roomId;
    
    TRTCPublishTarget *publishTarget = [[TRTCPublishTarget alloc] init];
    publishTarget.mixStreamIdentity = mixStreamRobot;
    publishTarget.mode = TRTCPublishMixStreamToRoom;
    
    TRTCStreamEncoderParam *streamEncoderParam = [[TRTCStreamEncoderParam alloc] init];
    streamEncoderParam.videoEncodedFPS = 15;
    streamEncoderParam.videoEncodedGOP = 3;
    streamEncoderParam.videoEncodedKbps = 30;
    streamEncoderParam.audioEncodedSampleRate = 48000;
    streamEncoderParam.audioEncodedChannelNum = 2;
    streamEncoderParam.audioEncodedKbps = 64;
    streamEncoderParam.audioEncodedCodecType = 2;
    
    TRTCStreamMixingConfig *streamMixingConfig = [[TRTCStreamMixingConfig alloc] init];
    if (!self.isStartMix) {
        TRTCLog(@"startPublishMediaStream");
        [self.voiceCloud startPublishMediaStream:publishTarget encoderParam:streamEncoderParam mixingConfig:streamMixingConfig];
        self.isStartMix = YES;
    }
    if (taskId && taskId.length > 0) {
        TRTCLog(@"updatePublishMediaStream: %@",taskId);
        [self.voiceCloud updatePublishMediaStream:taskId publishTarget:publishTarget encoderParam:streamEncoderParam mixingConfig:streamMixingConfig];
    }
}

#pragma mark - Private Methods

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

#pragma mark - 停止合唱相关
/// 停止主播端合唱播放
- (void)stopLocalChorus {
    int32_t musicID = self.currentPlayMusicID;
    int32_t accompanyMusicID = musicID + 1;
    //合唱中，清理状态
    self.requestStopChorusTs = [TXLiveBase getNetworkTimestamp];
    [self sendStopChorusMsg];
    TRTCLog(@"___ stopLocalChorus %d", musicID);
    [[self audioEffecManager] stopPlayMusic:musicID];
    [[self audioEffecManager] stopPlayMusic:accompanyMusicID];
    [self clearChorusState];
    _isChorusOn = NO;
    self.currentPlayMusicID = -1;
    self.startPlayChorusMusicTs = -1;
    self.requestStopChorusTs = -1;
    self.startDelayMs = -1;
    // 关闭合唱模式（人声）
    [self enableChorusCallExperimentalAPI:self.voiceCloud audioSource:0 enable:NO];
    // 关闭合唱模式（背景音乐）
    [self enableChorusCallExperimentalAPI:self.bgmCloud audioSource:1 enable:NO];
    // 关闭低延时模式（人声）
    [self enableLowLatencyModeCallExperimentalAPI:self.voiceCloud enable:NO];
    // 关闭低延时模式（背景音乐）
    [self enableLowLatencyModeCallExperimentalAPI:self.bgmCloud enable:NO];
    
    [self asyncDelegate:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(onChorusStop:message:)]) {
            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension calling onChorusStop, reason:ChorusStopReasonLocal, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]);
            [self.delegate onChorusStop:ChorusStopReasonLocal message:@"local user stopped chorus"];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(onMusicCompletePlaying:)]) {
            [self.delegate onMusicCompletePlaying:musicID];
        }
    }];
}

/// 停止副唱端合唱播放
- (void)stopRemoteChorus {
    int32_t musicID = self.currentPlayMusicID;
    int32_t accompanyMusicID = musicID + 1;
    //合唱中，清理状态
    self.requestStopChorusTs = [TXLiveBase getNetworkTimestamp];
    // 关闭合唱模式（人声）
    [self enableChorusCallExperimentalAPI:self.voiceCloud audioSource:0 enable:NO];
    // 关闭低延时模式（人声）
    [self enableLowLatencyModeCallExperimentalAPI:self.voiceCloud enable:NO];
    TRTCLog(@"___ stopRemoteChorus %d", musicID);
    [[self audioEffecManager] stopPlayMusic:musicID];
    [[self audioEffecManager] stopPlayMusic:accompanyMusicID];
    [self clearChorusState];
    _isChorusOn = NO;
    self.currentPlayMusicID = -1;
    self.startPlayChorusMusicTs = -1;
    self.requestStopChorusTs = -1;
    self.startDelayMs = -1;
    [self asyncDelegate:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(onChorusStop:message:)]) {
            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension calling onChorusStop, reason:ChorusStopReasonRemote, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]);
            [self.delegate onChorusStop:ChorusStopReasonRemote message:@"remote user stopped chorus"];
        }
    }];
}

/// 合唱结束清理合唱状态
- (void)clearChorusState {
    if (_delayStartChorusMusicTimer) {
        dispatch_source_cancel(_delayStartChorusMusicTimer);
        _delayStartChorusMusicTimer = nil;
    }
    if (self.preloadMusicTimer) {
        dispatch_source_cancel(self.preloadMusicTimer);
        self.preloadMusicTimer = nil;
    }
    [self.chorusLongTermTimer setFireDate:[NSDate distantFuture]];
}


#pragma mark - 播放音乐方法
- (void)schedulePlayMusic:(NSInteger)delayMs {
    TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension schedulePlayMusic delayMs:%ld, current_ntp:%ld", delayMs, [TXLiveBase getNetworkTimestamp]]);
    CHORUS_WEAKIFY(self);
    TXAudioMusicStartBlock startBlock = ^(NSInteger errCode) {
        CHORUS_STRONGIFY_OR_RETURN(self);
        if (errCode == 0) {
            [self asyncDelegate:^{
                CHORUS_STRONGIFY_OR_RETURN(self);
                if ([self canDelegateResponseMethod:@selector(onMusicPrepareToPlay:)]) {
                    [self.delegate onMusicPrepareToPlay:self.currentPlayMusicID];
                }
            }];
            TRTCLog(@"%@",[NSString stringWithFormat:
            @"ChorusExtension start play music, current_progress:%ld, current_ntp:%ld", [[self
            audioEffecManager] getMusicCurrentPosInMS:self.currentPlayMusicID], [TXLiveBase getNetworkTimestamp]]);
        } else {
            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension start play music failed %ld, current_ntp:%ld", errCode, [TXLiveBase getNetworkTimestamp]]);
            [self clearChorusState];
            self->_isChorusOn = NO;
            self.currentPlayMusicID = -1;
            self.startPlayChorusMusicTs = -1;
            self.startDelayMs = -1;
            [self asyncDelegate:^{
                if (self.delegate && [self.delegate respondsToSelector:@selector(onChorusStop:message:)]) {
                    TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension calling onChorusStop, reason:ChorusStopReasonMusicFailed, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]);
                    [self.delegate onChorusStop:ChorusStopReasonMusicFailed message:@"music start failed"];
                }
            }];
        }
    };
    
    TXAudioMusicProgressBlock progressBlock = ^(NSInteger progressMs, NSInteger durationMs) {
        CHORUS_STRONGIFY_OR_RETURN(self);
        //通知歌曲进度，用户会在这里进行歌词的滚动
        [self asyncDelegate:^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(onMusicProgressUpdate:progress:duration:)]) {
                [self.delegate onMusicProgressUpdate:self.currentPlayMusicID progress:progressMs duration:durationMs];
            }
        }];
        NSDictionary *progressMsg = @{
            kChorusMusicCurrentTime:@([[self audioEffecManager] getMusicCurrentPosInMS:self.currentPlayMusicID]),
            kChorusMusicId: @(self.currentPlayMusicID),
            kChorusMusicTotalTime: @(self.musicDuration),
            kChorusMusicIsOriginMusic: @(self.isOriginMusic),
        };
        NSString *jsonString = [self jsonStringFrom:progressMsg];
        [self.voiceCloud sendSEIMsg:[jsonString dataUsingEncoding:NSUTF8StringEncoding] repeatCount:1];
    };
    
    TXAudioMusicCompleteBlock completedBlock = ^(NSInteger errCode){
        TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension music play completed, errCode:%ld current_ntp:%ld", errCode, [TXLiveBase getNetworkTimestamp]]);
        TRTCLog(@"___ chorus: on complete: %ld", errCode);
        CHORUS_STRONGIFY_OR_RETURN(self);
        //播放完成后停止自定义消息的发送
        [self clearChorusState];
        //通知合唱已结束
        self->_isChorusOn = NO;
        self.startPlayChorusMusicTs = -1;
        self.startDelayMs = -1;
        [self asyncDelegate:^{
            if ([self canDelegateResponseMethod:@selector(onMusicCompletePlaying:)]) {
                [self.delegate onMusicCompletePlaying:self.currentPlayMusicID];
            }
            if ([self canDelegateResponseMethod:@selector(onChorusStop:message:)]) {
                TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension calling onChorusStop, reason:ChorusStopReasonMusicFinished, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]);
                [self.delegate onChorusStop:ChorusStopReasonMusicFinished message:@"chorus music finished playing"];
            }
            self.currentPlayMusicID = -1;
        }];
    };
    
    if (delayMs > 0) {
        [self preloadMusic:self.musicParam.path startMs:0];
        if (!self.delayStartChorusMusicTimer) {
            NSInteger initialTime = [TXLiveBase getNetworkTimestamp];
            self.delayStartChorusMusicTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
             dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
            dispatch_source_set_timer(self.delayStartChorusMusicTimer, DISPATCH_TIME_NOW, DISPATCH_TIME_FOREVER, 0);
            dispatch_source_set_event_handler(self.delayStartChorusMusicTimer, ^{
                while (true) {
                    //轮询，直到当前时间为约定好的播放时间再进行播放，之所以不直接用timer在约定时间执行是由于精度问题，可能会相差几百毫秒
                    CHORUS_STRONGIFY_OR_RETURN(self);
                    if ([TXLiveBase getNetworkTimestamp] > (initialTime + delayMs)) {
                        if(!self->_isChorusOn) {
                            //若达到预期播放时间时，合唱已被停止，则跳过此次播放
                            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension schedulePlayMusic abort, chorus has been stopped, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]);
                            break;
                        }
                        [[self audioEffecManager] startPlayMusic:self.musicParam onStart:startBlock
                         onProgress:progressBlock onComplete:completedBlock];
                        [[self audioEffecManager] startPlayMusic:self.accompanyParam onStart:nil onProgress:nil onComplete:nil];
                        break;
                    }
                }
            });
            dispatch_resume(_delayStartChorusMusicTimer);
        }
    } else {
        [[self audioEffecManager] startPlayMusic:self.musicParam onStart:startBlock onProgress:progressBlock
         onComplete:completedBlock];
        [[self audioEffecManager] startPlayMusic:self.accompanyParam onStart:nil onProgress:nil onComplete:nil];
        if (delayMs < 0) {
            NSInteger startMS = -delayMs + CHORUS_PRELOAD_MUSIC_DELAY;
            [self preloadMusic:self.musicParam.path startMs:startMS];
            if (!self.preloadMusicTimer) {
                NSInteger initialTime = [TXLiveBase getNetworkTimestamp];
                self.preloadMusicTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                 dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
                dispatch_source_set_timer(self.preloadMusicTimer, DISPATCH_TIME_NOW, DISPATCH_TIME_FOREVER, 0);
                dispatch_source_set_event_handler(self.preloadMusicTimer, ^{
                    while (true) {
                        //轮询，直到当前时间为约定时间再执行，之所以不直接用timer在约定时间执行是由于精度问题，可能会相差几百毫秒
                        CHORUS_STRONGIFY_OR_RETURN(self);
                        if ([TXLiveBase getNetworkTimestamp] > (initialTime + CHORUS_PRELOAD_MUSIC_DELAY)) {
                            if(!self->_isChorusOn) {
                                //若达到预期播放时间时，合唱已被停止，则跳过此次播放
                                TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension schedulePlayMusic abort, chorus has been stopped, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]);
                                break;
                            }
                            [[self audioEffecManager] startPlayMusic:self.musicParam onStart:startBlock
                             onProgress:progressBlock onComplete:completedBlock];
                            [[self audioEffecManager] startPlayMusic:self.accompanyParam onStart:nil onProgress:nil onComplete:nil];
                            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension calling startPlayMusic, startMs:%ld, current_ntp:%ld", startMS, [TXLiveBase getNetworkTimestamp]]);
                            break;
                        }
                    }
                });
                dispatch_resume(self.preloadMusicTimer);
            }
        }
    }
}

#pragma mark - 歌曲同步方法
- (void)preloadMusic:(NSString *)path startMs:(NSInteger)startMs {
    TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension preloadMusic, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]);
    NSDictionary *jsonDict = @{
        @"api": @"preloadMusic",
        @"params": @{
                @"musicId": @(self.currentPlayMusicID),
                @"path": path,
                @"startTimeMS": @(startMs),
        }
    };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [self.bgmCloud callExperimentalAPI:jsonString];
}

#pragma mark - 发送合唱信令相关
- (void)sendStartChorusMsg {
    NSDictionary *json = @{
        kChorusCmd: kChorusCmdStart,
        kChorusTimestampPlay: @(self.startPlayChorusMusicTs),
        kChorusMusicId: [NSString stringWithFormat:@"%d",self.currentPlayMusicID],
        kChorusMusicDuration: [NSString stringWithFormat:@"%ld",self.musicDuration],
    };
    NSString *jsonString = [self jsonStringFrom:json];
    [self sendCustomMessage:jsonString reliable:NO];
}

- (void)sendStopChorusMsg {
    NSDictionary *json = @{
        kChorusCmd: kChorusCmdStop,
        kChorusTimestampStop: @(self.requestStopChorusTs),
        kChorusMusicId: [NSString stringWithFormat:@"%d",self.currentPlayMusicID],
    };
    NSString *jsonString = [self jsonStringFrom:json];
    [self sendCustomMessage:jsonString reliable:YES];
}

- (NSString *)jsonStringFrom:(NSDictionary *)dict {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (BOOL)sendCustomMessage:(NSString *)message reliable:(BOOL)reliable {
    NSData * _Nullable data = [message dataUsingEncoding:NSUTF8StringEncoding];
    if (data != nil) {
        return [self.voiceCloud sendCustomCmdMsg:0 data:data reliable:reliable ordered:reliable];
    }
    return NO;
}

- (void)checkMusicProgress {
    if (self.currentPlayMusicID != -1) { //麦下观众不需要进行校准
        NSInteger currentProgress = [[self audioEffecManager] getMusicCurrentPosInMS:self.currentPlayMusicID];
        NSInteger estimatedProgress = [TXLiveBase getNetworkTimestamp] - self.startPlayChorusMusicTs;
        if (estimatedProgress >= 0 && labs(currentProgress - estimatedProgress) > 60) {
            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension checkMusicProgress triggered seek, currentProgress:%ld, estimatedProgress:%ld, current_ntp:%ld", currentProgress, estimatedProgress, [TXLiveBase getNetworkTimestamp]]);
            [[self audioEffecManager] seekMusicToPosInMS:self.currentPlayMusicID pts:estimatedProgress];
            [[self audioEffecManager] seekMusicToPosInMS:self.currentPlayMusicID + 1 pts:estimatedProgress];
        }
    }
}

#pragma mark - NTP校准
- (BOOL)isNtpReady {
    return [TXLiveBase getNetworkTimestamp] > 0;
}

- (TXAudioEffectManager *)audioEffecManager {
    if (self.bgmCloud) {
        return [self.bgmCloud getAudioEffectManager];
    }
    return [self.voiceCloud getAudioEffectManager];
}

- (BOOL)canDelegateResponseMethod:(SEL)method {
    return self.delegate && [self.delegate respondsToSelector:method];
}

- (void)runMainQueue:(void(^)(void))action {
    CHORUS_WEAKIFY(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        CHORUS_STRONGIFY_OR_RETURN(self);
        action();
    });
}

- (void)asyncDelegate:(void(^)(void))block {
    CHORUS_WEAKIFY(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        CHORUS_STRONGIFY_OR_RETURN(self);
        block();
    });
}

#pragma mark - TXLiveBaseDelegate
- (void)onUpdateNetworkTime:(int)errCode message:(NSString *)errMsg {
    // errCode 0 为合适参与合唱；1 建议 UI 提醒当前网络不够好，可能会影响合唱效果；-1 需要重新校时（同样建议 UI 提醒）
    TRTCLog(@"onUpdateNetworkTime: errCode = %ld, message = %@",errCode, errMsg);
    [self asyncDelegate:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(onUpdateNetworkTime:message:retryHandler:)]) {
            [self.delegate onUpdateNetworkTime:errCode message:errMsg retryHandler:^(BOOL shouldRetry) {
                if (shouldRetry && errCode == -1) {
                    [TXLiveBase updateNetworkTime];
                }
            }];
        }
    }];
}

- (void)onLog:(NSString *)log LogLevel:(int)level WhichModule:(NSString *)module {
    
}

- (void)onEnterRoom:(NSInteger)result {
    TRTCLog(@"onEnterRoom: %ld",result);
}

@end

//
//  KaraokeChorusExtension.m
//  TUIKaraoke
//
//  Created by adams on 2022/8/23.
//  Copyright © 2022 tencent. All rights reserved.
//

#import "KaraokeChorusExtension.h"
#import "TXLiteAVSDK_TRTC/TXLiveBase.h"
#import "TXLiteAVSDK_TRTC/TRTCCloud.h"
#import "KaraokeLogger.h"

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


@interface KaraokeChorusExtension()
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

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation KaraokeChorusExtension

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return _dateFormatter;
}

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
- (instancetype)initWithVoiceCloud:(TRTCCloud *)voiceCloud bgmCloud:(nullable TRTCCloud *)bgmCloud {
    self = [super init];
    if (self) {
        TRTCLog(@"ChorusExtension init");
        self.voiceCloud = voiceCloud;
        self.bgmCloud = bgmCloud;
        self.startPlayChorusMusicTs = -1;
        self.requestStopChorusTs = -1;
        self.musicDuration = -1;
        self.currentPlayMusicID = -1;
        self.isOriginMusic = NO;
        [self.chorusLongTermTimer setFireDate:[NSDate distantFuture]];
    }
    return self;
}

- (void)dealloc {
    TRTCLog(@"ChorusExtension dealloc");
    [self stopChorus];
    [self.chorusLongTermTimer setFireDate:[NSDate distantFuture]];
    [self.chorusLongTermTimer invalidate];
    self.chorusLongTermTimer = nil;
    self.musicParam = nil;
    self.accompanyParam = nil;
    self.isOriginMusic = NO;
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
    } else {
        chorusStartPlayDelay = self.startDelayMs;
    }
    
    TRTCLog(@"startChorus: musicId: %@, schedule time: %@, current_ntp: %@",
            musicId,
            [self logTimeIntervalToTime:self.startPlayChorusMusicTs],
            [self logTimeIntervalToTime:[TXLiveBase getNetworkTimestamp]]);
    
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
    [self.chorusLongTermTimer setFireDate:[NSDate distantPast]];
    self.musicDuration = [[self audioEffectManager] getMusicDurationInMS:self.musicParam.path];
    TRTCLog(@"Start Play: %@", musicId);
    [self schedulePlayMusic:chorusStartPlayDelay];
    if (self.chorusReason == ChorusStartReasonLocal) {
        [self sendStartChorusMsg];
    }
    
    // 若成功合唱，通知合唱已开始
    _isChorusOn = YES;
    if (self.chorusReason == ChorusStartReasonLocal) {
        [self asyncDelegate:^{
            if (self.observer && [self.observer respondsToSelector:@selector(onChorusStart:message:)]) {
                TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension calling onChorusStart, reason:ChorusStartReasonLocal, current_ntp:%ld", [TXLiveBase getNetworkTimestamp]]);
                [self.observer onChorusStart:ChorusStartReasonLocal message:@"local user launched chorus"];
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
        
        BOOL isOriginal = [[json  objectForKey:kChorusMusicIsOriginMusic] boolValue];
        if (isOriginal != self.isOriginMusic) {
            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension receive kStartChorusMsg musicId = %@, isOriginal = %d",
                           musicId,
                           isOriginal]);
            [self asyncDelegate:^{
                if ([self canDelegateResponseMethod:@selector(onMusicAccompanimentModeChanged:isOriginal:)]) {
                    [self.observer onMusicAccompanimentModeChanged:musicId isOriginal:isOriginal];
                }
            }];
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
            //副唱开始合唱后，也发送 kStartChorusMsg 信令，这样若主唱重进房则可恢复合唱进度
            self.startPlayChorusMusicTs = startPlayMusicTs;
            self.startDelayMs = startDelayMS;
            if (self.chorusReason == ChorusStartReasonLocal) {
                self.chorusReason = ChorusStartReasonRemote;
            }
            [self.chorusLongTermTimer setFireDate:[NSDate distantPast]];
            [self asyncDelegate:^{
                if ([self canDelegateResponseMethod:@selector(onReceiveAnchorSendChorusMsg:startDelay:)]) {
                    [self.observer onReceiveAnchorSendChorusMsg:musicId startDelay:startDelayMS];
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

#pragma mark - 停止合唱相关
/// 停止主播端合唱播放
- (void)stopLocalChorus {
    int32_t musicID = self.currentPlayMusicID;
    int32_t accompanyMusicID = musicID + 1;
    //合唱中，清理状态
    self.requestStopChorusTs = [TXLiveBase getNetworkTimestamp];
    [self sendStopChorusMsg];
    TRTCLog(@"___ stopLocalChorus %d", musicID);
    [[self audioEffectManager] stopPlayMusic:musicID];
    [[self audioEffectManager] stopPlayMusic:accompanyMusicID];
    [self clearChorusState];
    _isChorusOn = NO;
    self.currentPlayMusicID = -1;
    self.startPlayChorusMusicTs = -1;
    self.requestStopChorusTs = -1;
    self.startDelayMs = -1;
}

/// 停止副唱端合唱播放
- (void)stopRemoteChorus {
    int32_t musicID = self.currentPlayMusicID;
    int32_t accompanyMusicID = musicID + 1;
    //合唱中，清理状态
    self.requestStopChorusTs = [TXLiveBase getNetworkTimestamp];
    TRTCLog(@"___ stopRemoteChorus %d", musicID);
    [[self audioEffectManager] stopPlayMusic:musicID];
    [[self audioEffectManager] stopPlayMusic:accompanyMusicID];
    [self clearChorusState];
    _isChorusOn = NO;
    self.currentPlayMusicID = -1;
    self.startPlayChorusMusicTs = -1;
    self.requestStopChorusTs = -1;
    self.startDelayMs = -1;
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
        TRTCLog(@"%@",[NSString stringWithFormat:
        @"ChorusExtension start play music, current_progress:%ld, current_ntp:%ld errorCode: %ld",
                       [[self audioEffectManager] getMusicCurrentPosInMS:self.currentPlayMusicID],
                       [TXLiveBase getNetworkTimestamp],
                       errCode]);
        if (errCode != 0) {
            [self asyncDelegate:^{
                if (self.observer && [self.observer respondsToSelector:@selector(onMusicPlayError:errorCode:message:)]) {
                    [self.observer onMusicPlayError:self.currentPlayMusicID errorCode:errCode message:@"music start failed"];
                }
            }];
            [self clearChorusState];
            self->_isChorusOn = NO;
            self.currentPlayMusicID = -1;
            self.startPlayChorusMusicTs = -1;
            self.startDelayMs = -1;
        }
    };
    
    TXAudioMusicProgressBlock progressBlock = ^(NSInteger progressMs, NSInteger durationMs) {
        CHORUS_STRONGIFY_OR_RETURN(self);
        //通知歌曲进度，用户会在这里进行歌词的滚动
        [self asyncDelegate:^{
            if (self.observer && [self.observer respondsToSelector:@selector(onMusicProgressUpdate:progress:duration:)]) {
                [self.observer onMusicProgressUpdate:self.currentPlayMusicID progress:progressMs duration:durationMs];
            }
        }];
        
        if (self.bgmCloud) {
            NSDictionary *progressMsg = @{
                kChorusMusicCurrentTime:@([[self audioEffectManager] getMusicCurrentPosInMS:self.currentPlayMusicID]),
                kChorusMusicId: @(self.currentPlayMusicID),
                kChorusMusicTotalTime: @(self.musicDuration),
            };
            NSString *jsonString = [self jsonStringFrom:progressMsg];
            [self.bgmCloud sendSEIMsg:[jsonString dataUsingEncoding:NSUTF8StringEncoding] repeatCount:1];
        }
        
    };
    
    TXAudioMusicCompleteBlock completedBlock = ^(NSInteger errCode){
        TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension music play completed, errCode:%ld current_ntp:%ld", errCode, [TXLiveBase getNetworkTimestamp]]);
        CHORUS_STRONGIFY_OR_RETURN(self);
        //播放完成后停止自定义消息的发送
        [self clearChorusState];
        //通知合唱已结束
        self->_isChorusOn = NO;
        self.startPlayChorusMusicTs = -1;
        self.startDelayMs = -1;
        if ([self canDelegateResponseMethod:@selector(onMusicPlayCompleted:)]) {
            [self.observer onMusicPlayCompleted:self.currentPlayMusicID];
        }
        self.currentPlayMusicID = -1;
    };
    
    if (delayMs > 0) {
        self.musicParam.startTimeMS = 0;
        self.accompanyParam.startTimeMS = 0;
        [self preloadMusic:self.musicParam];
        [self preloadMusic:self.accompanyParam];
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
                        TRTCLog(@"schedulePlayMusic startPlayMusic: current_ntp: %@, musicId: %@",
                                [self logTimeIntervalToTime:[TXLiveBase getNetworkTimestamp]],
                                [NSString stringWithFormat:@"%d",self.musicParam.ID]);
                        [[self audioEffectManager] startPlayMusic:self.musicParam onStart:startBlock
                         onProgress:progressBlock onComplete:completedBlock];
                        [[self audioEffectManager] startPlayMusic:self.accompanyParam onStart:nil onProgress:nil onComplete:nil];
                        break;
                    }
                }
            });
            dispatch_resume(_delayStartChorusMusicTimer);
        }
    } else {
        NSInteger startMS = labs(delayMs) + CHORUS_PRELOAD_MUSIC_DELAY;
        self.musicParam.startTimeMS = startMS;
        self.accompanyParam.startTimeMS = startMS;
        [self preloadMusic:self.musicParam];
        [self preloadMusic:self.accompanyParam];
        TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension schedulePlayMusic startMS: %ld, current_ntp:%ld", startMS, [TXLiveBase getNetworkTimestamp]]);
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
                        TRTCLog(@"schedulePlayMusic startPlayMusic: current_ntp: %@, musicId: %@, start_time: %@",
                                [self logTimeIntervalToTime:[TXLiveBase getNetworkTimestamp]],
                                [NSString stringWithFormat:@"%d",self.musicParam.ID],
                                [self logTimeIntervalToTime:startMS]);
                        [[self audioEffectManager] startPlayMusic:self.musicParam onStart:startBlock
                                                       onProgress:progressBlock onComplete:completedBlock];
                        [[self audioEffectManager] startPlayMusic:self.accompanyParam onStart:nil onProgress:nil onComplete:nil];
                        TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension calling startPlayMusic, startMs:%ld, current_ntp:%ld", startMS, [TXLiveBase getNetworkTimestamp]]);
                        break;
                    }
                }
            });
            dispatch_resume(self.preloadMusicTimer);
        }
    }
}

#pragma mark - 歌曲同步方法
- (void)preloadMusic:(TXAudioMusicParam *)musicParam {
    TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension preloadMusic,musicId: %d, publish: %d, current_ntp:%ld", musicParam.ID, musicParam.publish, [TXLiveBase getNetworkTimestamp]]);
    [[self audioEffectManager] preloadMusic:musicParam
                                 onProgress:^(NSInteger progress) {
        
    } onError:^(NSInteger errorCode) {
        
    }];
}

#pragma mark - 发送合唱信令相关
- (void)sendStartChorusMsg {
    NSDictionary *json = @{
        kChorusCmd: kChorusCmdStart,
        kChorusTimestampPlay: @(self.startPlayChorusMusicTs),
        kChorusMusicId: [NSString stringWithFormat:@"%d",self.currentPlayMusicID],
        kChorusMusicDuration: [NSString stringWithFormat:@"%ld",self.musicDuration],
        kChorusMusicIsOriginMusic: @(self.isOriginMusic),
    };
    TRTCLog(@"sendStartChorusMsg: startNTPTime: %@, musicId: %@",
            [self logTimeIntervalToTime:self.startPlayChorusMusicTs],
            [NSString stringWithFormat:@"%d",self.currentPlayMusicID]);
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
        NSInteger currentProgress = [[self audioEffectManager] getMusicCurrentPosInMS:self.currentPlayMusicID];
        NSInteger estimatedProgress = [TXLiveBase getNetworkTimestamp] - self.startPlayChorusMusicTs;
        if (estimatedProgress >= 0 && labs(currentProgress - estimatedProgress) > 60) {
            TRTCLog(@"%@",[NSString stringWithFormat:@"ChorusExtension checkMusicProgress triggered seek, currentProgress:%ld, estimatedProgress:%ld, current_ntp:%ld", currentProgress, estimatedProgress, [TXLiveBase getNetworkTimestamp]]);
            [[self audioEffectManager] seekMusicToPosInMS:self.currentPlayMusicID pts:estimatedProgress];
            [[self audioEffectManager] seekMusicToPosInMS:self.currentPlayMusicID + 1 pts:estimatedProgress];
        }
    }
}

#pragma mark - NTP校准
- (BOOL)isNtpReady {
    return [TXLiveBase getNetworkTimestamp] > 0;
}

- (TXAudioEffectManager *)audioEffectManager {
    if (self.bgmCloud) {
        return [self.bgmCloud getAudioEffectManager];
    }
    return [self.voiceCloud getAudioEffectManager];
}

- (BOOL)canDelegateResponseMethod:(SEL)method {
    return self.observer && [self.observer respondsToSelector:method];
}

- (void)runMainQueue:(void(^)(void))action {
    dispatch_async(dispatch_get_main_queue(), ^{
        action();
    });
}

- (void)asyncDelegate:(void(^)(void))block {
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}

- (NSString *)logTimeIntervalToTime:(double)timeValue {
    NSTimeInterval time = timeValue / 1000;
    NSDate *detailDate = [NSDate dateWithTimeIntervalSince1970:time];
    NSString *currentDateStr = [self.dateFormatter stringFromDate: detailDate];
    return currentDateStr;
}

@end

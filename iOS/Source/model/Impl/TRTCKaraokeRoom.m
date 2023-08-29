//
//  TRTCKaraokeRoom.m
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "TRTCKaraokeRoom.h"
#import "KaraokeTRTCService.h"
#import "KaraokeIMService.h"
#import "KaraokeIMJsonHandle.h"
#import "KaraokeCommonDef.h"
#import "TUIKaraokeKit.h"
#import "KaraokeLocalized.h"
#import "KaraokeLogger.h"

@interface TRTCKaraokeRoom ()<KaraokeTRTCServiceObserver, KaraokeIMServiceObserver, TXLiveBaseDelegate>

@property (nonatomic,  copy ) NSString *roomID;
@property (nonatomic,  copy ) NSString *userId;
@property (nonatomic,  copy ) NSString *userSign;
@property (nonatomic, assign) UInt32 sdkAppId;

@property (nonatomic, strong) KaraokeTRTCService *rtcService;
@property (nonatomic, strong) KaraokeIMService *imService;

@property (nonatomic, strong) NSMutableArray<KaraokeSeatInfo *> *seatInfoList;
@property (nonatomic, weak) id<TRTCKaraokeRoomObserver> observer;

@property (nonatomic, copy, nullable) KaraokeCallback enterSeatCallback;
@property (nonatomic, copy, nullable) KaraokeCallback leaveSeatCallback;
@property (nonatomic, copy, nullable) KaraokeCallback pickSeatCallback;
@property (nonatomic, copy, nullable) KaraokeCallback kickSeatCallback;

@property (nonatomic, weak) dispatch_queue_t observerQueue;

@property (nonatomic, assign) BOOL isSelfMute;         // 判断自己是否静音
@property (nonatomic, assign) NSInteger takeSeatIndex; // 判断自己是否在麦上

// 音乐播放相关变量
@property (nonatomic, assign) int32_t currentPlayingOriginalMusicID;
@property (nonatomic, assign) BOOL isOriginalMusic;
@property (nonatomic, assign) NSInteger musicVolume;
@property (nonatomic, assign) NSInteger musicTimeStamp;

@end

@implementation TRTCKaraokeRoom

static TRTCKaraokeRoom *gInstance;
static dispatch_once_t gOnceToken;

#pragma mark - private method
- (BOOL)canObserverResponseMethod:(SEL)method {
    return self.observer && [self.observer respondsToSelector:method];
}

- (BOOL)isOnSeatWithUserId:(NSString *)userId {
    if (self.seatInfoList.count == 0) {
        return NO;
    }
    for (KaraokeSeatInfo *seatInfo in self.seatInfoList) {
        if ([seatInfo.user isEqualToString:userId]) {
            return YES;
        }
    }
    return NO;
}

- (void)runMainQueue:(void(^)(void))action {
    dispatch_async(dispatch_get_main_queue(), ^{
        action();
    });
}

- (void)runOnObserverQueue:(void(^)(void))action {
    if (self.observerQueue) {
        dispatch_async(self.observerQueue, ^{
            action();
        });
    }
}

- (void)resetGlobalVariablesToDefault {
    [self.seatInfoList removeAllObjects];
    self.isSelfMute = NO;
    self.currentPlayingOriginalMusicID = -1;
    self.isOriginalMusic = NO;
    self.musicVolume = 60;
    self.takeSeatIndex = -1;
    self.musicTimeStamp = -1;
}

- (void)getAudienceList:(KaraokeUserListCallback _Nullable)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.imService getAudienceList:^(int code, NSString * _Nonnull message, NSArray<KaraokeUserInfo *> * _Nonnull userInfos) {
            TRTCLog(@"get audience list finish, code:%d, message:%@, userListCount:%lu", code, message, (unsigned long)userInfos.count);
            NSMutableArray *userInfoList = [[NSMutableArray alloc] initWithCapacity:2];
            for (KaraokeUserInfo* info in userInfos) {
                [userInfoList addObject:info];
            }
            if (callback) {
                [self runOnObserverQueue:^{
                    callback(code, message, userInfoList);
                }];
            }
        }];
    }];
}

- (void)exitIMRoom:(KaraokeCallback)callback {
    TRTCLog(@"start exit im room");
    @weakify(self)
    [self.imService exitRoom:^(int code, NSString * _Nonnull message) {
        @strongify(self)
        if (!self) { return; }
        if (callback) {
            [self runOnObserverQueue:^{
                callback(code, message);
            }];
        }
        [self resetGlobalVariablesToDefault];
        self.roomID = @"";
    }];
}

#pragma mark - TRTCKaraoke 实现
- (instancetype)init {
    self = [super init];
    if (self) {
        TRTCLog(@"TRTCKaraokeRoom init");
        self.imService = [[KaraokeIMService alloc] init];
        self.rtcService = [[KaraokeTRTCService alloc] init];
        self.imService.observer = self;
        self.rtcService.observer = self;
        self.observerQueue = dispatch_get_main_queue();
        self.seatInfoList = [[NSMutableArray alloc] initWithCapacity:2];
        self.takeSeatIndex = -1;
        self.isSelfMute = NO;
        self.currentPlayingOriginalMusicID = -1;
        self.isOriginalMusic = NO;
        self.musicVolume = 60;
        self.takeSeatIndex = -1;
        self.musicTimeStamp = -1;
        [TXLiveBase sharedInstance].delegate = self;
    }
    return self;
}

+ (instancetype)sharedInstance {
    TRTCLog(@"sharedInstance");
    dispatch_once(&gOnceToken, ^{
        gInstance = [[TRTCKaraokeRoom alloc] init];
        TRTCLog(@"sharedInstance = %@", gInstance);
    });
    return gInstance;
}

+ (void)destroySharedInstance {
    TRTCLog(@"destroySharedInstance = %@", gInstance);
    gOnceToken = 0;
    gInstance = nil;
}

- (void)setObserver:(id<TRTCKaraokeRoomObserver>)observer {
    TRTCLog(@"setObserver: %@", observer);
    self->_observer = observer;
}

- (void)setObserverQueue:(dispatch_queue_t)queue {
    TRTCLog(@"setObserverQueue: %@", queue);
    self->_observerQueue = queue;
}

- (void)dealloc {
    TRTCLog(@"%@ dealloc", NSStringFromClass(self.class));
}

- (void)login:(int)sdkAppID userId:(NSString *)userId userSig:(NSString *)userSig callback:(KaraokeCallback)callback {
    TRTCLog(@"login: sdkAppID: %d userId: %@", sdkAppID, userId);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        if (sdkAppID != 0 && userId && ![userId isEqualToString:@""] && userSig && ![userSig isEqualToString:@""]) {
            self.sdkAppId = sdkAppID;
            self.userId = userId;
            self.userSign = userSig;
            TRTCLog(@"start login room service");
            [self.imService loginWithSdkAppId:sdkAppID userId:userId userSig:userSig callback:^(int code, NSString * _Nonnull message) {
                @strongify(self)
                if (!self) { return; }
                if (callback) {
                    [self runOnObserverQueue:^{
                        callback(code, message);
                    }];
                }
            }];
        } else {
            TRTCLog(@"start login failed. params invalid.");
            callback(-1, @"start login failed. params invalid.");
        }
    }];
}

- (void)logout:(KaraokeCallback)callback {
    TRTCLog(@"logout");
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        TRTCLog(@"start logout imservice");
        self.sdkAppId = 0;
        self.userId = @"";
        self.userSign = @"";
        [self.imService logout:^(int code, NSString * _Nonnull message) {
            if (callback) {
                [self runOnObserverQueue:^{
                    callback(code, message);
                }];
            }
        }];
    }];
}

- (void)setSelfProfile:(NSString *)userName avatarURL:(NSString *)avatarURL callback:(KaraokeCallback)callback {
    TRTCLog(@"setSelfProfile userName = %@, avatarURL = %@", userName, avatarURL);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.imService setSelfProfileWithUserName:userName avatarUrl:avatarURL callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            if (callback) {
                [self runOnObserverQueue:^{
                    callback(code, message);
                }];
            }
        }];
    }];
}

- (void)updateNetworkTime {
    TRTCLog(@"updateNetworkTime");
    [TXLiveBase updateNetworkTime];
}

- (void)createRoom:(int)roomID roomParam:(KaraokeRoomParam *)roomParam callback:(KaraokeCallback)callback {
    TRTCLog(@"createRoom roomID = %d, roomName = %@, coverUrl = %@,  needRequest = %d, seatCount = %ld",
            roomID,
            roomParam.roomName,
            roomParam.coverUrl,
            roomParam.needRequest,
            roomParam.seatCount);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        if (roomID == 0) {
            TRTCLog(@"create room fail. params invalid.");
            if (callback) {
                callback(-1, @"create room fail. parms invalid.");
            }
            return;
        }
        self.roomID = [NSString stringWithFormat:@"%d", roomID];
        NSString* roomName = roomParam.roomName;
        NSString* roomCover = roomParam.coverUrl;
        BOOL isNeedrequest = roomParam.needRequest;
        NSInteger seatCount = roomParam.seatCount;
        if (roomParam.seatInfoList.count > 0) {
            for (KaraokeSeatInfo* info in roomParam.seatInfoList) {
                [self.seatInfoList addObject:info];
            }
        } else {
            for (int index = 0; index < seatCount; index += 1) {
                KaraokeSeatInfo* info = [[KaraokeSeatInfo alloc] init];
                [self.seatInfoList addObject:info];
            }
        }
        [self.imService createRoomWithRoomId:self.roomID
                                        roomName:roomName
                                        coverUrl:roomCover
                                     needRequest:isNeedrequest
                                    seatInfoList:self.seatInfoList
                                        callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            if (code != 0) {
                [self runOnObserverQueue:^{
                    if ([self canObserverResponseMethod:@selector(onError:message:)]) {
                        [self.observer onError:code message:message];
                    }
                }];
            }
            if (callback) {
                callback(code, message);
            }
        }];
    }];
}

- (void)destroyRoom:(KaraokeCallback)callback {
    TRTCLog(@"destroyRoom");
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        // 在公开群（Public）、会议（Meeting）和直播群（AVChatRoom）中，群主是不可以退群的，群主只能调用 dismissGroup 解散群组。
        [self.imService destroyRoom:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            TRTCLog(@"destroy room finish, code:%d, message: %@", code, message);
            if (callback) {
                [self runOnObserverQueue:^{
                    callback(code, message);
                }];
            }
        }];
        [self resetGlobalVariablesToDefault];
    }];
}

- (void)enterRoom:(int)roomID callback:(KaraokeCallback)callback {
    TRTCLog(@"enterRoom: roomID = %ld", roomID);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        self.roomID = [NSString stringWithFormat:@"%ld", (long)roomID];
        [self.imService enterRoom:self.roomID callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            if (code != 0) {
                [self runOnObserverQueue:^{
                    @strongify(self)
                    if (!self) { return; }
                    if ([self canObserverResponseMethod:@selector(onError:message:)]) {
                        [self.observer onError:code message:message];
                    }
                }];
            } else {
                TRTCRoleType roleType = TRTCRoleAnchor;
                if (!self.imService.isOwner) {
                    roleType = TRTCRoleAudience;
                }
                [self.rtcService updateOwnerId:self.imService.ownerUserId];
                [self.rtcService enterRoomWithSdkAppId:self.sdkAppId
                                                roomId:roomID
                                                userId:self.userId
                                              userSign:self.userSign
                                                  role:roleType
                                              callback:^(int code, NSString * _Nonnull message) {
                    @strongify(self)
                    if (!self) { return; }
                    if (callback) {
                        [self runOnObserverQueue:^{
                            callback(code, message);
                        }];
                    }
                }];
            }
        }];
    }];
}

- (void)exitRoom:(KaraokeCallback)callback {
    TRTCLog(@"exitRoom");
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        TRTCLog(@"start exit trtc room");
        [self stopPlayMusic];
        [self.rtcService exitRoom:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            if (code != 0) {
                [self runOnObserverQueue:^{
                    if ([self canObserverResponseMethod:@selector(onError:message:)]) {
                        [self.observer onError:code message:message];
                    }
                }];
            }
        }];
        
        if (self.imService.isOwner) {
            if (callback) {
                callback(0, @"exit trtc room success");
            }
        } else {
            if ([self isOnSeatWithUserId:self.userId]) {
                [self leaveSeat:^(int code, NSString * _Nonnull message) {
                    @strongify(self)
                    if (!self) { return; }
                    [self exitIMRoom:callback];
                }];
            } else {
                [self exitIMRoom:callback];
            }
        }
    }];
}

- (void)getRoomInfoList:(NSArray<NSNumber *> *)roomIdList callback:(KaraokeRoomInfoListCallback)callback {
    TRTCLog(@"getRoomInfoList roomIdListCount = %ld", roomIdList.count);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        TRTCLog(@"start get room info:%@", roomIdList);
        NSMutableArray* roomIds = [[NSMutableArray alloc] initWithCapacity:2];
        for (NSNumber *roomId in roomIdList) {
            [roomIds addObject:[roomId stringValue]];
        }
        [self.imService getRoomInfoList:roomIds
                                calback:^(int code, NSString * _Nonnull message,
                                          NSArray<KaraokeRoomInfo *> * _Nonnull roomInfos) {
            if (code == 0) {
                TRTCLog(@"roomInfos: %@", roomInfos);
                NSMutableArray* trtcRoomInfos = [[NSMutableArray alloc] initWithCapacity:2];
                for (KaraokeRoomInfo *info in roomInfos) {
                    if ([info.roomId integerValue] != 0) {
                        [trtcRoomInfos addObject:info];
                    }
                }
                if (callback) {
                    callback(code, message, trtcRoomInfos);
                }
            } else {
                if (callback) {
                    callback(code, message, @[]);
                }
            }
        }];
    }];
}

- (void)getUserInfoList:(NSArray<NSString *> *)userIDList callback:(KaraokeUserListCallback)callback {
    TRTCLog(@"getUserInfoList userIDList.count = %ld", userIDList.count);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        if (!userIDList) {
            [self getAudienceList:callback];
            return;
        }
        [self.imService getUserInfo:userIDList callback:^(int code, NSString * _Nonnull
         message, NSArray<KaraokeUserInfo *> * _Nonnull userInfos) {
            @strongify(self)
            if (!self) { return; }
            [self runOnObserverQueue:^{
                @strongify(self)
                if (!self) {
                    return;
                }
                NSMutableArray* userList = [[NSMutableArray alloc] initWithCapacity:2];
                [userInfos enumerateObjectsUsingBlock:^(KaraokeUserInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [userList addObject:obj];
                }];
                if (callback) {
                    callback(code, message, userList);
                }
            }];
        }];
    }];
}

- (void)enterSeat:(NSInteger)seatIndex callback:(KaraokeCallback)callback {
    TRTCLog(@"enterSeat seatIndex = %ld", seatIndex);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self isOnSeatWithUserId:self.userId]) {
            [self runOnObserverQueue:^{
                if (callback) {
                    callback(-1, @"you are alread in the seat.");
                }
            }];
            return;
        }
        self.enterSeatCallback = callback;
        [self.imService takeSeat:seatIndex callback:^(int code, NSString * _Nonnull message) {
            if (code == 0) {
                TRTCLog(@"take seat callback success, and wait attrs changed");
            } else {
                self.enterSeatCallback = nil;
                self.takeSeatIndex = -1;
                if (callback) {
                    callback(code, message);
                }
            }
        }];
    }];
}

- (void)leaveSeat:(KaraokeCallback)callback {
    TRTCLog(@"leaveSeat");
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        if (self.takeSeatIndex == -1) {
            [self runOnObserverQueue:^{
                callback(-1, @"you are not in the seat.");
            }];
            return;
        }
        self.leaveSeatCallback = callback;
        [self.imService leaveSeat:self.takeSeatIndex callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            if (code == 0) {
                TRTCLog(@"levae seat success. and wait attrs changed");
            } else {
                self.leaveSeatCallback = nil;
                if (callback) {
                    callback(code, message);
                }
            }
        }];
    }];
}

- (void)pickSeat:(NSInteger)seatIndex userId:(NSString *)userId callback:(KaraokeCallback)callback {
    TRTCLog(@"pickSeat seatIndex = %ld, userId = %@", seatIndex, userId);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self isOnSeatWithUserId:userId]) {
            [self runOnObserverQueue:^{
                if (callback) {
                    callback(-1, karaokeLocalize(@"Demo.TRTC.Salon.userisspeaker"));
                }
            }];
            return;
        }
        self.pickSeatCallback = callback;
        [self.imService pickSeat:seatIndex userId:userId callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            if (code == 0) {
                TRTCLog(@"pick seat calback success. and wait attrs changed.");
            } else {
                self.pickSeatCallback = nil;
                if (callback) {
                    callback(code, message);
                }
            }
        }];
    }];
}

- (void)kickSeat:(NSInteger)seatIndex callback:(KaraokeCallback)callback {
    TRTCLog(@"kickSeat seatIndex = %ld", seatIndex);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        self.kickSeatCallback = callback;
        [self.imService kickSeat:seatIndex callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            if (code == 0) {
                TRTCLog(@"kick seat calback success. and wait attrs changed.");
            } else {
                self.kickSeatCallback = nil;
                if (callback) {
                    callback(code, message);
                }
            }
        }];
    }];
}

- (void)muteSeat:(NSInteger)seatIndex isMute:(BOOL)isMute callback:(KaraokeCallback)callback {
    TRTCLog(@"muteSeat seatIndex = %ld, isMute = %d", seatIndex, isMute);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.imService muteSeat:seatIndex mute:isMute callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            [self runOnObserverQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (void)closeSeat:(NSInteger)seatIndex isClose:(BOOL)isClose callback:(KaraokeCallback)callback {
    TRTCLog(@"closeSeat seatIndex = %ld, isClose = %d", seatIndex, isClose);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.imService closeSeat:seatIndex isClose:isClose callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            [self runOnObserverQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (void)startMicrophone {
    TRTCLog(@"startMicrophone");
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.rtcService startMicrophone];
    }];
}

- (void)stopMicrophone {
    TRTCLog(@"stopMicrophone");
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.rtcService stopMicrophone];
    }];
}

- (void)muteLocalAudio:(BOOL)mute {
    TRTCLog(@"muteLocalAudio mute = %d", mute);
    self.isSelfMute = mute;
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.rtcService muteLocalAudio:mute];
    }];
}

- (void)muteRemoteAudio:(NSString *)userId mute:(BOOL)mute {
    TRTCLog(@"muteRemoteAudio userId = %@, mute = %d", userId, mute);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.rtcService muteRemoteAudioWithUserId:userId isMute:mute];
    }];
}

- (void)muteAllRemoteAudio:(BOOL)isMute {
    TRTCLog(@"muteAllRemoteAudio isMute = %d", isMute);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.rtcService muteAllRemoteAudio:isMute];
    }];
}

- (TXAudioEffectManager *)getVoiceAudioEffectManager {
    return [self.rtcService getVoiceAudioEffectManager];
}

- (TXAudioEffectManager *)getMusicAudioEffectManager {
    return [self.rtcService getMusicAudioEffectManager];
}

- (void)sendRoomTextMsg:(NSString *)message callback:(KaraokeCallback)callback {
    TRTCLog(@"sendRoomTextMsg: message = %@", message);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.imService sendRoomTextMsg:message callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            [self runOnObserverQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (void)sendRoomCustomMsg:(NSString *)cmd message:(NSString *)message callback:(KaraokeCallback)callback {
    TRTCLog(@"sendRoomCustomMsg: cmd = %@, message = %@", cmd, message);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.imService sendRoomCustomMsg:cmd message:message callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            [self runOnObserverQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (NSString *)sendInvitation:(NSString *)cmd userId:(NSString *)userId content:(NSString *)content callback:(KaraokeCallback)callback {
    TRTCLog(@"sendInvitation: cmd = %@, userId = %@, content = %@", cmd, userId, content);
    @weakify(self)
    return [self.imService sendInvitation:cmd userId:userId content:content callback:^(int code, NSString * _Nonnull message) {
        @strongify(self)
        if (!self) { return; }
        [self runOnObserverQueue:^{
            if (callback) {
                callback(code, message);
            }
        }];
    }];
}

- (void)acceptInvitation:(NSString *)identifier callback:(KaraokeCallback)callback {
    TRTCLog(@"acceptInvitation: identifier = %@", identifier);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.imService acceptInvitation:identifier callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            [self runOnObserverQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (void)rejectInvitation:(NSString *)identifier callback:(KaraokeCallback)callback {
    TRTCLog(@"rejectInvitation: identifier = %@", identifier);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.imService rejectInvitaiton:identifier callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            [self runOnObserverQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (void)cancelInvitation:(NSString *)identifier callback:(KaraokeCallback)callback {
    TRTCLog(@"cancelInvitation: identifier = %@", identifier);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self.imService cancelInvitation:identifier callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) { return; }
            [self runOnObserverQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (NSString *)dictionaryToJson:(NSDictionary *)dic {
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)sendSEIMsg:(NSDictionary *)json {
    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&err];
    if (err == nil) {
        [self.rtcService sendSEIMsg:data];
    }
}

#pragma mark - Music & Music Volume Method
- (void)switchMusicAccompanimentMode:(BOOL)isOriginal {
    if (self.currentPlayingOriginalMusicID == -1) {
        TRTCLog(@"ktv: Music playing status error");
        return;
    }
    if (self.isOriginalMusic == isOriginal) { return; }
    TRTCLog(@"ktv: switch to %@, self.isOriginalMusic: %d, isOriginal: %d",isOriginal ? @"original" : @"accompany", self.isOriginalMusic, isOriginal);
    self.isOriginalMusic = isOriginal;
    [self.rtcService switchMusicAccompanimentMode:isOriginal];
    [self updateMusicVolumeInner];
    if ([self canObserverResponseMethod:@selector(onMusicAccompanimentModeChanged:isOrigin:)]) {
        NSString *musicId = [NSString stringWithFormat:@"%d", self.currentPlayingOriginalMusicID];
        [self.observer onMusicAccompanimentModeChanged:musicId isOrigin:isOriginal];
    }
}

- (void)updateMusicVolume:(NSInteger)musicVolume {
    TRTCLog(@"updateMusicVolume: musicVolume = %ld", musicVolume);
    if (self.currentPlayingOriginalMusicID == -1) return;
    if (musicVolume < 0) {
        musicVolume = 0;
    } else if (musicVolume > 100) {
        musicVolume = 100;
    }
    self.musicVolume = musicVolume;
    [self updateMusicVolumeInner];
}

- (void)updateMusicVolumeInner {
    // 原唱
    [[self getMusicAudioEffectManager] setMusicPlayoutVolume:self.currentPlayingOriginalMusicID
                                                      volume:self.isOriginalMusic ? self.musicVolume : 0];
    [[self getMusicAudioEffectManager] setMusicPublishVolume:self.currentPlayingOriginalMusicID
                                                      volume:(self.isOriginalMusic ? self.musicVolume : 0) * 0.9];
    
    // 伴奏
    [[self getMusicAudioEffectManager] setMusicPlayoutVolume:self.currentPlayingOriginalMusicID + 1
                                                      volume:self.isOriginalMusic ? 0 : self.musicVolume];
    [[self getMusicAudioEffectManager] setMusicPublishVolume:self.currentPlayingOriginalMusicID + 1
                                                      volume:(self.isOriginalMusic ? 0 : self.musicVolume) * 0.9];
}

- (void)enableVoiceEarMonitor:(BOOL)enable {
    TRTCLog(@"enableVoiceEarMonitor: enable = %d", enable);
    [[self getVoiceAudioEffectManager] enableVoiceEarMonitor:enable];
}

- (void)setVoiceVolume:(NSInteger)voiceVolume {
    TRTCLog(@"setVoiceVolume: voiceVolume = %ld", voiceVolume);
    [[self getVoiceAudioEffectManager] setVoiceVolume:voiceVolume];
    [[self getVoiceAudioEffectManager] setVoiceEarMonitorVolume:voiceVolume];
}

- (void)setMusicPitch:(double)musicPitch {
    TRTCLog(@"setMusicPitch: musicPitch = %f", musicPitch);
    if (self.currentPlayingOriginalMusicID == -1) return;
    // 原唱
    [[self getMusicAudioEffectManager] setMusicPitch:self.currentPlayingOriginalMusicID pitch: musicPitch];
    // 伴奏
    [[self getMusicAudioEffectManager] setMusicPitch:self.currentPlayingOriginalMusicID + 1 pitch: musicPitch];
}

- (void)setVoiceReverbType:(NSInteger)reverbType {
    TRTCLog(@"setVoiceReverbType: reverbType = %ld", reverbType);
    [[self getVoiceAudioEffectManager] setVoiceReverbType:reverbType];
}

- (void)setVoiceChangerType:(NSInteger)changerType {
    TRTCLog(@"setVoiceChangerType: changerType = %ld", changerType);
    [[self getVoiceAudioEffectManager] setVoiceChangerType:changerType];
}

- (void)startPlayMusic:(int32_t)musicID originalUrl:(nonnull NSString *)originalUrl accompanyUrl:(nonnull NSString *)accompanyUrl {
    TRTCLog(@"startPlayMusic: musicID = %d, originalUrl = %@, accompanyUrl = %@", musicID, originalUrl, accompanyUrl);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (self.currentPlayingOriginalMusicID == musicID) return;
        
        self.currentPlayingOriginalMusicID = musicID;
        TRTCLog(@"ktv: start play: %d", self.currentPlayingOriginalMusicID);
        [self.rtcService startChorus:[NSString stringWithFormat:@"%d",musicID]
                             originalUrl:originalUrl
                            accompanyUrl:accompanyUrl
                                 isOwner:self.imService.isOwner];
        if ([accompanyUrl isEqualToString:@""]) {
            [self switchMusicAccompanimentMode:YES];
        }
        // 这里开始播放歌曲前判断一下当前是原声还是伴奏
        [self updateMusicVolumeInner];
    }];
}

- (void)stopPlayMusic {
    TRTCLog(@"stopPlayMusic");
    @weakify(self)
    self.currentPlayingOriginalMusicID = -1;
    self.musicTimeStamp = -1;
    [self runMainQueue:^{
        @strongify(self)
        [self.rtcService stopChorus];
    }];
}

- (void)pausePlayMusic {
    TRTCLog(@"pausePlayMusic");
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (self.currentPlayingOriginalMusicID != 0) {
            [[self getMusicAudioEffectManager] pausePlayMusic:self.currentPlayingOriginalMusicID];
            [[self getMusicAudioEffectManager] pausePlayMusic:self.currentPlayingOriginalMusicID + 1];
        }
    }];
}

- (void)resumePlayMusic {
    TRTCLog(@"resumePlayMusic");
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (self.currentPlayingOriginalMusicID != 0) {
            [[self getMusicAudioEffectManager] resumePlayMusic:self.currentPlayingOriginalMusicID];
            [[self getMusicAudioEffectManager] resumePlayMusic:self.currentPlayingOriginalMusicID + 1];
        }
    }];
}

#pragma mark - TXLiveBaseDelegate
- (void)onUpdateNetworkTime:(int)errCode message:(NSString *)errMsg {
    // errCode 0 为合适参与合唱；1 建议 UI 提醒当前网络不够好，可能会影响合唱效果；-1 需要重新校时（同样建议 UI 提醒）
    TRTCLog(@"onUpdateNetworkTime: errCode = %ld, message = %@",errCode, errMsg);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if ([self canObserverResponseMethod:@selector(onUpdateNetworkTime:message:retryHandler:)]) {
            [self.observer onUpdateNetworkTime:errCode message:errMsg retryHandler:^(BOOL shouldRetry) {
                @strongify(self)
                if (shouldRetry && errCode == -1) {
                    [self updateNetworkTime];
                }
            }];
        }
    }];
}

#pragma mark - KaraokeTRTCServiceObserver

- (void)onStatistics:(TRTCStatistics *)statistics {
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if ([self canObserverResponseMethod:@selector(onStatistics:)]) {
            [self.observer onStatistics:statistics];
        }
    }];
}

- (void)onMusicProgressUpdate:(int32_t)musicID progress:(NSInteger)progress duration:(NSInteger)durationMS {
    self.musicTimeStamp = progress;
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if ([self canObserverResponseMethod:@selector(onMusicProgressUpdate:progress:total:)]) {
            [self.observer onMusicProgressUpdate:musicID progress:progress total:durationMS];
        }
    }];
}

- (void)onMusicPlayError:(int32_t)musicID errorCode:(NSInteger)errorCode message:(NSString *)message {
    TRTCLog(@"onMusicPlayError:  errorCode = %ld, message = %@",errorCode, message);
    self.currentPlayingOriginalMusicID = -1;
    self.musicTimeStamp = -1;
}

- (void)onMusicPlayCompleted:(int32_t)musicID {
    TRTCLog(@"onMusicPlayCompleted musicID = %d", musicID);
    self.currentPlayingOriginalMusicID = -1;
    self.musicTimeStamp = -1;
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if ([self canObserverResponseMethod:@selector(onMusicPlayCompleted:)]) {
            [self.observer onMusicPlayCompleted:musicID];
        }
    }];
}

- (void)genUserSign:(NSString *)userId completion:(void (^)(NSString *userSign))completion {
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(genUserSign:completion:)]) {
            [self.observer genUserSign:userId completion:completion];
        }
    }];
}

- (void)onTRTCAnchorEnter:(NSString *)userId {
    TRTCLog(@"onTRTCAnchorEnter userId = %@", userId);
}

- (void)onTRTCAnchorExit:(NSString *)userId {
    TRTCLog(@"onTRTCAnchorExit userId = %@", userId);
    if (self.imService.isOwner) {
        if (self.seatInfoList.count > 0) {
            NSInteger kickSeatIndex = -1;
            for (int i = 0; i < self.seatInfoList.count; i+=1) {
                if ([userId isEqualToString:self.seatInfoList[i].user]) {
                    kickSeatIndex = i;
                    break;
                }
            }
            if (kickSeatIndex != -1) {
                [self kickSeat:kickSeatIndex callback:nil];
            }
        }
    }
}

- (void)onError:(NSInteger)code message:(NSString *)message {
    TRTCLog(@"onError code = %ld, message = %@", code, message);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onError:message:)]) {
            [self.observer onError:(int)code message:message];
        }
    }];
}

- (void)onNetWorkQuality:(TRTCQualityInfo *)trtcQuality arrayList:(NSArray<TRTCQualityInfo *> *)arrayList {
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self canObserverResponseMethod:@selector(onNetWorkQuality:arrayList:)]) {
            [self.observer onNetWorkQuality:trtcQuality arrayList:arrayList];
        }
    }];

}

- (void)onUserVoiceVolume:(NSArray<TRTCVolumeInfo *> *)userVolumes totalVolume:(NSInteger)totalVolume {
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onUserVolumeUpdate:totalVolume:)]) {
            [self.observer onUserVolumeUpdate:userVolumes totalVolume:totalVolume];
        }
    }];
}

- (void)onTRTCAudioAvailable:(NSString *)userId available:(BOOL)available {
    TRTCLog(@"onTRTCAudioAvailable userId = %@, available = %d", userId, available);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onUserMicrophoneMute:mute:)]) {
            [self.observer onUserMicrophoneMute:userId mute:!available];
        }
    }];
}

- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message {
    @weakify(self)
    NSError *err = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:message options:NSJSONReadingMutableContainers error:&err];
    if (err || ![dic isKindOfClass:[NSDictionary class]]) {
        TRTCLog(@"ktv: recv SEI class failed");
        return;
    }
    if ([dic.allKeys containsObject:@"music_id"] && [dic.allKeys containsObject:@"total_time"] && [dic.allKeys containsObject:@"current_time"]) {
        [self runOnObserverQueue:^{
            @strongify(self)
            if ([self canObserverResponseMethod:@selector(onMusicProgressUpdate:progress:total:)] && self.takeSeatIndex == -1) {
                [self.observer onMusicProgressUpdate:[dic[@"music_id"] intValue] progress:[dic[@"current_time"] doubleValue] total:[dic[@"total_time"] doubleValue]];
            }
        }];
    }
}

- (void)onReceiveAnchorSendChorusMsg:(NSString *)musicID startDelay:(NSInteger)startDelay {
    @weakify(self)
    if (self.takeSeatIndex == -1) { return; }
    [self runOnObserverQueue:^{
        @strongify(self)
        if ([self canObserverResponseMethod:@selector(onReceiveAnchorSendChorusMsg:startDelay:)]) {
            [self.observer onReceiveAnchorSendChorusMsg:musicID startDelay:startDelay];
        }
    }];
}

- (void)onMusicAccompanimentModeChanged:(NSString *)musicID isOriginal:(BOOL)isOriginal {
    if (self.takeSeatIndex == -1) { return; }
    if (!self.imService.isOwner && self.currentPlayingOriginalMusicID == musicID.intValue) {
        [self switchMusicAccompanimentMode:isOriginal];
    }
}

- (void)onCapturedAudioFrame:(TRTCAudioFrame *)frame {
    @weakify(self)
    if (self.takeSeatIndex == -1 || self.currentPlayingOriginalMusicID == -1 || self.musicTimeStamp == -1) {
        NSLog(@"currentPlayingOriginalMusicID = %d, musicTimeStamp = %ld",self.currentPlayingOriginalMusicID, self.musicTimeStamp);
        return;
    }
    [self runOnObserverQueue:^{
        @strongify(self)
        if ([self canObserverResponseMethod:@selector(onCapturedAudioBuffer:length:timeStamp:)]) {
            char* buffer = (char *)[frame.data bytes];
            int length = (int)[frame.data length];
            [self.observer onCapturedAudioBuffer:buffer length:length timeStamp:(double)self.musicTimeStamp];
        }
    }];
}

#pragma mark - KaraokeIMServiceObserver
- (void)onRoomDestroyWithRoomId:(NSString *)roomID {
    TRTCLog(@"onRoomDestroyWithRoomId roomID = %@", roomID);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        [self exitRoom:nil];
        [self runOnObserverQueue:^{
            @strongify(self)
            if (!self) { return; }
            if ([self canObserverResponseMethod:@selector(onRoomDestroy:)]) {
                [self.observer onRoomDestroy:roomID];
            }
        }];
    }];
}

- (void)onRoomRecvRoomTextMsg:(NSString *)roomID message:(NSString *)message userInfo:(KaraokeUserInfo *)userInfo {
    TRTCLog(@"onRoomRecvRoomTextMsg roomID = %@, message = %@, userInfo = %@", roomID, message, userInfo);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onRecvRoomTextMsg:userInfo:)]) {
            [self.observer onRecvRoomTextMsg:message userInfo:userInfo];
        }
    }];
}

- (void)onRoomRecvRoomCustomMsg:(NSString *)roomID cmd:(NSString *)cmd message:(NSString *)message userInfo:(KaraokeUserInfo *)userInfo {
    TRTCLog(@"onRoomRecvRoomCustomMsg roomID = %@, cmd = %@, message = %@, userInfo = %@", roomID, cmd, message, userInfo);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onRecvRoomCustomMsg:message:userInfo:)]) {
            [self.observer onRecvRoomCustomMsg:cmd message:message userInfo:userInfo];
        }
    }];
}

- (void)onRoomInfoChange:(KaraokeRoomInfo *)roomInfo {
    TRTCLog(@"onRoomInfoChange roomID = %@, ownerId = %@, memberCount = %d, roomName = %@",
            roomInfo.roomId,
            roomInfo.ownerId,
            roomInfo.memberCount,
            roomInfo.roomName);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([roomInfo.roomId intValue] == 0) {
            return;
        }
        if ([self canObserverResponseMethod:@selector(onRoomInfoChange:)]) {
            [self.observer onRoomInfoChange:roomInfo];
        }
    }];
}

- (void)onSeatInfoListChange:(NSArray<KaraokeSeatInfo *> *)seatInfoList {
    TRTCLog(@"onSeatInfoListChange seatInfoListCount = %lu",(unsigned long)seatInfoList.count);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        NSMutableArray* roomSeatList = [[NSMutableArray alloc] initWithCapacity:2];
        for (KaraokeSeatInfo* info in seatInfoList) {
            [roomSeatList addObject:info];
        }
        if (self.imService.isOwner) {
            [self.rtcService updatePublishMediaStream];
        }
        self.seatInfoList = roomSeatList;
        if ([self canObserverResponseMethod:@selector(onSeatInfoChange:)]) {
            [self.observer onSeatInfoChange:roomSeatList];
        }
    }];
}

- (void)onRoomAudienceEnter:(KaraokeUserInfo *)userInfo {
    TRTCLog(@"onRoomAudienceEnter userId = %@, userName = %@, avatarURL = %@",
          userInfo.userId,
          userInfo.userName,
          userInfo.avatarURL);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onAudienceEnter:)]) {
            [self.observer onAudienceEnter:userInfo];
        }
    }];
}

- (void)onRoomAudienceLeave:(KaraokeUserInfo *)userInfo {
    TRTCLog(@"onRoomAudienceLeave userId = %@, userName = %@, avatarURL = %@",
          userInfo.userId,
          userInfo.userName,
          userInfo.avatarURL);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onAudienceExit:)]) {
            [self.observer onAudienceExit:userInfo];
        }
    }];
}

- (void)onSeatTakeWithIndex:(NSInteger)index userInfo:(KaraokeUserInfo *)userInfo {
    TRTCLog(@"onSeatTakeWithIndex index = %ld, userId = %@, userName = %@, avatarURL = %@",
            index,
            userInfo.userId,
            userInfo.userName,
            userInfo.avatarURL);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        BOOL isSelfEnterSeat = [userInfo.userId isEqualToString:self.userId];
        if (isSelfEnterSeat) {
            // 是自己上线了
            self.takeSeatIndex = index;
            [self.rtcService switchToAnchor];
            BOOL mute = self.seatInfoList[index].mute;
            [self.rtcService muteLocalAudio:mute];
        }
        [self runOnObserverQueue:^{
            @strongify(self)
            if (!self) { return; }
            if ([self canObserverResponseMethod:@selector(onAnchorEnterSeat:user:)]) {
                [self.observer onAnchorEnterSeat:index user:userInfo];
            }
            if (self.pickSeatCallback) {
                self.pickSeatCallback(0, @"pick seat success");
                self.pickSeatCallback = nil;
            }
        }];
        if (isSelfEnterSeat) {
            [self runOnObserverQueue:^{
                @strongify(self)
                if (!self) {
                    return;
                }
                if (self.enterSeatCallback) {
                    self.enterSeatCallback(0, @"enter seat success.");
                    self.enterSeatCallback = nil;
                }
            }];
        }
    }];
}

- (void)onSeatCloseWithIndex:(NSInteger)index isClose:(BOOL)isClose {
    TRTCLog(@"onSeatCloseWithIndex index = %ld, isClose = %d", index, isClose);
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) { return; }
        if (self.takeSeatIndex == index) {
            [self.rtcService switchToAudience];
            self.takeSeatIndex = -1;
        }
        [self runOnObserverQueue:^{
            @strongify(self)
            if (!self) { return; }
            if ([self canObserverResponseMethod:@selector(onSeatClose:isClose:)]) {
                [self.observer onSeatClose:index isClose:isClose];
            }
        }];
    }];
}

- (void)onSeatLeaveWithIndex:(NSInteger)index userInfo:(KaraokeUserInfo *)userInfo {
    TRTCLog(@"onSeatLeaveWithIndex index = %ld, userId = %@, userName = %@, avatarURL = %@",
            index,
            userInfo.userId,
            userInfo.userName,
            userInfo.avatarURL);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self.userId isEqualToString:userInfo.userId]) {
            self.takeSeatIndex = -1;
            [self.rtcService switchToAudience];
        }
        if ([self canObserverResponseMethod:@selector(onAnchorLeaveSeat:user:)]) {
            [self.observer onAnchorLeaveSeat:index user:userInfo];
        }
        if (self.kickSeatCallback) {
            self.kickSeatCallback(0, @"kick seat success.");
            self.kickSeatCallback = nil;
        }
        if ([self.userId isEqualToString:userInfo.userId]) {
            if (self.leaveSeatCallback) {
                self.leaveSeatCallback(0, @"leave seat success.");
                self.leaveSeatCallback = nil;
            }
        }
    }];
}

- (void)onSeatMuteWithIndex:(NSInteger)index mute:(BOOL)isMute {
    TRTCLog(@"onSeatMuteWithIndex index = %ld, mute = %d", index, isMute);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if (self.takeSeatIndex == index) {
            self.isSelfMute = isMute;
            [self.rtcService muteLocalAudio:isMute];
            if ([self canObserverResponseMethod:@selector(onUserMicrophoneMute:mute:)]) {
                [self.observer onUserMicrophoneMute:self.userId mute:isMute];
            }
        }
        if ([self canObserverResponseMethod:@selector(onSeatMute:isMute:)]) {
            [self.observer onSeatMute:index isMute:isMute];
        }
    }];
}

- (void)onReceiveNewInvitationWithIdentifier:(NSString *)identifier inviter:(NSString *)inviter cmd:(NSString *)cmd content:(NSString *)content{
    TRTCLog(@"onReceiveNewInvitationWithIdentifier identifier = %@, inviter = %@, cmd = %@, content = %@",
            identifier,
            inviter,
            cmd,
            content);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onReceiveNewInvitation:inviter:cmd:content:)]) {
            [self.observer onReceiveNewInvitation:identifier inviter:inviter cmd:cmd content:content];
        }
    }];
}

- (void)onInviteeAcceptedWithIdentifier:(NSString *)identifier invitee:(NSString *)invitee {
    TRTCLog(@"onInviteeAcceptedWithIdentifier identifier = %@, invitee = %@",
            identifier,
            invitee);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onInviteeAccepted:invitee:)]) {
            [self.observer onInviteeAccepted:identifier invitee:invitee];
        }
    }];
}

- (void)onInviteeRejectedWithIdentifier:(NSString *)identifier invitee:(NSString *)invitee {
    TRTCLog(@"onInviteeRejectedWithIdentifier identifier = %@, invitee = %@",
            identifier,
            invitee);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onInviteeRejected:invitee:)]) {
            [self.observer onInviteeRejected:identifier invitee:invitee];
        }
    }];
}

- (void)onInviteeCancelledWithIdentifier:(NSString *)identifier invitee:(NSString *)invitee {
    TRTCLog(@"onInviteeCancelledWithIdentifier identifier = %@, invitee = %@",
            identifier,
            invitee);
    @weakify(self)
    [self runOnObserverQueue:^{
        @strongify(self)
        if (!self) { return; }
        if ([self canObserverResponseMethod:@selector(onInvitationCancelled:invitee:)]) {
            [self.observer onInvitationCancelled:identifier invitee:invitee];
        }
    }];
}

@end

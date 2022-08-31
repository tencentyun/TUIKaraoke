//
//  TRTCKaraokeRoom.m
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "TRTCKaraokeRoom.h"
#import "KaraokeTRTCService.h"
#import "TXKaraokeService.h"
#import "TXKaraokeCommonDef.h"
#import "TRTCCloud.h"
#import "KaraokeLocalized.h"
#import "TXKaraokeIMJsonHandle.h"

@interface TRTCKaraokeRoom ()<KaraokeTRTCServiceDelegate, ITXRoomServiceDelegate>

@property (nonatomic, assign) int mSDKAppID;

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *userSig;
@property (nonatomic, strong) NSString *roomID;
@property (nonatomic, strong) NSMutableSet<NSString *> *anchorSeatList;
@property (nonatomic, strong) NSMutableSet<NSString *> *audienceList;
@property (nonatomic, strong) NSMutableArray<SeatInfo *> *seatInfoList;
@property (nonatomic, assign) NSInteger takeSeatIndex;

@property (nonatomic, strong) RoomInfo *roomInfo;

@property (nonatomic, weak) id<TRTCKaraokeRoomDelegate> delegate;

@property (nonatomic, copy, nullable) ActionCallback enterSeatCallback;
@property (nonatomic, copy, nullable) ActionCallback leaveSeatCallback;
@property (nonatomic, copy, nullable) ActionCallback pickSeatCallback;
@property (nonatomic, copy, nullable) ActionCallback kickSeatCallback;

@property (nonatomic, weak) dispatch_queue_t delegateQueue;

@property (nonatomic, readonly) TXKaraokeService *roomService;
@property (nonatomic, readonly) KaraokeTRTCService *roomTRTCService;

@property (nonatomic, assign) BOOL isSelfMute;

@property (nonatomic, assign) int32_t currentPlayingOriginalMusicID;
@property (nonatomic, assign) int32_t currentPlayingAccompanyMusicID;
@property (nonatomic, assign) BOOL isOriginalMusic;
//@property (nonatomic, strong) dispatch_semaphore_t startPlayMusicSem;
//@property (nonatomic, strong) dispatch_semaphore_t completePlayMusicSem;
//@property (nonatomic, strong) dispatch_queue_t musicCheckStatusQ;
@end

@implementation TRTCKaraokeRoom

static TRTCKaraokeRoom *gInstance;
static dispatch_once_t gOnceToken;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.delegateQueue = dispatch_get_main_queue();
        self.seatInfoList = [[NSMutableArray alloc] initWithCapacity:2];
        self.anchorSeatList = [[NSMutableSet alloc] initWithCapacity:2];
        self.audienceList = [[NSMutableSet alloc] initWithCapacity:2];
        self.takeSeatIndex = -1;
        self.roomService.delegate = self;
        self.roomTRTCService.delegate =self;
        self.isSelfMute = NO;
        self.currentPlayingOriginalMusicID = 0;
        self.currentPlayingAccompanyMusicID = 0;
        self.isOriginalMusic = YES;
    }
    return self;
}

- (TXKaraokeService *)roomService {
    return [TXKaraokeService sharedInstance];
}

- (KaraokeTRTCService *)roomTRTCService {
    return [KaraokeTRTCService sharedInstance];
}

- (BOOL)canDelegateResponseMethod:(SEL)method {
    return self.delegate && [self.delegate respondsToSelector:method];
}

#pragma mark - private method
- (BOOL)isOnSeatWithUserId:(NSString *)userId {
    if (self.seatInfoList.count == 0) {
        return NO;
    }
    for (SeatInfo *seatInfo in self.seatInfoList) {
        if ([seatInfo.userId isEqualToString:userId]) {
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

- (void)runOnDelegateQueue:(void(^)(void))action {
    if (self.delegateQueue) {
        dispatch_async(self.delegateQueue, ^{
            action();
        });
    }
}

- (void)destroy {
    [self.roomService destroy];
}

- (void)clearList {
    [self.seatInfoList removeAllObjects];
    [self.anchorSeatList removeAllObjects];
    [self.audienceList removeAllObjects];
    self.isSelfMute = NO;
    [self stopPlayMusic];
    self.currentPlayingOriginalMusicID = 0;
    self.currentPlayingAccompanyMusicID = 0;
}

- (void)exitRoomInternal:(ActionCallback _Nullable)callback {
    @weakify(self)
    [self.roomTRTCService exitRoom:^(int code, NSString * _Nonnull message) {
        @strongify(self)
        if (!self) {
            return;
        }
        if (code != 0) {
            [self runOnDelegateQueue:^{
                if ([self canDelegateResponseMethod:@selector(onError:message:)]) {
                    [self.delegate onError:code message:message];
                }
            }];
        }
    }];
    TRTCLog(@"start exit room service");
    [self.roomService exitRoom:^(int code, NSString * _Nonnull message) {
        @strongify(self)
        if (!self) {
            return;
        }
        if (callback) {
            [self runOnDelegateQueue:^{
                callback(code, message);
            }];
        }
    }];
    [self clearList];
    self.roomID = @"";
}

- (void)getAudienceList:(KaraokeUserListCallback _Nullable)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomService getAudienceList:^(int code, NSString * _Nonnull message, NSArray<TXKaraokeUserInfo *> * _Nonnull userInfos) {
            TRTCLog(@"get audience list finish, code:%d, message:%@, userListCount:%d", code, message, userInfos.count);
            NSMutableArray *userInfoList = [[NSMutableArray alloc] initWithCapacity:2];
            for (TXKaraokeUserInfo* info in userInfos) {
                UserInfo* userInfo = [[UserInfo alloc] init];
                userInfo.userId = info.userId;
                userInfo.userName = info.userName;
                userInfo.userAvatar = info.avatarURL;
                [userInfoList addObject:userInfo];
            }
            if (callback) {
                [self runOnDelegateQueue:^{
                    callback(code, message, userInfoList);
                }];
            }
        }];
    }];
}

- (void)enterTRTCRoomInnerWithRoomId:(NSString *)roomId userId:(NSString *)userId
 userSign:(NSString *)userSig role:(NSInteger)role callback:(ActionCallback)callback {
    TRTCLog(@"start enter trtc room.");
    @weakify(self)
    [self.roomTRTCService enterRoomWithSdkAppId:self.mSDKAppID roomId:roomId userId:userId
     userSign:userSig role:role callback:^(int code, NSString * _Nonnull message) {
        @strongify(self)
        if (!self) {
            return;
        }
        if (callback) {
            [self runOnDelegateQueue:^{
                callback(code, message);
            }];
        }
    }];
}

#pragma mark - TRTCKaraoke 实现
+ (instancetype)sharedInstance {
    dispatch_once(&gOnceToken, ^{
        gInstance = [[TRTCKaraokeRoom alloc] init];
        [TXKaraokeService sharedInstance].delegate = gInstance;
        [KaraokeTRTCService sharedInstance].delegate = gInstance;
    });
    return gInstance;
}

+ (void)destroySharedInstance {
    gOnceToken = 0;
    gInstance = nil;
}

- (void)setDelegate:(id<TRTCKaraokeRoomDelegate>)delegate{
    self->_delegate = delegate;
}

- (void)setDelegateQueue:(dispatch_queue_t)queue {
    self->_delegateQueue = queue;
}

- (void)login:(int)sdkAppID userId:(NSString *)userId userSig:(NSString *)userSig callback:(ActionCallback)callback{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if (sdkAppID != 0 && userId && ![userId isEqualToString:@""] && userSig && ![userSig isEqualToString:@""]) {
            self.mSDKAppID = sdkAppID;
            self.userId = userId;
            self.userSig = userSig;
            TRTCLog(@"start login room service");
            [self.roomService loginWithSdkAppId:sdkAppID userId:userId userSig:userSig callback:^(int code, NSString * _Nonnull message) {
                @strongify(self)
                if (!self) {
                    return;
                }
                [self.roomService getSelfInfo];
                if (callback) {
                    [self runOnDelegateQueue:^{
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

- (void)logout:(ActionCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        TRTCLog(@"start logout");
        self.mSDKAppID = 0;
        self.userId = @"";
        self.userSig = @"";
        TRTCLog(@"start logout room service");
        [self.roomService logout:^(int code, NSString * _Nonnull message) {
            if (callback) {
                [self runOnDelegateQueue:^{
                    callback(code, message);
                }];
            }
        }];
    }];
}

- (void)setSelfProfile:(NSString *)userName avatarURL:(NSString *)avatarURL callback:(ActionCallback)callback{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomService setSelfProfileWithUserName:userName avatarUrl:avatarURL callback:^(int code, NSString * _Nonnull message) {
            if (callback) {
                [self runOnDelegateQueue:^{
                    callback(code, message);
                }];
            }
        }];
    }];
}

- (void)createRoom:(int)roomID roomParam:(RoomParam *)roomParam callback:(ActionCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomService getSelfInfo];
        if (roomID == 0) {
            TRTCLog(@"crate room fail. params invalid.");
            if (callback) {
                callback(-1, @"create room fail. parms invalid.");
            }
            return;
        }
        self.roomID = [NSString stringWithFormat:@"%d", roomID];
        [self clearList];
        NSString* roomName = roomParam.roomName;
        NSString* roomCover = roomParam.coverUrl;
        BOOL isNeedrequest = roomParam.needRequest;
        NSInteger seatCount = roomParam.seatCount;
        NSMutableArray* seatInfoList = [[NSMutableArray alloc] initWithCapacity:2];
        if (roomParam.seatInfoList.count > 0) {
            for (SeatInfo* info in roomParam.seatInfoList) {
                TXKaraokeSeatInfo* seatInfo = [[TXKaraokeSeatInfo alloc] init];
                seatInfo.status = info.status;
                seatInfo.mute = info.mute;
                seatInfo.user = info.userId;
                [seatInfoList addObject:seatInfo];
                [self.seatInfoList addObject:info];
            }
        } else {
            for (int index = 0; index < seatCount; index += 1) {
                TXKaraokeSeatInfo* info = [[TXKaraokeSeatInfo alloc] init];
                [seatInfoList addObject:info];
                [self.seatInfoList addObject:[[SeatInfo alloc] init]];
            }
        }
        [self.roomService createRoomWithRoomId:self.roomID
                                      roomName:roomName
                                      coverUrl:roomCover
                                   needRequest:isNeedrequest
                                  seatInfoList:seatInfoList
                                      callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            if (code == 0) {
                [self enterTRTCRoomInnerWithRoomId:self.roomID userId:self.userId userSign:self.userSig role:KTRTCRoleAnchorValue callback:callback];
                return;
            } else {
                [self runOnDelegateQueue:^{
                    if ([self canDelegateResponseMethod:@selector(onError:message:)]) {
                        [self.delegate onError:code message:message];
                    }
                }];
            }
            if (callback) {
                callback(code, message);
            }
        }];
    }];
}

- (void)destroyRoom:(ActionCallback)callback{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        TRTCLog(@"start destroyu room.");
        [self.roomTRTCService exitRoom:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            if (code != 0) {
                if ([self canDelegateResponseMethod:@selector(onError:message:)]) {
                    [self.delegate onError:code message:message];
                }
            }
        }];
        // 在公开群（Public）、会议（Meeting）和直播群（AVChatRoom）中，群主是不可以退群的，群主只能调用 dismissGroup 解散群组。
        [self.roomService destroyRoom:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            TRTCLog(@"destroy room finish, code:%d, message: %@", code, message);
            if (callback) {
                [self runOnDelegateQueue:^{
                    callback(code, message);
                }];
            }
        }];
        [self clearList];
    }];
}

- (void)enterRoom:(NSInteger)roomID callback:(ActionCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self clearList];
        self.roomID = [NSString stringWithFormat:@"%ld", (long)roomID];
        TRTCLog(@"start enter room, room id is %ld", (long)roomID);
        [self enterTRTCRoomInnerWithRoomId:self.roomID userId:self.userId userSign:self.userSig
         role:KTRTCRoleAudienceValue callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            if (callback) {
                [self runMainQueue:^{
                    callback(code, message);
                }];
            }
        }];
        [self.roomService enterRoom:self.roomID callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            if (code != 0) {
                [self runOnDelegateQueue:^{
                    if ([self canDelegateResponseMethod:@selector(onError:message:)]) {
                        [self.delegate onError:code message:message];
                    }
                }];
            }
        }];
    }];
}

- (void)exitRoom:(ActionCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        TRTCLog(@"start exit room");
        if ([self isOnSeatWithUserId:self.userId]) {
            [self leaveSeat:^(int code, NSString * _Nonnull message) {
                @strongify(self)
                if (!self) {
                    return;
                }
                [self exitRoomInternal:callback];
            }];
        } else {
            [self exitRoomInternal:callback];
        }
    }];
}

- (void)getRoomInfoList:(NSArray<NSNumber *> *)roomIdList callback:(KaraokeInfoCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        TRTCLog(@"start get room info:%@", roomIdList);
        NSMutableArray* roomIds = [[NSMutableArray alloc] initWithCapacity:2];
        for (NSNumber *roomId in roomIdList) {
            [roomIds addObject:[roomId stringValue]];
        }
        [self.roomService getRoomInfoList:roomIds calback:^(int code, NSString * _Nonnull
         message, NSArray<TXKaraokeRoomInfo *> * _Nonnull roomInfos) {
            if (code == 0) {
                TRTCLog(@"roomInfos: %@", roomInfos);
                NSMutableArray* trtcRoomInfos = [[NSMutableArray alloc] initWithCapacity:2];
                for (TXKaraokeRoomInfo *info in roomInfos) {
                    if ([info.roomId integerValue] != 0) {
                        RoomInfo *roomInfo = [[RoomInfo alloc] init];
                        roomInfo.roomID = [info.roomId integerValue];
                        roomInfo.ownerId = info.ownerId;
                        roomInfo.memberCount = info.memberCount;
                        roomInfo.roomName = info.roomName;
                        roomInfo.coverUrl = info.cover;
                        roomInfo.ownerName = info.ownerName;
                        roomInfo.needRequest = info.needRequest == 1;
                        [trtcRoomInfos addObject:roomInfo];
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
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if (!userIDList) {
            [self getAudienceList:callback];
            return;
        }
        [self.roomService getUserInfo:userIDList callback:^(int code, NSString * _Nonnull
         message, NSArray<TXKaraokeUserInfo *> * _Nonnull userInfos) {
            @strongify(self)
            if (!self) {
                return;
            }
            [self runOnDelegateQueue:^{
                @strongify(self)
                if (!self) {
                    return;
                }
                NSMutableArray* userList = [[NSMutableArray alloc] initWithCapacity:2];
                [userInfos enumerateObjectsUsingBlock:^(TXKaraokeUserInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    UserInfo* userInfo = [[UserInfo alloc] init];
                    userInfo.userId = obj.userId;
                    userInfo.userName = obj.userName;
                    userInfo.userAvatar = obj.avatarURL;
                    [userList addObject:userInfo];
                }];
                if (callback) {
                    callback(code, message, userList);
                }
            }];
        }];
    }];
}

- (void)enterSeat:(NSInteger)seatIndex callback:(ActionCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self isOnSeatWithUserId:self.userId]) {
            [self runOnDelegateQueue:^{
                if (callback) {
                    callback(-1, @"you are alread in the seat.");
                }
            }];
            return;
        }
        self.enterSeatCallback = callback;
        [self.roomService takeSeat:seatIndex callback:^(int code, NSString * _Nonnull message) {
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

- (void)leaveSeat:(ActionCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if (self.takeSeatIndex == -1) {
            [self runOnDelegateQueue:^{
                callback(-1, @"you are not in the seat.");
            }];
            return;
        }
        self.leaveSeatCallback = callback;
        [self.roomService leaveSeat:self.takeSeatIndex callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
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

- (void)pickSeat:(NSInteger)seatIndex userId:(NSString *)userId callback:(ActionCallback)callback{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self isOnSeatWithUserId:userId]) {
            [self runOnDelegateQueue:^{
                if (callback) {
                    callback(-1, karaokeLocalize(@"Demo.TRTC.Salon.userisspeaker"));
                }
            }];
            return;
        }
        self.pickSeatCallback = callback;
        [self.roomService pickSeat:seatIndex userId:userId callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
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

- (void)kickSeat:(NSInteger)seatIndex callback:(ActionCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        self.kickSeatCallback = callback;
        [self.roomService kickSeat:seatIndex callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
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

- (void)muteSeat:(NSInteger)seatIndex isMute:(BOOL)isMute callback:(ActionCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomService muteSeat:seatIndex mute:isMute callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            [self runOnDelegateQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (void)closeSeat:(NSInteger)seatIndex isClose:(BOOL)isClose callback:(ActionCallback)callback{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomService closeSeat:seatIndex isClose:isClose callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            [self runOnDelegateQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (void)startMicrophone {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomTRTCService startMicrophone];
    }];
}

- (void)stopMicrophone{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomTRTCService stopMicrophone];
    }];
}

- (void)setAuidoQuality:(NSInteger)quality {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomTRTCService setAudioQuality:quality];
    }];
}

- (void)setVoiceEarMonitorEnable:(BOOL)enable {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomTRTCService setVoiceEarMonitorEnable:enable];
    }];
}

- (void)muteLocalAudio:(BOOL)mute{
    self.isSelfMute = mute;
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomTRTCService muteLocalAudio:mute];
    }];
}

- (void)setSpeaker:(BOOL)userSpeaker {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomTRTCService setSpeaker:userSpeaker];
    }];
}

- (void)setAudioCaptureVolume:(NSInteger)voluem {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomTRTCService setAudioCaptureVolume:voluem];
    }];
}

- (void)setAudioPlayoutVolume:(NSInteger)volume {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomTRTCService setAudioPlayoutVolume:volume];
    }];
}

- (void)muteRemoteAudio:(NSString *)userId mute:(BOOL)mute{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomTRTCService muteRemoteAudioWithUserId:userId isMute:mute];
    }];
}

- (void)muteAllRemoteAudio:(BOOL)isMute{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomTRTCService muteAllRemoteAudio:isMute];
    }];
}

- (TXAudioEffectManager *)getAudioEffectManager{
    return [[TRTCCloud sharedInstance] getAudioEffectManager];
}

- (void)sendRoomTextMsg:(NSString *)message callback:(ActionCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomService sendRoomTextMsg:message callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            [self runOnDelegateQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (void)sendRoomCustomMsg:(NSString *)cmd message:(NSString *)message callback:(ActionCallback)callback {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomService sendRoomCustomMsg:cmd message:message callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            [self runOnDelegateQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (NSString *)sendInvitation:(NSString *)cmd userId:(NSString *)userId content:(NSString *)content callback:(ActionCallback)callback{
    @weakify(self)
    return [self.roomService sendInvitation:cmd userId:userId content:content callback:^(int code, NSString * _Nonnull message) {
        @strongify(self)
        if (!self) {
            return;
        }
        [self runOnDelegateQueue:^{
            if (callback) {
                callback(code, message);
            }
        }];
    }];
}

- (void)acceptInvitation:(NSString *)identifier callback:(ActionCallback)callback{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomService acceptInvitation:identifier callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            [self runOnDelegateQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (void)rejectInvitation:(NSString *)identifier callback:(ActionCallback)callback{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomService rejectInvitaiton:identifier callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            [self runOnDelegateQueue:^{
                if (callback) {
                    callback(code, message);
                }
            }];
        }];
    }];
}

- (void)cancelInvitation:(NSString *)identifier callback:(ActionCallback)callback{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self.roomService cancelInvitation:identifier callback:^(int code, NSString * _Nonnull message) {
            @strongify(self)
            if (!self) {
                return;
            }
            [self runOnDelegateQueue:^{
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

#pragma mark - Music


- (void)sendSEIMsg:(NSDictionary *)json {
    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&err];
    if (err == nil) {
        [self.roomTRTCService sendSEIMsg:data];
    }
}

- (void)switchToOriginalVolume:(BOOL)isOriginal {
    if (self.currentPlayingOriginalMusicID * self.currentPlayingAccompanyMusicID == 0) {
        TRTCLog(@"ktv: Music playing status error");
        return;
    }
    TRTCLog(@"ktv: switch to %@", isOriginal ? @"original" : @"accompany");
    _isOriginalMusic = isOriginal;
    [self setMusicVolume:self.currentPlayingOriginalMusicID volume:isOriginal ? 100 : 0];
    [self setMusicVolume:self.currentPlayingAccompanyMusicID volume:isOriginal ? 0 : 100];
}

- (void)setMusicVolume:(int32_t)musicID volume:(NSInteger)volume {
    
    if (musicID == 0) return;
    
    if (volume < 0) {
        volume = 0;
    }
    else if (volume > 100) {
        volume = 100;
    }
    [[self getAudioEffectManager] setMusicPlayoutVolume:musicID volume:volume];
    [[self getAudioEffectManager] setMusicPublishVolume:musicID volume:volume];
}

- (void)startPlayMusic:(int32_t)musicID originalUrl:(nonnull NSString *)originalUrl accompanyUrl:(nonnull NSString *)accompanyUrl {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (self.currentPlayingOriginalMusicID * self.currentPlayingAccompanyMusicID != 0) {
            if (self.currentPlayingOriginalMusicID == musicID) {
                [self resumePlayMusic];
                return;
            }
            else {
                [self stopPlayMusic];
            }
            self.currentPlayingOriginalMusicID = 0;
            self.currentPlayingAccompanyMusicID = 0;
        }
        self.currentPlayingOriginalMusicID = musicID;
        self.currentPlayingAccompanyMusicID = musicID + 1;
        
        TXAudioMusicParam *originParam = [[TXAudioMusicParam alloc] init];
        originParam.ID = self.currentPlayingOriginalMusicID;
        originParam.path = originalUrl;
        originParam.loopCount = 0;
        originParam.publish = YES;
        
        TXAudioMusicParam *accompanyParam = [[TXAudioMusicParam alloc] init];
        accompanyParam.ID = self.currentPlayingAccompanyMusicID;
        accompanyParam.path = accompanyUrl;
        accompanyParam.loopCount = 0;
        accompanyParam.publish = YES;
        
        TRTCLog(@"ktv: start play: %d", self.currentPlayingOriginalMusicID);
        
        [self.roomTRTCService enableBlackStream:YES size:CGSizeMake(60, 60)];
        
        [[self getAudioEffectManager] startPlayMusic:originParam onStart:^(NSInteger errCode) {
            @strongify(self)
            TRTCLog(@"ktv: on prepare origin");
            [self playStart:musicID];
        } onProgress:^(NSInteger progressMs, NSInteger durationMs) {
            @strongify(self)
            [self runMainQueue:^{
                @strongify(self)
                NSInteger currentTime = progressMs;
                NSInteger totalTime = durationMs;
                NSDictionary *json = @{
                    @"music_id" : @(musicID),
                    @"current_time" : @(currentTime),
                    @"total_time" : @(totalTime)
                };
                [self sendSEIMsg:json];
                if ([self canDelegateResponseMethod:@selector(onMusicProgressUpdate:progress:total:)]) {
                    [self runOnDelegateQueue:^{
                        @strongify(self)
                        [self.delegate onMusicProgressUpdate:musicID progress:currentTime total:totalTime];
                    }];
                }
            }];
        } onComplete:^(NSInteger errCode) {
            @strongify(self)
            [self playComplete:musicID];
        }];
        
        [[self getAudioEffectManager] startPlayMusic:accompanyParam onStart:^(NSInteger errCode) {
        } onProgress:^(NSInteger progressMs, NSInteger durationMs) {
        } onComplete:^(NSInteger errCode) {
        }];
        // TODO: 这里可根据需要修改：如果记录原唱/伴奏；则不需要修改，反之则需要修改
        [self switchToOriginalVolume:self.isOriginalMusic];
    }];
}


-(void)playComplete:(int32_t)musicID{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        self.currentPlayingOriginalMusicID = 0;
        self.currentPlayingAccompanyMusicID = 0;
        [self.roomTRTCService enableBlackStream:NO size:CGSizeMake(60, 60)];
        if ([self canDelegateResponseMethod:@selector(onMusicCompletePlaying:)]) {
            [self runOnDelegateQueue:^{
                @strongify(self)
                [self.delegate onMusicCompletePlaying:musicID];
            }];
        }
    }];
}

-(void)playStart:(int32_t)musicID{
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if ([self canDelegateResponseMethod:@selector(onMusicPrepareToPlay:)]) {
            [self.delegate onMusicPrepareToPlay:musicID];
        }
    }];
}
- (void)stopPlayMusic {
    @weakify(self)
    int32_t musicID = self.currentPlayingOriginalMusicID;
    self.currentPlayingOriginalMusicID = 0;
    self.currentPlayingAccompanyMusicID = 0;
    [self runMainQueue:^{
        @strongify(self)
        [self.roomTRTCService enableBlackStream:NO size:CGSizeMake(60, 60)];
        [[self getAudioEffectManager] stopPlayMusic:musicID];
        [[self getAudioEffectManager] stopPlayMusic:musicID+1];
        if ([self canDelegateResponseMethod:@selector(onMusicCompletePlaying:)]) {
            [self runOnDelegateQueue:^{
                @strongify(self)
                if(musicID > 0){
                    [self.delegate onMusicCompletePlaying:musicID];
                }
            }];
        }
    }];
}

- (void)pausePlayMusic {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (self.currentPlayingOriginalMusicID * self.currentPlayingAccompanyMusicID != 0) {
            [[self getAudioEffectManager] pausePlayMusic:self.currentPlayingOriginalMusicID];
            [[self getAudioEffectManager] pausePlayMusic:self.currentPlayingAccompanyMusicID];
        }
    }];
}

- (void)resumePlayMusic {
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (self.currentPlayingOriginalMusicID * self.currentPlayingAccompanyMusicID != 0) {
            [[self getAudioEffectManager] resumePlayMusic:self.currentPlayingOriginalMusicID];
            [[self getAudioEffectManager] resumePlayMusic:self.currentPlayingAccompanyMusicID];
        }
    }];
}

#pragma mark - KaraokeTRTCServiceDelegate



- (void)onTRTCAnchorEnter:(NSString *)userId {
    [self.anchorSeatList addObject:userId];
}

- (void)onTRTCAnchorExit:(NSString *)userId {
    if (self.roomService.isOwner) {
        if (self.seatInfoList.count > 0) {
            NSInteger kickSeatIndex = -1;
            for (int i = 0; i<self.seatInfoList.count; i+=1) {
                if ([userId isEqualToString:self.seatInfoList[i].userId]) {
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
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self canDelegateResponseMethod:@selector(onError:message:)]) {
            [self.delegate onError:(int)code message:message];
        }
    }];
}

- (void)onNetWorkQuality:(TRTCQualityInfo *)trtcQuality arrayList:(NSArray<TRTCQualityInfo *> *)arrayList {
    
}

- (void)onUserVoiceVolume:(NSArray<TRTCVolumeInfo *> *)userVolumes totalVolume:(NSInteger)totalVolume {
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self canDelegateResponseMethod:@selector(onUserVolumeUpdate:totalVolume:)]) {
            [self.delegate onUserVolumeUpdate:userVolumes totalVolume:totalVolume];
        }
    }];
}

- (void)onTRTCAudioAvailable:(NSString *)userId available:(BOOL)available {
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self canDelegateResponseMethod:@selector(onUserMicrophoneMute:mute:)]) {
            [self.delegate onUserMicrophoneMute:userId mute:!available];
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
    if ([dic.allKeys containsObject:@"music_id"] && [dic.allKeys containsObject:@"current_time"] && [dic.allKeys containsObject:@"total_time"]) {
        [self runOnDelegateQueue:^{
            @strongify(self)
            if ([self canDelegateResponseMethod:@selector(onMusicProgressUpdate:progress:total:)]) {
                [self.delegate onMusicProgressUpdate:[dic[@"music_id"] intValue] progress:[dic[@"current_time"] doubleValue] total:[dic[@"total_time"] doubleValue]];
            }
        }];
    }
}

#pragma mark - ITXRoomServiceDelegate
- (void)onRoomDestroyWithRoomId:(NSString *)roomID{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        [self exitRoom:nil];
        [self runOnDelegateQueue:^{
            @strongify(self)
            if (!self) {
                return;
            }
            if ([self canDelegateResponseMethod:@selector(onRoomDestroy:)]) {
                [self.delegate onRoomDestroy:roomID];
            }
        }];
    }];
}

- (void)onRoomRecvRoomTextMsg:(NSString *)roomID message:(NSString *)message userInfo:(TXKaraokeUserInfo *)userInfo {
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        UserInfo* user = [[UserInfo alloc] init];
        user.userId = userInfo.userId;
        user.userName = userInfo.userName;
        user.userAvatar = userInfo.avatarURL;
        if ([self canDelegateResponseMethod:@selector(onRecvRoomTextMsg:userInfo:)]) {
            [self.delegate onRecvRoomTextMsg:message userInfo:user];
        }
    }];
}

- (void)onRoomRecvRoomCustomMsg:(NSString *)roomID cmd:(NSString *)cmd message:(NSString *)message userInfo:(TXKaraokeUserInfo *)userInfo {
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        UserInfo* user = [[UserInfo alloc] init];
        user.userId = userInfo.userId;
        user.userName = userInfo.userName;
        user.userAvatar = userInfo.avatarURL;
        if ([self canDelegateResponseMethod:@selector(onRecvRoomCustomMsg:message:userInfo:)]) {
            [self.delegate onRecvRoomCustomMsg:cmd message:message userInfo:user];
        }
    }];
}

- (void)onRoomInfoChange:(TXKaraokeRoomInfo *)roomInfo{
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([roomInfo.roomId intValue] == 0) {
            return;
        }
        RoomInfo *room = [[RoomInfo alloc] init];
        room.roomID = [roomInfo.roomId intValue];
        room.ownerId = roomInfo.ownerId;
        room.memberCount = roomInfo.memberCount;
        room.ownerName = roomInfo.ownerName;
        room.coverUrl = roomInfo.cover;
        room.needRequest = roomInfo.needRequest == 1;
        room.roomName = roomInfo.roomName;
        if ([self canDelegateResponseMethod:@selector(onRoomInfoChange:)]) {
            [self.delegate onRoomInfoChange:room];
        }
    }];
}

- (void)onSeatInfoListChange:(NSArray<TXKaraokeSeatInfo *> *)seatInfoList{
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        NSMutableArray* roomSeatList = [[NSMutableArray alloc] initWithCapacity:2];
        for (TXKaraokeSeatInfo* info in seatInfoList) {
            SeatInfo* seat = [[SeatInfo alloc] init];
            seat.userId = info.user;
            seat.mute = info.mute;
            seat.status = info.status;
            [roomSeatList addObject:seat];
        }
        self.seatInfoList = roomSeatList;
        if ([self canDelegateResponseMethod:@selector(onSeatInfoChange:)]) {
            [self.delegate onSeatInfoChange:roomSeatList];
        }
    }];
}

- (void)onRoomAudienceEnter:(TXKaraokeUserInfo *)userInfo {
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        UserInfo* user = [[UserInfo alloc] init];
        user.userId = userInfo.userId;
        user.userName = userInfo.userName;
        user.userAvatar = userInfo.avatarURL;
        if ([self canDelegateResponseMethod:@selector(onAudienceEnter:)]) {
            [self.delegate onAudienceEnter:user];
        }
    }];
}

- (void)onRoomAudienceLeave:(TXKaraokeUserInfo *)userInfo {
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        UserInfo* user = [[UserInfo alloc] init];
        user.userId = userInfo.userId;
        user.userName = userInfo.userName;
        user.userAvatar = userInfo.avatarURL;
        if ([self canDelegateResponseMethod:@selector(onAudienceExit:)]) {
            [self.delegate onAudienceExit:user];
        }
    }];
}

- (void)onSeatTakeWithIndex:(NSInteger)index userInfo:(TXKaraokeUserInfo *)userInfo{
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        BOOL isSelfEnterSeat = [userInfo.userId isEqualToString:self.userId];
        if (isSelfEnterSeat) {
            // 是自己上线了
            self.takeSeatIndex = index;
            [self.roomTRTCService switchToAnchor];
            BOOL mute = self.seatInfoList[index].mute;
            [self.roomTRTCService muteLocalAudio:mute];
        }
        [self runOnDelegateQueue:^{
            @strongify(self)
            if (!self) {
                return;
            }
            UserInfo* user = [[UserInfo alloc] init];
            user.userId = userInfo.userId;
            user.userName = userInfo.userName;
            user.userAvatar = userInfo.avatarURL;
            if ([self canDelegateResponseMethod:@selector(onAnchorEnterSeat:user:)]) {
                [self.delegate onAnchorEnterSeat:index user:user];
            }
            if (self.pickSeatCallback) {
                self.pickSeatCallback(0, @"pick seat success");
                self.pickSeatCallback = nil;
            }
        }];
        if (isSelfEnterSeat) {
            [self runOnDelegateQueue:^{
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
    @weakify(self)
    [self runMainQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if (self.takeSeatIndex == index) {
            [self.roomTRTCService switchToAudience];
            self.takeSeatIndex = -1;
        }
        [self runOnDelegateQueue:^{
            @strongify(self)
            if (!self) {
                return;
            }
            if ([self canDelegateResponseMethod:@selector(onSeatClose:isClose:)]) {
                [self.delegate onSeatClose:index isClose:isClose];
            }
        }];
    }];
}

- (void)onSeatLeaveWithIndex:(NSInteger)index userInfo:(TXKaraokeUserInfo *)userInfo {
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self.userId isEqualToString:userInfo.userId]) {
            self.takeSeatIndex = -1;
            [self.roomTRTCService switchToAudience];
        }
        UserInfo* user = [[UserInfo alloc] init];
        user.userId = userInfo.userId;
        user.userName = userInfo.userName;
        user.userAvatar = userInfo.avatarURL;
        if ([self canDelegateResponseMethod:@selector(onAnchorLeaveSeat:user:)]) {
            [self.delegate onAnchorLeaveSeat:index user:user];
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
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if (self.takeSeatIndex == index) {
            if (isMute) {
                [self.roomTRTCService muteLocalAudio:YES];
            } else {
                [self.roomTRTCService muteLocalAudio:self.isSelfMute];
            }
        }
        if ([self canDelegateResponseMethod:@selector(onSeatMute:isMute:)]) {
            [self.delegate onSeatMute:index isMute:isMute];
        }
    }];
}

- (void)onReceiveNewInvitationWithIdentifier:(NSString *)identifier inviter:(NSString *)inviter cmd:(NSString *)cmd content:(NSString *)content{
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self canDelegateResponseMethod:@selector(onReceiveNewInvitation:inviter:cmd:content:)]) {
            [self.delegate onReceiveNewInvitation:identifier inviter:inviter cmd:cmd content:content];
        }
    }];
}

- (void)onInviteeAcceptedWithIdentifier:(NSString *)identifier invitee:(NSString *)invitee {
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self canDelegateResponseMethod:@selector(onInviteeAccepted:invitee:)]) {
            [self.delegate onInviteeAccepted:identifier invitee:invitee];
        }
    }];
}

- (void)onInviteeRejectedWithIdentifier:(NSString *)identifier invitee:(NSString *)invitee {
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self canDelegateResponseMethod:@selector(onInviteeRejected:invitee:)]) {
            [self.delegate onInviteeRejected:identifier invitee:invitee];
        }
    }];
}

- (void)onInviteeCancelledWithIdentifier:(NSString *)identifier invitee:(NSString *)invitee {
    @weakify(self)
    [self runOnDelegateQueue:^{
        @strongify(self)
        if (!self) {
            return;
        }
        if ([self canDelegateResponseMethod:@selector(onInvitationCancelled:invitee:)]) {
            [self.delegate onInvitationCancelled:identifier invitee:invitee];
        }
    }];
}

@end

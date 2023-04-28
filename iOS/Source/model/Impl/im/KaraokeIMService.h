//
//  KaraokeIMService.h
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KaraokeModelDef.h"
#import "TRTCKaraokeRoomDef.h"
#import "KaraokeIMServiceObserver.h"

NS_ASSUME_NONNULL_BEGIN

static int gKaraoke_SERVICE_CODE_ERROR = -1;

@interface KaraokeIMService : NSObject

@property (nonatomic, weak) id<KaraokeIMServiceObserver> observer;
@property (nonatomic, assign, readonly)BOOL isOwner;
@property (nonatomic, copy) NSString *ownerUserId;

- (void)loginWithSdkAppId:(int)sdkAppId userId:(NSString *)userId userSig:(NSString *)userSig callback:(KaraokeCallback _Nullable)callback;
- (void)logout:(KaraokeCallback _Nullable)callback;

- (void)setSelfProfileWithUserName:(NSString *)userName
                         avatarUrl:(NSString *)avatarUrl
                          callback:(KaraokeCallback _Nullable)callback;

- (void)createRoomWithRoomId:(NSString *)roomId
                    roomName:(NSString *)roomName
                    coverUrl:(NSString *)coverUrl
                 needRequest:(BOOL)needRequest
                seatInfoList:(NSArray<KaraokeSeatInfo *> *)seatInfoList
                    callback:(KaraokeCallback _Nullable)callback;
- (void)destroyRoom:(KaraokeCallback _Nullable)callback;
- (void)enterRoom:(NSString *)roomId callback:(KaraokeCallback _Nullable)callback;
- (void)exitRoom:(KaraokeCallback _Nullable)callback;
- (void)takeSeat:(NSInteger)seatIndex callback:(KaraokeCallback _Nullable)callback;
- (void)leaveSeat:(NSInteger)seatIndex callback:(KaraokeCallback _Nullable)callback;
- (void)pickSeat:(NSInteger)seatIndex userId:(NSString *)userId callback:(KaraokeCallback _Nullable)callback;
- (void)kickSeat:(NSInteger)seatIndex callback:(KaraokeCallback _Nullable)callback;
- (void)muteSeat:(NSInteger)seatIndex mute:(BOOL)mute callback:(KaraokeCallback _Nullable)callback;
- (void)closeSeat:(NSInteger)seatIndex isClose:(BOOL)isClose callback:(KaraokeCallback _Nullable)callback;
- (void)getUserInfo:(NSArray<NSString *> *)userList callback:(KaraokeUserListCallback _Nullable)callback;
- (void)sendRoomTextMsg:(NSString *)msg callback:(KaraokeCallback _Nullable)callback;
- (void)sendRoomCustomMsg:(NSString *)cmd message:(NSString *)message callback:(KaraokeCallback _Nullable)callback;
- (void)sendGroupMsg:(NSString *)message callback:(KaraokeCallback _Nullable)callback;
- (void)getAudienceList:(KaraokeUserListCallback _Nullable)callback;
- (void)getRoomInfoList:(NSArray<NSString *> *)roomIds calback:(KaraokeRoomInfoListCallback _Nullable)callback;
- (NSString *)sendInvitation:(NSString *)cmd userId:(NSString *)userId content:(NSString *)content callback:(KaraokeCallback _Nullable)callback;
- (void)acceptInvitation:(NSString *)identifier callback:(KaraokeCallback _Nullable)callback;
- (void)rejectInvitaiton:(NSString *)identifier callback:(KaraokeCallback _Nullable)callback;
- (void)cancelInvitation:(NSString *)identifier callback:(KaraokeCallback _Nullable)callback;

@end

NS_ASSUME_NONNULL_END

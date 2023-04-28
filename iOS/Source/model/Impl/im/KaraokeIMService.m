//
//  KaraokeIMService.m
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "KaraokeIMService.h"
#import "MJExtension.h"
#import <ImSDK_Plus/ImSDK_Plus.h>
#import "KaraokeIMJsonHandle.h"
#import "KaraokeCommonDef.h"
#import "KaraokeLocalized.h"
#import "TRTCKaraokeRoomDef.h"
#import "KaraokeLogger.h"
#import "TUILogin.h"

@interface KaraokeIMService ()<V2TIMSDKListener, V2TIMSimpleMsgListener, V2TIMGroupListener, V2TIMSignalingListener>

@property (nonatomic, assign) BOOL isEnterRoom;
@property (nonatomic, strong) KaraokeRoomInfo *roomInfo;
@property (nonatomic, strong) NSArray<KaraokeSeatInfo *> *seatInfoList;

@end

@implementation KaraokeIMService

- (void)dealloc {
    TRTCLog(@"%@ dealloc", NSStringFromClass(self.class));
}

#pragma mark - public method
- (void)loginWithSdkAppId:(int)sdkAppId
                   userId:(NSString *)userId
                  userSig:(NSString *)userSig
                 callback:(KaraokeCallback)callback {
    NSString *loggedUserId = [TUILogin getUserID];
    if (loggedUserId && [loggedUserId isEqualToString:userId]) {
        // 已经登陆了
        if (callback) {
            callback(0, @"login im success, but you have been login.");
        }
        return;
    }
    
    @weakify(self)
    [TUILogin login:sdkAppId userID:userId userSig:userSig succ:^{
        @strongify(self)
        if (!self) { return; }
        if (callback) {
            callback(0, @"im login success.");
        }
    } fail:^(int code, NSString *msg) {
        if (callback) {
            callback(code, msg ?: @"im login error");
        }
    }];
}

- (void)logout:(KaraokeCallback)callback {
    if (!TUILogin.isUserLogined) {
        if (callback) {
            callback(gKaraoke_SERVICE_CODE_ERROR, @"start logout fail. not login yet");
        }
        return;
    }
    if (self.isEnterRoom) {
        if (callback) {
            callback(gKaraoke_SERVICE_CODE_ERROR, @"start logout fail. you are in room, please exit room before logout");
        }
        return;
    }
    @weakify(self)
    [TUILogin logout:^{
        @strongify(self)
        if (!self) { return; }
        if (callback) {
            callback(0, @"im logout success");
        }
    } fail:^(int code, NSString *msg) {
        if (callback) {
            callback(code, msg);
        }
    }];
}

- (void)setSelfProfileWithUserName:(NSString *)userName avatarUrl:(NSString *)avatarUrl callback:(KaraokeCallback _Nullable)callback{
    if (!TUILogin.isUserLogined) {
        if (callback) {
            callback(gKaraoke_SERVICE_CODE_ERROR, @"set profile fail, not login yet.");
        }
        return;
    }
    V2TIMUserFullInfo *userInfo = [[V2TIMUserFullInfo alloc] init];
    userInfo.nickName = userName;
    userInfo.faceURL = avatarUrl;
    [self.imManager setSelfInfo:userInfo succ:^{
        if (callback) {
            callback(0, @"set profile success");
        }
    } fail:^(int code, NSString *desc) {
        if (callback) {
            callback(0, desc ?: @"set profile failed.");
        }
    }];
}

- (void)createRoomWithRoomId:(NSString *)roomId
                    roomName:(NSString *)roomName
                    coverUrl:(NSString *)coverUrl
                 needRequest:(BOOL)needRequest
                seatInfoList:(NSArray<KaraokeSeatInfo *> *)seatInfoList
                    callback:(KaraokeCallback)callback {
    if (!TUILogin.isUserLogined) {
        if (callback) {
            callback(gKaraoke_SERVICE_CODE_ERROR, @"im not login yet, create room fail");
        }
        return;
    }
    if (self.isEnterRoom) {
        if (callback) {
            callback(gKaraoke_SERVICE_CODE_ERROR, @"you have been in room");
        }
        return;
    }
    self.ownerUserId = [TUILogin getUserID];
    self.seatInfoList = seatInfoList;
    self.roomInfo = [[KaraokeRoomInfo alloc] init];
    self.roomInfo.ownerId = self.ownerUserId;
    self.roomInfo.ownerName = [TUILogin getNickName];
    self.roomInfo.roomName = roomName;
    self.roomInfo.cover = coverUrl;
    self.roomInfo.seatSize = seatInfoList.count;
    self.roomInfo.needRequest = needRequest ? 1 : 0;
    self.roomInfo.roomId = roomId;
    @weakify(self)
    [self.imManager createGroup:@"AVChatRoom" groupID:roomId groupName:roomName succ:^(NSString *groupID) {
        @strongify(self)
        if (!self) { return; }
        [self setGroupInfoWithRoomId:roomId roomName:roomName coverUrl:coverUrl userName:[TUILogin getNickName]];
        if (callback) {
            callback(0, groupID);
        }
    } fail:^(int code, NSString *desc) {
        @strongify(self)
        if (!self) { return; }
        TRTCLog(@"create room error: %d, msg: %@", code, desc);
        NSString *msg = desc ?: @"create room fiald";
        if (code == 10036) {
            msg = localizeReplaceXX(karaokeLocalize(@"Demo.TRTC.Buy.chatroom"), @"https://cloud.tencent.com/document/product/269/11673");
        } else if (code == 10037) {
            msg = localizeReplaceXX(karaokeLocalize(@"Demo.TRTC.Buy.grouplimit"), @"https://cloud.tencent.com/document/product/269/11673");
        } else if (code == 10038) {
            msg = localizeReplaceXX(karaokeLocalize(@"Demo.TRTC.Buy.groupmemberlimit"), @"https://cloud.tencent.com/document/product/269/11673");
        }
        
        if (code == 10025 || code == 10021) {
            // 表明群主是自己，认为创建成功
            // 群ID已被他人使用，走进房的逻辑
            [self setGroupInfoWithRoomId:roomId roomName:roomName coverUrl:coverUrl userName:[TUILogin getNickName]];
            if (callback) {
                callback(0, @"create room success");
            }
        } else {
            if (callback) {
                callback(code, msg);
            }
        }
    }];
}

- (void)destroyRoom:(KaraokeCallback)callback {
    if (!self.isOwner) {
        if (callback) {
            callback(-1, @"only owner could destroy room");
        }
        return;
    }
    @weakify(self)
    [self.imManager dismissGroup:self.roomInfo.roomId succ:^{
        @strongify(self)
        if (!self) { return; }
        [self unInitIMListener];
        if (callback) {
            callback(0, @"destroy room success.");
        }
    } fail:^(int code, NSString *desc) {
        @strongify(self)
        if (!self) { return; }
        if (code == 10007) {
            TRTCLog(@"your are not real owner, start logic destroy.");
            [self cleanGroupAttributes];
            [self sendGroupMsg:[KaraokeIMJsonHandle getRoomdestroyMsg] callback:callback];
            [self unInitIMListener];
        } else {
            [self unInitIMListener];
            if (callback) {
                callback(code, desc ?: @"destroy room failed");
            }
        }
    }];
}

- (void)enterRoom:(NSString *)roomId callback:(KaraokeCallback)callback {
    [self initImListener];
    @weakify(self)
    [self.imManager joinGroup:roomId msg:@"" succ:^{
        [self getGroupAttributesWithRoomId:roomId callback:callback];
    } fail:^(int code, NSString *desc) {
        if (code == 10013) {
            [self getGroupAttributesWithRoomId:roomId callback:callback];
        } else {
            if (callback) {
                callback(-1, [NSString stringWithFormat:@"join group eror, enter room fail. code:%d, msg:%@", code ,desc]);
            }
        }
    }];
}

- (void)exitRoom:(KaraokeCallback)callback {
    if (!self.isEnterRoom) {
        if (callback) {
            callback(-1,@"not enter room yet, can't exit room.");
        }
        return;
    }
    @weakify(self)
    [self.imManager quitGroup:self.roomInfo.roomId succ:^{
        @strongify(self)
        if (!self) { return; }
        [self unInitIMListener];
        if (callback) {
            callback(0, @"exit room success.");
        }
    } fail:^(int code, NSString *desc) {
        @strongify(self)
        if (!self) { return; }
        [self unInitIMListener];
        if (callback) {
            callback(code, desc ?: @"exit room failed.");
        }
    }];
}

- (void)takeSeat:(NSInteger)seatIndex callback:(KaraokeCallback)callback {
    if (!callback) {
        callback = ^(int code, NSString* message){
            
        };
    }
    if (seatIndex >= 0 && seatIndex < self.seatInfoList.count) {
        KaraokeSeatInfo* info = self.seatInfoList[seatIndex];
        if (info.status == kKaraokeSeatStatusUsed) {
            callback(-1, @"seat is used");
            return;
        }
        if (info.status == kKaraokeSeatStatusClose) {
            callback(-1, @"seat is closed.");
            return;
        }
        KaraokeSeatInfo* changeInfo = [[KaraokeSeatInfo alloc] init];
        changeInfo.status = kKaraokeSeatStatusUsed;
        changeInfo.user = [TUILogin getUserID];
        changeInfo.mute = info.mute;
        NSDictionary *dic = [KaraokeIMJsonHandle getSeatInfoJsonStrWithIndex:seatIndex info:changeInfo];
        [self modifyRoomAttributes:dic callback:callback];
    } else {
        if (callback) {
            callback(-1, @"seat info list is empty or index error.");
        }
    }
}

- (void)leaveSeat:(NSInteger)seatIndex callback:(KaraokeCallback)callback {
    if (!callback) {
        callback = ^(int code, NSString* message){
            
        };
    }
    if (seatIndex >= 0 && seatIndex < self.seatInfoList.count) {
        KaraokeSeatInfo* info = self.seatInfoList[seatIndex];
        if (![[TUILogin getUserID] isEqualToString:info.user]) {
            callback(-1, @"not in the seat");
            return;
        }
        KaraokeSeatInfo* changeInfo = [[KaraokeSeatInfo alloc] init];
        changeInfo.status = kKaraokeSeatStatusUnused;
        changeInfo.user = @"";
        changeInfo.mute = info.mute;
        NSDictionary *dic = [KaraokeIMJsonHandle getSeatInfoJsonStrWithIndex:seatIndex info:changeInfo];
        [self modifyRoomAttributes:dic callback:callback];
    } else {
        if (callback) {
            callback(-1, @"seat info list is empty or index error.");
        }
    }
}

- (void)pickSeat:(NSInteger)seatIndex userId:(NSString *)userId callback:(KaraokeCallback)callback {
    if (!callback) {
        callback = ^(int code, NSString* message){};
    }
    if (!self.isOwner) {
        callback(-1, @"seat info list is empty or index error.");
        return;
    }
    if (seatIndex < 0 || seatIndex >= self.seatInfoList.count) {
        callback(-1, @"seat info list is empty or index error.");
        return;
    }
    KaraokeSeatInfo *info = self.seatInfoList[seatIndex];
    if (info.status == kKaraokeSeatStatusUsed) {
        callback(-1, @"seat status is used");
        return;
    }
    if (info.status == kKaraokeSeatStatusClose) {
        callback(-1, @"seat status is close");
        return;
    }
    KaraokeSeatInfo *changeInfo = [[KaraokeSeatInfo alloc] init];
    changeInfo.status = kKaraokeSeatStatusUsed;
    changeInfo.user = userId;
    changeInfo.mute = info.mute;
    NSDictionary *dic = [KaraokeIMJsonHandle getSeatInfoJsonStrWithIndex:seatIndex info:changeInfo];
    [self modifyRoomAttributes:dic callback:callback];
}

- (void)kickSeat:(NSInteger)seatIndex callback:(KaraokeCallback)callback {
    if (!callback) {
        callback = ^(int code, NSString* message){};
    }
    if (!self.isOwner) {
        callback(-1, @"seat info list is empty or index error.");
        return;
    }
    if (seatIndex < 0 || seatIndex >= self.seatInfoList.count) {
        callback(-1, @"seat info list is empty or index error.");
        return;
    }
    KaraokeSeatInfo *changeInfo = [[KaraokeSeatInfo alloc] init];
    changeInfo.status = kKaraokeSeatStatusUnused;
    changeInfo.user = @"";
    changeInfo.mute = self.seatInfoList[seatIndex].mute;
    NSDictionary *dic = [KaraokeIMJsonHandle getSeatInfoJsonStrWithIndex:seatIndex info:changeInfo];
    [self modifyRoomAttributes:dic callback:callback];
}

- (void)muteSeat:(NSInteger)seatIndex mute:(BOOL)mute callback:(KaraokeCallback)callback {
    if (!callback) {
        callback = ^(int code, NSString* message){};
    }
    if (!self.isOwner) {
        callback(-1, @"seat info list is empty or index error.");
        return;
    }
    if (seatIndex < 0 || seatIndex >= self.seatInfoList.count) {
        callback(-1, @"seat info list is empty or index error.");
        return;
    }
    KaraokeSeatInfo *info = self.seatInfoList[seatIndex];
    KaraokeSeatInfo *changeInfo = [[KaraokeSeatInfo alloc] init];
    changeInfo.status = info.status;
    changeInfo.user = info.user;
    changeInfo.mute = mute;
    NSDictionary *dic = [KaraokeIMJsonHandle getSeatInfoJsonStrWithIndex:seatIndex info:changeInfo];
    [self modifyRoomAttributes:dic callback:callback];
}

- (void)closeSeat:(NSInteger)seatIndex isClose:(BOOL)isClose callback:(KaraokeCallback)callback {
    if (!callback) {
        callback = ^(int code, NSString* message){};
    }
    if (!self.isOwner) {
        callback(-1, @"seat info list is empty or index error.");
        return;
    }
    if (seatIndex < 0 || seatIndex >= self.seatInfoList.count) {
        callback(-1, @"seat info list is empty or index error.");
        return;
    }
    KaraokeSeatInfo *info = self.seatInfoList[seatIndex];
    if (info.status == kKaraokeSeatStatusUsed) {
        callback(-1, @"seat is used, can't closed.");
        return;
    }
    if (info.status == isClose ? kKaraokeSeatStatusClose : kKaraokeSeatStatusUnused) {
        callback(-1, [NSString stringWithFormat:@"seat is already %@", isClose ? @"close" : @"open"]);
        return;
    }
    KaraokeSeatInfo *changeInfo = [[KaraokeSeatInfo alloc] init];
    changeInfo.status = isClose ? kKaraokeSeatStatusClose : kKaraokeSeatStatusUnused;
    changeInfo.user = @"";
    changeInfo.mute = info.mute;
    NSDictionary *dic = [KaraokeIMJsonHandle getSeatInfoJsonStrWithIndex:seatIndex info:changeInfo];
    [self modifyRoomAttributes:dic callback:callback];
}

- (void)getUserInfo:(NSArray<NSString *> *)userList callback:(KaraokeUserListCallback)callback {
    if (!self.isEnterRoom) {
        if (callback) {
            callback(gKaraoke_SERVICE_CODE_ERROR, @"get user info list fail, not enter room yet", @[]);
        }
        return;
    }
    if (!userList || userList.count == 0) {
        if (callback) {
            callback(gKaraoke_SERVICE_CODE_ERROR, @"get user info list fail, user id list is empty.", @[]);
        }
        return;
    }
    [self.imManager getUsersInfo:userList succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
        NSMutableArray *txUserInfo = [[NSMutableArray alloc] initWithCapacity:2];
        [infoList enumerateObjectsUsingBlock:^(V2TIMUserFullInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            KaraokeUserInfo *userInfo = [[KaraokeUserInfo alloc] init];
            userInfo.userName = obj.nickName ?: @"";
            userInfo.userId = obj.userID ?: @"";
            userInfo.avatarURL = obj.faceURL ?: @"";
            [txUserInfo addObject:userInfo];
        }];
        if (callback) {
            callback(0, @"success", txUserInfo);
        }
    } fail:^(int code, NSString *desc) {
        if (callback) {
            callback(code, desc ?: @"get user info failed", @[]);
        }
    }];
}

- (void)sendRoomTextMsg:(NSString *)msg callback:(KaraokeCallback)callback {
    if (!self.isEnterRoom) {
        if (callback) {
            callback(-1, @"send room text fail. not enter room yet.");
        }
        return;
    }
    [self.imManager sendGroupTextMessage:msg to:self.roomInfo.roomId priority:V2TIM_PRIORITY_NORMAL succ:^{
        if (callback) {
            callback(0, @"send gourp message success.");
        }
    } fail:^(int code, NSString *desc) {
        if (callback) {
            callback(code, desc ?: @"send group message error.");
        }
    }];
}

- (void)sendRoomCustomMsg:(NSString *)cmd message:(NSString *)message callback:(KaraokeCallback)callback {
    if (!self.isEnterRoom) {
        if (callback) {
            callback(-1, @"send room text fail. not enter room yet.");
        }
        return;
    }
    [self sendGroupMsg:[KaraokeIMJsonHandle getCusMsgJsonStrWithCmd:cmd msg:message] callback:callback];
}

- (void)sendGroupMsg:(NSString *)message callback:(KaraokeCallback)callback {
    if (!self.roomInfo.roomId || [self.roomInfo.roomId isEqualToString:@""]) {
        if (callback) {
            callback(-1, @"gourp id is wrong.please check it.");
        }
        return;
    }
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        callback(-1, @"message can't covert to data");
        return;
    }
    [self.imManager sendGroupCustomMessage:data to:self.roomInfo.roomId priority:V2TIM_PRIORITY_NORMAL succ:^{
        if (callback) {
            callback(0, @"send group message success.");
        }
    } fail:^(int code, NSString *desc) {
        TRTCLog(@"error: send group message error. error:%d, message:%@", code, desc);
        if (callback) {
            callback(code, desc);
        }
    }];
}

- (void)getAudienceList:(KaraokeUserListCallback)callback {
    [self.imManager getGroupMemberList:self.roomInfo.roomId
                                filter:V2TIM_GROUP_MEMBER_FILTER_COMMON
                               nextSeq:0
                                  succ:^(uint64_t nextSeq, NSArray<V2TIMGroupMemberFullInfo *> *memberList) {
        if (memberList) {
            NSMutableArray *resultList = [[NSMutableArray alloc] initWithCapacity:2];
            [memberList enumerateObjectsUsingBlock:^(V2TIMGroupMemberFullInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                KaraokeUserInfo *info = [[KaraokeUserInfo alloc] init];
                info.userId = obj.userID;
                info.userName = obj.nickName;
                info.avatarURL = obj.faceURL;
                [resultList addObject:info];
            }];
            if (callback) {
                callback(0, @"get audience list success.", resultList);
            }
        } else {
            if (callback) {
                callback(-1, @"get audience list fail, results is nil", @[]);
            }
        }
    } fail:^(int code, NSString *desc) {
        if (callback) {
            callback(code, desc ?: @"get sudience list fail.", @[]);
        }
    }];
}

- (void)getRoomInfoList:(NSArray<NSString *> *)roomIds calback:(KaraokeRoomInfoListCallback)callback {
    [self.imManager getGroupsInfo:roomIds succ:^(NSArray<V2TIMGroupInfoResult *> *groupResultList) {
        if (groupResultList) {
            NSMutableArray *groupResults = [[NSMutableArray alloc] initWithCapacity:2];
            NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] initWithCapacity:2];
            [groupResultList enumerateObjectsUsingBlock:^(V2TIMGroupInfoResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj && obj.info.groupID) {
                    tempDic[obj.info.groupID] = obj;
                }
            }];
            [roomIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                KaraokeRoomInfo *roomInfo = [[KaraokeRoomInfo alloc] init];
                V2TIMGroupInfoResult* groupInfo = tempDic[obj];
                if (groupInfo) {
                    roomInfo.roomId = groupInfo.info.groupID;
                    roomInfo.cover = groupInfo.info.faceURL;
                    roomInfo.memberCount = groupInfo.info.memberCount;
                    roomInfo.ownerId = groupInfo.info.owner;
                    roomInfo.roomName = groupInfo.info.groupName;
                    roomInfo.ownerName = groupInfo.info.introduction;
                }
                [groupResults addObject:roomInfo];
            }];
            if (callback) {
                callback(0, @"success.", groupResults);
            }
        } else {
            if (callback) {
                callback(-1, @"get group info failed.reslut is nil.", @[]);
            }
        }
    } fail:^(int code, NSString *desc) {
        
    }];
}

- (NSString *)sendInvitation:(NSString *)cmd userId:(NSString *)userId content:(NSString *)content callback:(KaraokeCallback)callback {
    NSDictionary *dic = @{
        gKaraoke_KEY_CMD_VERSION:@(gKaraoke_VALUE_CMD_VERSION),
        gKaraoke_KEY_CMD_BUSINESSID:gKaraoke_VALUE_CMD_BUSINESSID,
        gKaraoke_KEY_CMD_PLATFORM:gKaraoke_VALUE_CMD_PLATFORM,
        gKaraoke_KEY_CMD_EXTINFO:@"",
        gKaraoke_KEY_CMD_DATA:@{
                gKaraoke_KEY_CMD_ROOMID:@(self.roomInfo.roomId.intValue),
                gKaraoke_KEY_CMD_CMD:cmd,
                gKaraoke_KEY_CMD_SEATNUMBER:content,
        },
    };
    NSString *jsonString = [dic mj_JSONString];
    return [self.imManager invite:userId data:jsonString onlineUserOnly:YES offlinePushInfo:nil timeout:0 succ:^{
        TRTCLog(@"send invitation success.");
        if (callback) {
            callback(0, @"send invitation success.");
        }
    } fail:^(int code, NSString *desc) {
        TRTCLog(@"send invitation failed");
        if (callback) {
            callback(code, desc ?: @"send invatiaon failed");
        }
    }];
}

- (void)acceptInvitation:(NSString *)identifier callback:(KaraokeCallback)callback {
    TRTCLog(@"accept %@", identifier);
    NSDictionary *dic = @{
        gKaraoke_KEY_CMD_VERSION:@(gKaraoke_VALUE_CMD_VERSION),
        gKaraoke_KEY_CMD_BUSINESSID:gKaraoke_VALUE_CMD_BUSINESSID,
        gKaraoke_KEY_CMD_PLATFORM:gKaraoke_VALUE_CMD_PLATFORM,
    };
    NSString *jsonString = [dic mj_JSONString];
    [self.imManager accept:identifier data:jsonString succ:^{
        TRTCLog(@"accept invitation success.");
        if (callback) {
            callback(0, @"accept invitation success.");
        }
    } fail:^(int code, NSString *desc) {
        TRTCLog(@"accept invitation failed");
        if (callback) {
            callback(code, desc ?: @"accept invatiaon failed");
        }
    }];
}

- (void)rejectInvitaiton:(NSString *)identifier callback:(KaraokeCallback)callback {
    TRTCLog(@"reject %@", identifier);
    NSDictionary *dic = @{
        gKaraoke_KEY_CMD_VERSION:@(gKaraoke_VALUE_CMD_VERSION),
        gKaraoke_KEY_CMD_BUSINESSID:gKaraoke_VALUE_CMD_BUSINESSID,
        gKaraoke_KEY_CMD_PLATFORM:gKaraoke_VALUE_CMD_PLATFORM,
    };
    NSString *jsonString = [dic mj_JSONString];
    [self.imManager reject:identifier data:jsonString succ:^{
        TRTCLog(@"reject invitation success.");
        if (callback) {
            callback(0, @"reject invitation success.");
        }
    } fail:^(int code, NSString *desc) {
        TRTCLog(@"reject invitation failed");
        if (callback) {
            callback(code, desc ?: @"reject invatiaon failed");
        }
    }];
}

- (void)cancelInvitation:(NSString *)identifier callback:(KaraokeCallback)callback {
    TRTCLog(@"cancel %@", identifier);
    NSDictionary *dic = @{
        gKaraoke_KEY_CMD_VERSION:@(gKaraoke_VALUE_CMD_VERSION),
        gKaraoke_KEY_CMD_BUSINESSID:gKaraoke_VALUE_CMD_BUSINESSID,
        gKaraoke_KEY_CMD_PLATFORM:gKaraoke_VALUE_CMD_PLATFORM,
    };
    NSString *jsonString = [dic mj_JSONString];
    [self.imManager cancel:identifier data:jsonString succ:^{
        TRTCLog(@"cancel invitation success.");
        if (callback) {
            callback(0, @"cancel invitation success.");
        }
    } fail:^(int code, NSString *desc) {
        TRTCLog(@"cancel invitation success.");
        if (callback) {
            callback(0, @"cancel invitation success.");
        }
    }];
}
#pragma mark - V2TIMSDKListener

#pragma mark - V2TIMSimpleMsgListener
- (void)onRecvC2CTextMessage:(NSString *)msgID sender:(V2TIMUserInfo *)info text:(NSString *)text {
    
}

- (void)onRecvC2CCustomMessage:(NSString *)msgID sender:(V2TIMUserInfo *)info customData:(NSData *)data {
    
}

- (void)onRecvGroupTextMessage:(NSString *)msgID groupID:(NSString *)groupID sender:(V2TIMGroupMemberInfo *)info text:(NSString *)text {
    TRTCLog(@"im get tet msg group:%@, userId:%@, text:%@", groupID, info.userID, text);
    if (![groupID isEqualToString:self.roomInfo.roomId]) {
        return;
    }
    KaraokeUserInfo* userInfo = [[KaraokeUserInfo alloc] init];
    userInfo.userId = info.userID;
    userInfo.avatarURL = info.faceURL;
    userInfo.userName = info.nickName;
    if ([self canDelegateResponseMethod:@selector(onRoomRecvRoomTextMsg:message:userInfo:)]) {
        [self.observer onRoomRecvRoomTextMsg:self.roomInfo.roomId message:text userInfo:userInfo];
    }
}

- (void)onRecvGroupCustomMessage:(NSString *)msgID groupID:(NSString *)groupID sender:(V2TIMGroupMemberInfo *)info customData:(NSData *)data {
    TRTCLog(@"im get custom msg group:%@, userId:%@, text:%@", groupID, info.userID, data);
    if (![groupID isEqualToString:self.roomInfo.roomId]) {
        return;
    }
    if (!data) {
        return;
    }
    
    NSString* jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary* dic = [jsonString mj_JSONObject];
    
    NSDictionary *dicData = dic[@"data"];
    if (![dicData isKindOfClass:[NSDictionary class]]) {
        dicData = @{};
    }
    if ([dicData.allKeys containsObject:@"instruction"] || [dic.allKeys containsObject:@"instruction"]) {
        return;
    }
    NSString *version = [dic objectForKey:gKaraoke_KEY_ATTR_VERSION];
    if (!version || ![version isEqualToString:gKaraoke_VALUE_ATTR_VERSION]) {
        TRTCLog(@"protocol version is not match, ignore msg");
        return;
    }
    NSNumber* action = [dic objectForKey:gKaraoke_KEY_CMD_ACTION];
    if (!action) {
        TRTCLog(@"action can't parse from data");
        return;
    }
    int actionValue = [action intValue];
    switch (actionValue) {
        case kKaraokeCodeUnknown:
            break;
        case kKaraokeCodeCustomMsg:
        {
            NSDictionary *cusPair = [KaraokeIMJsonHandle parseCusMsgWithJsonDic:dic];
            KaraokeUserInfo *userInfo = [[KaraokeUserInfo alloc] init];
            userInfo.userId = info.userID;
            userInfo.avatarURL = info.faceURL;
            userInfo.userName = info.nickName;
            if ([self canDelegateResponseMethod:@selector(onRoomRecvRoomCustomMsg:cmd:message:userInfo:)]) {
                [self.observer onRoomRecvRoomCustomMsg:self.roomInfo.roomId cmd:cusPair[@"cmd"] message:cusPair[@"message"] userInfo:userInfo];
            }
        }
            break;
        case kKaraokeCodeDestroy:
        {
            [self exitRoom:nil];
            if ([self canDelegateResponseMethod:@selector(onRoomDestroyWithRoomId:)]) {
                [self.observer onRoomDestroyWithRoomId:self.roomInfo.roomId];
            }
        }
            break;
        default:
            break;
    }
}
#pragma mark - V2TIMGroupListener
- (void)onMemberEnter:(NSString *)groupID memberList:(NSArray<V2TIMGroupMemberInfo *> *)memberList{
    if (![groupID isEqualToString:self.roomInfo.roomId]) {
        return;
    }
    [memberList enumerateObjectsUsingBlock:^(V2TIMGroupMemberInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        KaraokeUserInfo* userInfo = [[KaraokeUserInfo alloc] init];
        userInfo.userId = obj.userID;
        userInfo.avatarURL = obj.faceURL;
        userInfo.userName = obj.nickName;
        if ([self canDelegateResponseMethod:@selector(onRoomAudienceEnter:)]) {
            [self.observer onRoomAudienceEnter:userInfo];
        }
    }];
}

- (void)onMemberLeave:(NSString *)groupID member:(V2TIMGroupMemberInfo *)member{
    if (![groupID isEqualToString:self.roomInfo.roomId]) {
        return;
    }
    if (!member) {
        return;
    }
    KaraokeUserInfo *userInfo = [[KaraokeUserInfo alloc] init];
    userInfo.userId = member.userID;
    userInfo.avatarURL = member.faceURL;
    userInfo.userName = member.nickName;
    if ([self canDelegateResponseMethod:@selector(onRoomAudienceLeave:)]) {
        [self.observer onRoomAudienceLeave:userInfo];
    }
}

- (void)onGroupDismissed:(NSString *)groupID opUser:(V2TIMGroupMemberInfo *)opUser{
    if (![groupID isEqualToString:self.roomInfo.roomId]) {
        return;
    }
    [self unInitIMListener];
    if ([self canDelegateResponseMethod:@selector(onRoomDestroyWithRoomId:)]) {
        [self.observer onRoomDestroyWithRoomId:groupID];
    }
}

- (void)onGroupAttributeChanged:(NSString *)groupID attributes:(NSMutableDictionary<NSString *,NSString *> *)attributes {
    TRTCLog(@"on group attr changed:%@", attributes);
    if (![groupID isEqualToString:self.roomInfo.roomId]) {
        return;
    }
    if (!attributes) {
        TRTCLog(@"on group attr changed:: attributes is empty");
        return;
    }
    // 解析roomInfo
    KaraokeRoomInfo* roomInfo = [KaraokeIMJsonHandle getRoomInfoFromAttr:attributes];
    if (roomInfo) {
        roomInfo.roomId = self.roomInfo.roomId;
        roomInfo.memberCount = -1; // 当前房间的MemberCount无法从这个接口正确获取。
        self.roomInfo = roomInfo;
        if ([self canDelegateResponseMethod:@selector(onRoomInfoChange:)]) {
            [self.observer onRoomInfoChange:roomInfo];
        }
    }
    if (self.roomInfo.seatSize == 0) {
        TRTCLog(@"on group attr changed: but room seatSize is 0");
        return;
    }
    // 更新 seatInfo
    [self onSeatAttrMapChangedWithAttributes:attributes seatSize:self.roomInfo.seatSize];
    
}

#pragma mark - 群属性麦位更新
/// 群属性回调麦位信息更新
/// @param attributes 群属性信息
/// @param seatSize 麦位数量
- (void)onSeatAttrMapChangedWithAttributes:(NSDictionary<NSString *, NSString *> *)attributes seatSize:(NSInteger)seatSize{
    
    NSArray<KaraokeSeatInfo *> *seatInfoList = [KaraokeIMJsonHandle getSeatListFromAttr:attributes seatSize:seatSize];
    if (self.seatInfoList == nil) {
        NSMutableArray <KaraokeSeatInfo *> *seatInfoList = [NSMutableArray array];
        for (int i = 0; i < seatSize; i++) {
            KaraokeSeatInfo *seatInfo = [[KaraokeSeatInfo alloc] init];
            [seatInfoList addObject:seatInfo];
        }
        self.seatInfoList = [seatInfoList copy];
    }
    NSArray<KaraokeSeatInfo *> *oldSeatInfoList = [self.seatInfoList copy];
    self.seatInfoList = [seatInfoList mutableCopy];
    
    if ([self canDelegateResponseMethod:@selector(onSeatInfoListChange:)]) {
        [self.observer onSeatInfoListChange:self.seatInfoList];
    }
    
    for (int i = 0; i < seatSize; i+=1) {
        KaraokeSeatInfo *old = oldSeatInfoList[i];
        KaraokeSeatInfo *new = self.seatInfoList[i];
        if (old.status != new.status) {
            switch (new.status) {
                case kKaraokeSeatStatusUnused:
                    if (old.status == kKaraokeSeatStatusClose) {
                        [self onSeatcloseWithIndex:i isClose:NO];
                    } else {
                        [self onSeatLeaveWithIndex:i user:old.user];
                    }
                    break;
                case kKaraokeSeatStatusUsed:
                    [self onSeatTakeWithIndex:i user:new.user];
                    break;
                case kKaraokeSeatStatusClose:
                    [self onSeatcloseWithIndex:i isClose:YES];
                    break;
                default:
                    break;
            }
        }
        if (old.mute != new.mute) {
            [self onSeatMuteWithIndex:i mute:new.mute];
        }
    }
}

#pragma mark - V2TIMSignalingListener
- (void)onReceiveNewInvitation:(NSString *)inviteID
                       inviter:(NSString *)inviter
                       groupID:(NSString *)groupID
                   inviteeList:(NSArray<NSString *> *)inviteeList
                          data:(NSString *)data {
    NSDictionary *dic = [data mj_JSONObject];
    if (![dic isKindOfClass:[NSDictionary class]]) {
        TRTCLog(@"parse data error");
        return;
    }
    NSInteger version = [[dic objectForKey:gKaraoke_KEY_CMD_VERSION] integerValue];
    if (version < gKaraoke_VALUE_CMD_BASIC_VERSION) {
        TRTCLog(@"protocol version is nil or not match, ignore c2c msg");
        return;
    }
    NSString *businessID = [dic objectForKey:gKaraoke_KEY_CMD_BUSINESSID];
    if (!businessID || ![businessID isEqualToString:gKaraoke_VALUE_CMD_BUSINESSID]) {
        TRTCLog(@"bussiness id error");
        return;
    }
    
    NSDictionary *cmdData = [dic objectForKey:gKaraoke_KEY_CMD_DATA];
    NSString *cmd = [cmdData objectForKey:gKaraoke_KEY_CMD_CMD];
    NSString *content = [cmdData objectForKey:gKaraoke_KEY_CMD_SEATNUMBER];
    int roomID = [[cmdData objectForKey:gKaraoke_KEY_CMD_ROOMID] intValue];
    if ([self.roomInfo.roomId intValue] != roomID) {
        TRTCLog(@"room id is not right");
        return;
    }
    if ([self canDelegateResponseMethod:@selector(onReceiveNewInvitationWithIdentifier:inviter:cmd:content:)]) {
        [self.observer onReceiveNewInvitationWithIdentifier:inviteID inviter:inviter cmd:cmd content:content];
    }
}

- (void)onInviteeAccepted:(NSString *)inviteID invitee:(NSString *)invitee data:(NSString *)data {
    if ([self canDelegateResponseMethod:@selector(onInviteeAcceptedWithIdentifier:invitee:)]) {
        [self.observer onInviteeAcceptedWithIdentifier:inviteID invitee:invitee];
    }
}

-(void)onInviteeRejected:(NSString *)inviteID invitee:(NSString *)invitee data:(NSString *)data {
    if ([self canDelegateResponseMethod:@selector(onInviteeRejectedWithIdentifier:invitee:)]) {
        [self.observer onInviteeRejectedWithIdentifier:inviteID invitee:invitee];
    }
}

- (void)onInvitationCancelled:(NSString *)inviteID inviter:(NSString *)inviter data:(NSString *)data {
    if ([self canDelegateResponseMethod:@selector(onInviteeCancelledWithIdentifier:invitee:)]) {
        [self.observer onInviteeCancelledWithIdentifier:inviteID invitee:inviter];
    }
}

#pragma mark - private method
- (V2TIMManager *)imManager {
    return [V2TIMManager sharedInstance];
}

- (BOOL)isOwner {
    return [[TUILogin getUserID] isEqualToString:self.ownerUserId];
}

- (BOOL)canDelegateResponseMethod:(SEL)method {
    return self.observer && [self.observer respondsToSelector:method];
}

- (void)onSeatTakeWithIndex:(NSInteger)index user:(NSString *)userId {
    TRTCLog(@"onSeatTake: %ld, user: %@", (long)index, userId);
    @weakify(self)
    [self getUserInfo:@[userId] callback:^(int code, NSString * _Nonnull message, NSArray<KaraokeUserInfo *> * _Nonnull userInfos) {
        @strongify(self)
        if (!self) { return; }
        KaraokeUserInfo *userInfo = [[KaraokeUserInfo alloc] init];
        if (code == 0 && userInfos.count > 0) {
            userInfo = userInfos[0];
        } else {
            TRTCLog(@"onSeat Take get user info error!");
            userInfo.userId = userId;
        }
        if ([self canDelegateResponseMethod:@selector(onSeatTakeWithIndex:userInfo:)]) {
            [self.observer onSeatTakeWithIndex:index userInfo:userInfo];
        }
    }];
}

- (void)onSeatLeaveWithIndex:(NSInteger)index user:(NSString *)userId {
    TRTCLog(@"onSeatLeave: %ld, user: %@", (long)index, userId);
    @weakify(self)
    [self getUserInfo:@[userId] callback:^(int code, NSString * _Nonnull message, NSArray<KaraokeUserInfo *> * _Nonnull userInfos) {
        @strongify(self)
        if (!self) { return; }
        KaraokeUserInfo *userInfo = [[KaraokeUserInfo alloc] init];
        if (code == 0 && userInfos.count > 0) {
            userInfo = userInfos[0];
        } else {
            TRTCLog(@"onSeat Take get user info error!");
            userInfo.userId = userId;
        }
        if ([self canDelegateResponseMethod:@selector(onSeatLeaveWithIndex:userInfo:)]) {
            [self.observer onSeatLeaveWithIndex:index userInfo:userInfo];
        }
    }];
}

- (void)onSeatcloseWithIndex:(NSInteger)index isClose:(BOOL)isClose {
    TRTCLog(@"onSeatClose: %ld", (long)index);
    if ([self canDelegateResponseMethod:@selector(onSeatCloseWithIndex:isClose:)]) {
        [self.observer onSeatCloseWithIndex:index isClose:isClose];
    }
}

- (void)onSeatMuteWithIndex:(NSInteger)index mute:(BOOL)mute {
    TRTCLog(@"onSeatMute: %ld, mute:%d", (long)index, mute);
    if ([self canDelegateResponseMethod:@selector(onSeatMuteWithIndex:mute:)]) {
        [self.observer onSeatMuteWithIndex:index mute:mute];
    }
}

- (void)initImListener {
    [self.imManager addGroupListener:self];
    // 设置前先remove下，防止在单例的情况下重复设置
    [self.imManager removeSignalingListener:self];
    [self.imManager removeSimpleMsgListener:self];
    [self.imManager addSignalingListener:self];
    [self.imManager addSimpleMsgListener:self];
}

- (void)unInitIMListener {
    [self.imManager addGroupListener:nil];
    [self.imManager removeSignalingListener:self];
    [self.imManager removeSimpleMsgListener:self];
}

- (void)initRoomAttributes:(KaraokeCallback _Nullable)callback {
    @weakify(self)
    [self.imManager initGroupAttributes:self.roomInfo.roomId
                             attributes:[KaraokeIMJsonHandle getInitRoomDicWithRoomInfo:self.roomInfo seatInfoList:self.seatInfoList]
                                   succ:^{
        @strongify(self)
        if (!self) { return; }
        self.isEnterRoom = YES;
        if (callback) {
            callback(0, @"init room info and seat success");
        }
    } fail:^(int code, NSString *desc) {
        @strongify(self)
        if (!self) { return; }
        TRTCLog(@"init room info and seat failed");
        if (callback) {
            callback(code, desc ?: @"init room info and seat failed");
        }
    }];
}

- (void)getGroupAttributesWithRoomId:(NSString *)roomId callback:(KaraokeCallback _Nullable)callback {
    @weakify(self)
    [self.imManager getGroupAttributes:roomId keys:nil succ:^(NSMutableDictionary<NSString *,NSString *> *groupAttributeList) {
        @strongify(self)
        if (!self) { return; }
        if (groupAttributeList.count == 0 && [self.roomInfo.ownerId isEqualToString:[TUILogin getUserID]]) {
            // 房主未初始化IM群属性 初始化IM群属性
            [self initRoomAttributes:^(int code, NSString * _Nonnull message) {
                @strongify(self)
                if (!self) { return; }
                if (code == 0) {
                    // IM群属性初始化完成 再次获取群属性;
                    [self getGroupAttributesWithRoomId:roomId callback:callback];
                } else if (code == gERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT) {
                    TRTCLog(@"init room attrs conflict, now get room attrs");
                    [self getGroupAttributesWithRoomId:roomId callback:callback];
                } else {
                    if (callback) {
                        callback(code, message);
                    }
                }
            }];
            return;
        }
        // 解析roomInfo
        KaraokeRoomInfo* roomInfo = [KaraokeIMJsonHandle getRoomInfoFromAttr:groupAttributeList];
        if (roomInfo) {
            roomInfo.roomId = roomId;
            roomInfo.memberCount = -1; // 当前房间的MemberCount无法从这个接口正确获取。
            self.roomInfo = roomInfo;
        } else {
            TRTCLog(@"group room info is empty, enter room failed.");
            if (callback) {
                callback(-1, @"group room info is empty, enter room failed.");
            }
            return;
        }
        TRTCLog(@"enter room successed.");
        self.isEnterRoom = true;
        self.ownerUserId = self.roomInfo.ownerId;
        if (callback) {
            callback(0, @"enter rooom success");
        }
        // 更新麦位信息
        [self onSeatAttrMapChangedWithAttributes:groupAttributeList seatSize:self.roomInfo.seatSize];
        if ([self canDelegateResponseMethod:@selector(onRoomInfoChange:)]) {
            [self.observer onRoomInfoChange:self.roomInfo];
        }
    } fail:^(int code, NSString *desc) {
        if (callback) {
            callback(code, desc ?: @"get group attr error");
        }
    }];
}

- (void)cleanGroupAttributes {
    [self.imManager deleteGroupAttributes:self.roomInfo.roomId keys:nil succ:nil fail:nil];
}

- (void)modifyRoomAttributes:(NSDictionary<NSString *, NSString *> *)attrs callback:(KaraokeCallback _Nullable)callback {
    TRTCLog(@"start modify group attrs: %@", attrs);
    @weakify(self)
    [self.imManager setGroupAttributes:self.roomInfo.roomId attributes:attrs succ:^{
        if (callback) {
            callback(0, @"modify group attrs success");
        }
    } fail:^(int code, NSString *desc) {
        if (code == gERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT) {
            @strongify(self)
            TRTCLog(@"modify group attrs conflict, now get group attrs");
            [self getGroupAttributesWithRoomId:self.roomInfo.roomId callback:nil];
        }
        if (callback) {
            callback(code, desc ?: @"modify group attrs failed");
        }
    }];
}

- (void)setGroupInfoWithRoomId:(NSString *)roomId roomName:(NSString *)roomName coverUrl:(NSString *)coverUrl userName:(NSString *)userName {
    V2TIMGroupInfo *info = [[V2TIMGroupInfo alloc] init];
    info.groupID = roomId;
    info.groupName = roomName;
    info.faceURL = coverUrl;
    info.introduction = userName;
    [self.imManager setGroupInfo:info succ:^{
        TRTCLog(@"success: set group info success.");
    } fail:^(int code, NSString *desc) {
        TRTCLog(@"fail: set group info fail.");
    }];
}

@end

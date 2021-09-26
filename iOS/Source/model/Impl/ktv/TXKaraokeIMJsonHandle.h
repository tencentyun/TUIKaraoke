//
//  TXKaraokeIMJsonHandle.h
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/7/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TXKaraokeBaseDef.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* Karaoke_KEY_ATTR_VERSION = @"version";
static NSString* Karaoke_VALUE_ATTR_VERSION = @"1.0";
static NSString* Karaoke_KEY_ROOM_INFO = @"roomInfo";
static NSString* Karaoke_KEY_SEAT = @"seat";

//static NSString* Karaoke_KEY_CMD_VERSION = @"version";
//static NSString* Karaoke_VALUE_CMD_VERSION = @"1.0";
static NSString* Karaoke_KEY_CMD_ACTION = @"action";

static NSString* Karaoke_KEY_INVITATION_VERSION = @"version";
static NSString* Karaoke_VALUE_INVITATION_VERSION = @"1.0";
static NSString* Karaoke_KEY_INVITATION_CMD = @"command";
static NSString* Karaoke_KEY_INVITAITON_CONTENT = @"content";

static NSString* Karaoke_KEY_CMD_VERSION = @"version";
static NSString* Karaoke_KEY_CMD_BUSINESSID = @"businessID";
static NSString* Karaoke_KEY_CMD_PLATFORM = @"platform";
static NSString* Karaoke_KEY_CMD_EXTINFO = @"extInfo";
static NSString* Karaoke_KEY_CMD_DATA = @"data";
static NSString* Karaoke_KEY_CMD_ROOMID = @"room_id";
static NSString* Karaoke_KEY_CMD_CMD = @"cmd";
static NSString* Karaoke_KEY_CMD_SEATNUMBER = @"seat_number";
static NSString* Karaoke_KEY_CMD_INSTRUCTION = @"instruction";
static NSString* Karaoke_KEY_CMD_CONTENT = @"content";

static NSInteger Karaoke_VALUE_CMD_BASIC_VERSION = 1;
static NSInteger Karaoke_VALUE_CMD_VERSION = 1;
static NSString* Karaoke_VALUE_CMD_BUSINESSID = @"Karaoke";
static NSString* Karaoke_VALUE_CMD_PLATFORM = @"iOS";
static NSString* Karaoke_VALUE_CMD_PICK = @"pickSeat";
static NSString* Karaoke_VALUE_CMD_TAKE = @"takeSeat";
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MPREPARE = @"m_prepare";
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MCOMPLETE = @"m_complete";
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MPLAYMUSIC = @"m_play_music";
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MSTOP = @"m_stop";
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MLISTCHANGE = @"m_list_change";//歌曲列表发生改变->IM消息标记
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MPICK = @"m_pick";//把歌曲加入->IM消息标记
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MDELETE = @"m_delete";
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MTOP = @"m_top";
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MNEXT = @"m_next";
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MGETLIST = @"m_get_list";
static NSString* Karaoke_VALUE_CMD_INSTRUCTION_MDELETEALL = @"m_delete_all";


typedef NS_ENUM(NSUInteger, TXKaraokeCustomCodeType) {
    kKaraokeCodeUnknown = 0,
    kKaraokeCodeDestroy = 200,
    kKaraokeCodeCustomMsg = 301,
};

@interface TXKaraokeIMJsonHandle : NSObject

+ (NSDictionary<NSString *, NSString *> *)getInitRoomDicWithRoomInfo:(TXKaraokeRoomInfo *)roominfo seatInfoList:(NSArray<TXKaraokeSeatInfo *> *)seatInfoList;

+ (NSDictionary<NSString *, NSString *> *)getSeatInfoListJsonStrWithSeatInfoList:(NSArray<TXKaraokeSeatInfo *> *)seatInfoList;

+ (NSDictionary<NSString *, NSString *> *)getSeatInfoJsonStrWithIndex:(NSInteger)index info:(TXKaraokeSeatInfo *)info;

+ (TXKaraokeRoomInfo * _Nullable)getRoomInfoFromAttr:(NSDictionary<NSString *, NSString *> *)attr;

+ (NSArray<TXKaraokeSeatInfo *> * _Nullable)getSeatListFromAttr:(NSDictionary<NSString *, NSString *> *)attr seatSize:(NSUInteger)seatSize;

+ (NSString *)getInvitationMsgWithRoomId:(NSString *)roomId cmd:(NSString *)cmd content:(NSString *)content;

+ (TXKaraokeInviteData * _Nullable)parseInvitationMsgWithJson:(NSString *)json;

+ (NSString *)getRoomdestroyMsg;

+ (NSString *)getCusMsgJsonStrWithCmd:(NSString *)cmd msg:(NSString *)msg;

+ (NSDictionary<NSString *, NSString *> *)parseCusMsgWithJsonDic:(NSDictionary *)jsonDic;

+ (NSDictionary *)makeInstruction:(NSString *)cmd roomID:(int)roomID;

@end

NS_ASSUME_NONNULL_END

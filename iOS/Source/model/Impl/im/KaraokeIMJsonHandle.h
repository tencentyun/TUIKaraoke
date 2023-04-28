//
//  KaraokeIMJsonHandle.h
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/7/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRTCKaraokeRoomDef.h"
#import "KaraokeModelDef.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* gKaraoke_KEY_ATTR_VERSION = @"version";
static NSString* gKaraoke_VALUE_ATTR_VERSION = @"1.0";
static NSString* gKaraoke_KEY_ROOM_INFO = @"roomInfo";
static NSString* gKaraoke_KEY_SEAT = @"seat";

//static NSString* Karaoke_KEY_CMD_VERSION = @"version";
//static NSString* Karaoke_VALUE_CMD_VERSION = @"1.0";
static NSString* gKaraoke_KEY_CMD_ACTION = @"action";

static NSString* gKaraoke_KEY_INVITATION_VERSION = @"version";
static NSString* gKaraoke_VALUE_INVITATION_VERSION = @"1.0";
static NSString* gKaraoke_KEY_INVITATION_CMD = @"command";
static NSString* gKaraoke_KEY_INVITAITON_CONTENT = @"content";

static NSString* gKaraoke_KEY_CMD_VERSION = @"version";
static NSString* gKaraoke_KEY_CMD_BUSINESSID = @"businessID";
static NSString* gKaraoke_KEY_CMD_PLATFORM = @"platform";
static NSString* gKaraoke_KEY_CMD_EXTINFO = @"extInfo";
static NSString* gKaraoke_KEY_CMD_DATA = @"data";
static NSString* gKaraoke_KEY_CMD_ROOMID = @"room_id";
static NSString* gKaraoke_KEY_CMD_CMD = @"cmd";
static NSString* gKaraoke_KEY_CMD_SEATNUMBER = @"seat_number";
static NSString* gKaraoke_KEY_CMD_INSTRUCTION = @"instruction";
static NSString* gKaraoke_KEY_CMD_CONTENT = @"content";
static NSString* gKaraoke_KEY_CMD_SELECTED_MUSIC = @"selected_music";

static NSInteger gKaraoke_VALUE_CMD_BASIC_VERSION = 1;
static NSInteger gKaraoke_VALUE_CMD_VERSION = 1;
static NSString* gKaraoke_VALUE_CMD_BUSINESSID = @"Karaoke";
static NSString* gKaraoke_VALUE_CMD_PLATFORM = @"iOS";
static NSString* gKaraoke_VALUE_CMD_PICK = @"pickSeat";
static NSString* gKaraoke_VALUE_CMD_TAKE = @"takeSeat";
static NSString* gKaraoke_VALUE_CMD_MUSICNAME = @"music_name";
static NSString* gKaraoke_VALUE_CMD_USERID = @"user_id";
static NSString* gKaraoke_VALUE_CMD_INSTRUCTION_MLISTCHANGE = @"m_list_change";//歌曲列表发生改变->IM消息标记
static NSString* gKaraoke_VALUE_CMD_INSTRUCTION_MTOP = @"m_top";
static NSString* gKaraoke_VALUE_CMD_INSTRUCTION_MNEXT = @"m_next";


typedef NS_ENUM(NSUInteger, TXKaraokeCustomCodeType) {
    kKaraokeCodeUnknown = 0,
    kKaraokeCodeDestroy = 200,
    kKaraokeCodeCustomMsg = 301,
};

@interface KaraokeIMJsonHandle : NSObject

+ (NSDictionary<NSString *, NSString *> *)getInitRoomDicWithRoomInfo:(KaraokeRoomInfo
 *)roominfo seatInfoList:(NSArray<KaraokeSeatInfo *> *)seatInfoList;

+ (NSDictionary<NSString *, NSString *> *)getSeatInfoListJsonStrWithSeatInfoList:(NSArray<KaraokeSeatInfo *> *)seatInfoList;

+ (NSDictionary<NSString *, NSString *> *)getSeatInfoJsonStrWithIndex:(NSInteger)index info:(KaraokeSeatInfo *)info;

+ (KaraokeRoomInfo * _Nullable)getRoomInfoFromAttr:(NSDictionary<NSString *, NSString *> *)attr;

+ (NSArray<KaraokeSeatInfo *> * _Nullable)getSeatListFromAttr:(NSDictionary<NSString *, NSString *> *)attr seatSize:(NSUInteger)seatSize;

+ (NSString *)getInvitationMsgWithRoomId:(NSString *)roomId cmd:(NSString *)cmd content:(NSString *)content;

+ (KaraokeInviteData * _Nullable)parseInvitationMsgWithJson:(NSString *)json;

+ (NSString *)getRoomdestroyMsg;

+ (NSString *)getCusMsgJsonStrWithCmd:(NSString *)cmd msg:(NSString *)msg;

+ (NSDictionary<NSString *, NSString *> *)parseCusMsgWithJsonDic:(NSDictionary *)jsonDic;

+ (NSDictionary *)makeInstruction:(NSString *)cmd roomID:(int)roomID;

@end

NS_ASSUME_NONNULL_END

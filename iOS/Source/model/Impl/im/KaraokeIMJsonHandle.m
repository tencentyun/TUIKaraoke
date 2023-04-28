//
//  KaraokeIMJsonHandle.m
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/7/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "KaraokeIMJsonHandle.h"
#import "MJExtension.h"

@implementation KaraokeIMJsonHandle

+ (NSDictionary<NSString *,NSString *> *)getInitRoomDicWithRoomInfo:(KaraokeRoomInfo *)roominfo
 seatInfoList:(NSArray<KaraokeSeatInfo *> *)seatInfoList{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:2];
    [result setValue:gKaraoke_KEY_ATTR_VERSION forKey:gKaraoke_VALUE_ATTR_VERSION];
    NSString *jsonRoomInfo = [roominfo mj_JSONString];
    [result setValue:jsonRoomInfo forKey:gKaraoke_KEY_ROOM_INFO];
    for (int index = 0; index < seatInfoList.count; index += 1) {
        NSString *jsonInfo = [seatInfoList[index] mj_JSONString];
        NSString *key = [NSString stringWithFormat:@"%@%d", gKaraoke_KEY_SEAT, index];
        [result setValue:jsonInfo forKey:key];
    }
    return result;
}

+ (NSDictionary<NSString *,NSString *> *)getSeatInfoListJsonStrWithSeatInfoList:(NSArray<KaraokeSeatInfo *> *)seatInfoList {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:2];
    [seatInfoList enumerateObjectsUsingBlock:^(KaraokeSeatInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = [NSString stringWithFormat:@"%@%lu", gKaraoke_KEY_SEAT, (unsigned long)idx];
        [result setValue:obj forKey:key];
    }];
    return result;
}

+ (NSDictionary<NSString *,NSString *> *)getSeatInfoJsonStrWithIndex:(NSInteger)index info:(KaraokeSeatInfo *)info {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:2];
    NSString *json = [info mj_JSONString];
    NSString *key = [NSString stringWithFormat:@"%@%ld", gKaraoke_KEY_SEAT, (long)index];
    [result setValue:json forKey:key];
    return result;
}

+ (KaraokeRoomInfo *)getRoomInfoFromAttr:(NSDictionary<NSString *,NSString *> *)attr {
    NSString *jsonStr = [attr objectForKey:gKaraoke_KEY_ROOM_INFO];
    return [KaraokeRoomInfo mj_objectWithKeyValues:jsonStr];
}

+ (NSArray<KaraokeSeatInfo *> *)getSeatListFromAttr:(NSDictionary<NSString *,NSString *> *)attr seatSize:(NSUInteger)seatSize {
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:2];
    for (int index = 0; index < seatSize; index += 1) {
        NSString *key = [NSString stringWithFormat:@"%@%d", gKaraoke_KEY_SEAT, index];
        NSString *jsonStr = [attr objectForKey:key];
        if (jsonStr) {
            KaraokeSeatInfo *seatInfo = [KaraokeSeatInfo mj_objectWithKeyValues:jsonStr];
            [result addObject:seatInfo];
        } else {
            KaraokeSeatInfo *seatInfo = [[KaraokeSeatInfo alloc] init];
            [result addObject:seatInfo];
        }
    }
    return result;
}

+ (NSString *)getInvitationMsgWithRoomId:(NSString *)roomId cmd:(NSString *)cmd content:(NSString *)content {
    KaraokeInviteData *data = [[KaraokeInviteData alloc] init];
    data.roomId = roomId;
    data.command = cmd;
    data.message = content;
    NSString *jsonString = [data mj_JSONString];
    return jsonString;
}

+ (KaraokeInviteData *)parseInvitationMsgWithJson:(NSString *)json {
    return [KaraokeInviteData mj_objectWithKeyValues:json];
}

+ (NSString *)getRoomdestroyMsg {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:2];
    [result setValue:gKaraoke_VALUE_ATTR_VERSION forKey:gKaraoke_KEY_ATTR_VERSION];
    [result setValue:@(kKaraokeCodeDestroy) forKey:gKaraoke_KEY_CMD_ACTION];
    return [result mj_JSONString];
}

+ (NSString *)getCusMsgJsonStrWithCmd:(NSString *)cmd msg:(NSString *)msg {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:2];
    [result setValue:gKaraoke_VALUE_ATTR_VERSION forKey:gKaraoke_KEY_ATTR_VERSION];
    [result setValue:@(kKaraokeCodeCustomMsg) forKey:gKaraoke_KEY_CMD_ACTION];
    [result setValue:cmd forKey:gKaraoke_KEY_INVITATION_CMD];
    [result setValue:msg forKey:@"message"];
    return [result mj_JSONString];
}

+ (NSDictionary<NSString *,NSString *> *)parseCusMsgWithJsonDic:(NSDictionary *)jsonDic {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:2];
    result[@"cmd"] = [jsonDic objectForKey:gKaraoke_KEY_INVITATION_CMD] ?: @"";
    result[@"message"] = [jsonDic objectForKey:@"message"] ?: @"";
    return result;
}

+ (NSDictionary *)makeInstruction:(NSString *)cmd roomID:(int)roomID {
    NSDictionary *result = @{
        gKaraoke_KEY_CMD_VERSION : @(gKaraoke_VALUE_CMD_VERSION),
        gKaraoke_KEY_CMD_BUSINESSID : gKaraoke_VALUE_CMD_BUSINESSID,
        gKaraoke_KEY_CMD_PLATFORM : gKaraoke_VALUE_CMD_PLATFORM,
        gKaraoke_KEY_CMD_DATA : @{
            gKaraoke_KEY_CMD_ROOMID : @(roomID),
            gKaraoke_KEY_CMD_INSTRUCTION : cmd
        }
    };
    return result;
}
@end

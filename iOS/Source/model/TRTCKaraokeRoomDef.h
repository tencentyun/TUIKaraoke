//
//  TRTCKaraokeRoomDef.h
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KaraokeSeatStatus) {
    kKaraokeSeatStatusUnused = 0,
    kKaraokeSeatStatusUsed = 1,
    kKaraokeSeatStatusClose = 2,
};

NS_ASSUME_NONNULL_BEGIN
// 群属性写冲突，请先拉取最新的群属性后再尝试写操作，IMSDK5.6及其以上版本支持，麦位信息已经发生变化，需要重新拉取
static int gERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT = 10056;

@interface KaraokeSeatInfo : NSObject
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic,  copy ) NSString *user;
@end

@interface KaraokeRoomParam : NSObject
@property (nonatomic,  copy ) NSString *roomName;
@property (nonatomic,  copy ) NSString *coverUrl;
@property (nonatomic, assign) BOOL needRequest;
@property (nonatomic, assign) NSInteger seatCount;
@property (nonatomic, strong) NSArray<KaraokeSeatInfo *> *seatInfoList;
@end

@interface KaraokeUserInfo : NSObject
@property (nonatomic,  copy ) NSString *userId;
@property (nonatomic,  copy ) NSString *userName;
@property (nonatomic,  copy ) NSString *avatarURL;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign) int networkLevel;
@end

@interface KaraokeRoomInfo : NSObject
@property (nonatomic,  copy ) NSString *roomId;
@property (nonatomic,  copy ) NSString *ownerId;
@property (nonatomic,  copy ) NSString *ownerName;
@property (nonatomic,  copy ) NSString *roomName;
@property (nonatomic,  copy ) NSString *cover;
@property (nonatomic, assign) NSInteger seatSize;
@property (nonatomic, assign) NSInteger needRequest;
@property (nonatomic, assign) NSInteger memberCount;

- (instancetype)initWithRoomID:(NSString *)roomId ownerId:(NSString *)ownerId memberCount:(NSInteger)memberCount;
@end

typedef void(^KaraokeCallback)(int code, NSString *message);
typedef void(^KaraokeUserListCallback)(int code, NSString *message, NSArray<KaraokeUserInfo *> *userInfos);
typedef void(^KaraokeRoomInfoListCallback)(int code, NSString *message, NSArray<KaraokeRoomInfo *> *roomInfos);

NS_ASSUME_NONNULL_END

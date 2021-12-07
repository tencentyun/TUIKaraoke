//
//  TRTCKaraokeRoomDef.h
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 群属性写冲突，请先拉取最新的群属性后再尝试写操作，IMSDK5.6及其以上版本支持，麦位信息已经发生变化，需要重新拉取
static int ERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT = 10056;

@interface SeatInfo : NSObject

@property (nonatomic, assign) NSInteger status;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic,  copy ) NSString *userId;

@end

@interface RoomParam : NSObject

@property (nonatomic,  copy ) NSString *roomName;
@property (nonatomic,  copy ) NSString *coverUrl;
@property (nonatomic, assign) BOOL needRequest;
@property (nonatomic, assign) NSInteger seatCount;
@property (nonatomic, strong) NSArray<SeatInfo *> *seatInfoList;


@end

@interface UserInfo : NSObject

@property (nonatomic,  copy ) NSString *userId;
@property (nonatomic,  copy ) NSString *userName;
@property (nonatomic,  copy ) NSString *userAvatar;
@property (nonatomic, assign) BOOL mute;

@end

@interface RoomInfo : NSObject

@property (nonatomic, assign) NSInteger roomID;
@property (nonatomic,  copy ) NSString *roomName;
@property (nonatomic,  copy ) NSString *coverUrl;
@property (nonatomic,  copy ) NSString *ownerId;
@property (nonatomic,  copy ) NSString *ownerName;
@property (nonatomic, assign) NSInteger memberCount;
@property (nonatomic, assign) BOOL needRequest;

-(instancetype)initWithRoomID:(NSInteger)roomID ownerId:(NSString *)ownerId memberCount:(NSInteger)memberCount;

@end

typedef void(^ActionCallback)(int code, NSString * _Nonnull message);
typedef void(^KaraokeInfoCallback)(int code, NSString * _Nonnull message, NSArray<RoomInfo * > * _Nonnull roomInfos);
typedef void(^KaraokeUserListCallback)(int code, NSString * _Nonnull message, NSArray<UserInfo * > * _Nonnull userInfos);

NS_ASSUME_NONNULL_END

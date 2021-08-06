//
//  TRTCKaraokeRoomDef.m
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "TRTCKaraokeRoomDef.h"

@implementation RoomParam

@end

@implementation SeatInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.status = 0;
        self.mute = NO;
        self.userId = @"";
    }
    return self;
}

@end

@implementation UserInfo

- (instancetype)init {
    if (self = [super init]) {
        self.mute = YES;
    }
    return self;
}

- (void)setUserName:(NSString *)userName{
    if (!userName) {
        userName = @"";
    }
    _userName = userName;
}

- (void)setUserAvatar:(NSString *)userAvatar{
    if (!userAvatar) {
        userAvatar = @"";
    }
    _userAvatar = userAvatar;
}

@end

@implementation RoomInfo

-(instancetype)initWithRoomID:(NSInteger)roomID ownerId:(NSString *)ownerId memberCount:(NSInteger)memberCount {
    self = [super init];
    if (self) {
        self.roomID = roomID;
        self.ownerId = ownerId;
        self.memberCount = memberCount;
    }
    return self;
}

@end

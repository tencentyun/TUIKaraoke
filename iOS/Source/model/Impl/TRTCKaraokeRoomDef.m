//
//  TRTCKaraokeRoomDef.m
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "TRTCKaraokeRoomDef.h"

@implementation KaraokeSeatInfo

- (instancetype)init {
    if (self = [super init]) {
        self.status = 0;
        self.mute = NO;
        self.user = @"";
    }
    return self;
}

@end


@implementation KaraokeRoomParam

@end

@implementation KaraokeUserInfo

- (instancetype)init {
    if (self = [super init]) {
        self.mute = NO;
    }
    return self;
}

- (void)setUserName:(NSString *)userName {
    if (!userName) {
        userName = @"";
    }
    _userName = userName;
}

- (void)setAvatarURL:(NSString *)avatarURL {
    if (!avatarURL) {
        avatarURL = @"";
    }
    _avatarURL = avatarURL;
}

@end

@implementation KaraokeRoomInfo

// 默认值与业务逻辑统一
-(instancetype)initWithRoomID:(NSString *)roomId ownerId:(NSString *)ownerId memberCount:(NSInteger)memberCount {
    if (self = [super init]) {
        self.roomId = roomId;
        self.ownerId = ownerId;
        self.memberCount = memberCount;
        self.needRequest = YES;
    }
    return self;
}

@end

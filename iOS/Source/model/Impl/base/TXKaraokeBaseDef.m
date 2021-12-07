//
//  TXKaraokeBaseDef.m
//  TRTCKaraokeOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "TXKaraokeBaseDef.h"
#import "TRTCCloud.h"

@interface TRTCCloud (KaraokeLog)

// 打印一些关键log到本地日志中
- (void)apiLog:(NSString *)log;

@end

void TUIKaraokeLog(NSString *format, ...){
    if (!format || ![format isKindOfClass:[NSString class]] || format.length == 0) {
        return;
    }
    va_list arguments;
    va_start(arguments, format);
    NSString *content = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    if (content) {
        [[TRTCCloud sharedInstance] apiLog:content];
    }
}

@implementation TXKaraokeRoomInfo

// 默认值与业务逻辑统一
- (instancetype)init {
    if (self = [super init]) {
        self.needRequest = YES;
    }
    return self;
}

@end

@implementation TXKaraokeUserInfo


@end

@implementation TXKaraokeSeatInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.status = 0;
        self.mute = NO;
        self.user = @"";
    }
    return self;
}

@end

@implementation TXKaraokeInviteData


@end

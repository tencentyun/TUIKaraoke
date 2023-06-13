//
//  KaraokeLogger.m
//  TUIKaraoke
//
//  Created by adams on 2023/3/20.
//  Copyright © 2023 tencent. All rights reserved.
//

#import "KaraokeLogger.h"
#import "TXLiteAVSDK_TRTC/TRTCCloud.h"

@interface TRTCCloud (KaraokeLog)

// 打印一些关键log到本地日志中
- (void)apiLog:(NSString *)log;

@end

void tuiKaraokeLog(NSString *format, ...){
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

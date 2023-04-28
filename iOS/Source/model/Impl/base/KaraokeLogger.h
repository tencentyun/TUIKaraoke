//
//  KaraokeLogger.h
//  TUIKaraoke
//
//  Created by adams on 2023/3/20.
//  Copyright © 2023 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT void tuiKaraokeLog(NSString * _Nullable format, ...);
// 使用TRTCCloud apiLog，日志会写入本地
#define TRTCLog(fmt, ...) tuiKaraokeLog((@"TRTC LOG:%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

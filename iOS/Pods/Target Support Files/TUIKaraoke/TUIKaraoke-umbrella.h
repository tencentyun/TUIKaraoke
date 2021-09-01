#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "KaraokeLocalized.h"
#import "TXKaraokeBaseDef.h"
#import "TXKaraokeCommonDef.h"
#import "TXKaraokeIMJsonHandle.h"
#import "TXKaraokeService.h"
#import "KaraokeTRTCService.h"
#import "TRTCKaraokeRoom.h"
#import "TRTCKaraokeRoomDef.h"
#import "TRTCKaraokeRoomDelegate.h"
#import "TUIKaraokeKit.h"

FOUNDATION_EXPORT double TUIKaraokeVersionNumber;
FOUNDATION_EXPORT const unsigned char TUIKaraokeVersionString[];


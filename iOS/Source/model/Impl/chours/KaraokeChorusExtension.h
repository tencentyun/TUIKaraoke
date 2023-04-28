//
//  KaraokeChorusExtension.h
//  TUIKaraoke
//
//  Created by adams on 2022/8/23.
//  Copyright © 2022 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KaraokeChorusExtensionObserver.h"

@class TRTCCloud;
@class TRTCParams;

NS_ASSUME_NONNULL_BEGIN

@interface KaraokeChorusExtension : NSObject
@property (nonatomic, weak) id<KaraokeChorusExtensionObserver> observer;
@property (nonatomic, assign, readonly) BOOL isChorusOn;    ///是否在合唱中
@property (nonatomic, assign) BOOL isOriginMusic;           ///是否为原唱

/**
 * 初始化合唱扩展
 * @param voiceCloud 人声实例
 * @param bgmCloud   背景音乐实例
 */
- (instancetype)initWithVoiceCloud:(TRTCCloud *)voiceCloud bgmCloud:(nullable TRTCCloud *)bgmCloud;

/**
 * 开始合唱
 * 调用后，会收到 onChorusStart 回调，并且房间内的远端用户也会开始合唱
 * @param musicId      歌曲ID
 * @param originalUrl  歌曲URL
 * @param accompanyUrl 伴奏URL
 * @param reason 开始合唱的身份
 * @note 中途加入的用户也会一并开始合唱，音乐进度会与其它用户自动对齐
 */
- (BOOL)startChorus:(NSString *)musicId originalUrl:(NSString *)originalUrl accompanyUrl:(NSString *)accompanyUrl reason:(ChorusStartReason)reason;

/**
 * 停止合唱
 */
- (void)stopChorus;

/**
 * 接收TRTCCloudDelegate回调消息
 * @param userId 用户Id
 * @param cmdId 命令Id
 * @param seq   消息序号
 * @param message 消息数据
 */
- (void)onRecvCustomCmdMsgUserId:(NSString *)userId
                           cmdID:(NSInteger)cmdId
                             seq:(UInt32)seq
                         message:(NSData *)message;

@end

NS_ASSUME_NONNULL_END

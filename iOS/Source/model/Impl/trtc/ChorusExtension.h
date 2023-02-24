//
//  ChorusExtension.h
//  TUIKaraoke
//
//  Created by adams on 2022/8/23.
//  Copyright © 2022 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TRTCCloud;
@class TRTCParams;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ChorusStartReason) {
    // 本地用户发起合唱（主播端）
    ChorusStartReasonLocal  = 0,
    // 远端某个用户发起合唱（上麦观众）
    ChorusStartReasonRemote = 1,
};

typedef NS_ENUM(NSInteger, ChorusStopReason) {
    // 合唱音乐起播失败，被迫终止
    ChorusStopReasonMusicFailed = 0,
    // 远端某个用户请求停止合唱（上麦观众）
    ChorusStopReasonRemote = 1,
    // 本地用户停止合唱（主播端）
    ChorusStopReasonLocal = 2,
    // 合唱歌曲播放完毕，自动停止
    ChorusStopReasonMusicFinished = 3,
};

@protocol ChorusExtensionDelegate <NSObject>
/**
 * 合唱已开始
 * 您可以监听这个接口来处理 UI 和业务逻辑
 */
- (void)onChorusStart:(ChorusStartReason)reason message:(NSString *)msg;

/**
 * 合唱已停止
 * 您可以监听这个接口来处理 UI 和业务逻辑
 */
- (void)onChorusStop:(ChorusStopReason)reason message:(NSString *)msg;

/**
 * 准备播放音乐的回调
 * @param musicID 准备播放的音乐ID
 * @note 监听此回调用来更新歌词显示UI
 */
- (void)onMusicPrepareToPlay:(int32_t)musicID;

/**
 * 音乐播放结束的回调
 * @param musicID 准备播放的音乐ID
 * @note 监听此回调用来结束显示正在播放的歌词UI
 */
- (void)onMusicCompletePlaying:(int32_t)musicID;

/**
 * 合唱音乐进度回调
 * 您可以监听这个接口来处理进度条和歌词的滚动
 */
- (void)onMusicProgressUpdate:(int32_t)musicID progress:(NSInteger)progress duration:(NSInteger)durationMS;

/**
 * 接收到发起合唱的消息的回调
 * @param musicID    合唱的歌曲ID
 * @param startDelay 合唱的歌曲延迟秒数
 * @note 此回调将musicId回传出去用来对接曲库查询歌曲信息并调用歌曲播放接口
 */
- (void)onReceiveAnchorSendChorusMsg:(NSString *)musicID startDelay:(NSInteger)startDelay;

/**
 * 更新网络NTP时间回调
 * @param errCode       错误码
 * @param errMsg        错误信息
 * @param retryHandler  重新更新网络时间
 * @note 此回调将返回更新NTP网络时间出错时的错误码和错误信息
 */
- (void)onUpdateNetworkTime:(int)errCode message:(NSString *)errMsg retryHandler:(void (^)(BOOL shouldRetry))retryHandler;
@end

@interface ChorusExtension : NSObject
@property (nonatomic, weak) id<ChorusExtensionDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL isChorusOn;    ///是否在合唱中
@property (nonatomic, assign) BOOL isOriginMusic;           ///是否为原唱

/**
 * 初始化合唱扩展
 * @param voiceCloud 人声实例
 * @param bgmCloud   背景音乐实例
 */
- (instancetype)initWithVoiceCloud:(TRTCCloud *)voiceCloud bgmCloud:(TRTCCloud *)bgmCloud;

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
 * 调用后，会收到 onChorusStop 回调，并且房间内的远端用户也会停止合唱
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
/**
 *  创建混流机器人
 * @param userId 用户Id
 * @param roomId 房间Id
 * @param taskId 混流Id
 */
- (void)createMixStreamRobot:(NSString *)userId roomId:(UInt32)roomId taskId:(NSString *)taskId;

@end

NS_ASSUME_NONNULL_END

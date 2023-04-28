//
//  KaraokeChorusExtensionObserver.h
//  Pods
//
//  Created by adams on 2023/4/10.
//  Copyright © 2023 tencent. All rights reserved.
//

#ifndef KaraokeChorusExtensionObserver_h
#define KaraokeChorusExtensionObserver_h

typedef NS_ENUM(NSInteger, ChorusStartReason) {
    // 本地用户发起合唱（主播端）
    ChorusStartReasonLocal  = 0,
    // 远端某个用户发起合唱（上麦观众）
    ChorusStartReasonRemote = 1,
};

@protocol KaraokeChorusExtensionObserver <NSObject>
/**
 * 合唱已开始
 * 您可以监听这个接口来处理 UI 和业务逻辑
 */
- (void)onChorusStart:(ChorusStartReason)reason message:(NSString *)msg;

/**
 * 音乐播放失败的回调
 * @param musicID   准备播放的音乐ID
 * @param errorCode 错误码
 * @param message   错误信息
 * @note 监听此回调用来更新歌词显示UI
 */
- (void)onMusicPlayError:(int32_t)musicID errorCode:(NSInteger)errorCode message:(NSString *)message;

/**
 * 音乐播放结束的回调
 * @param musicID 准备播放的音乐ID
 * @note 监听此回调用来结束显示正在播放的歌词UI
 */
- (void)onMusicPlayCompleted:(int32_t)musicID;

/**
 * 合唱音乐进度回调
 * 您可以监听这个接口来处理进度条和歌词的滚动
 */
- (void)onMusicProgressUpdate:(int32_t)musicID progress:(NSInteger)progress duration:(NSInteger)durationMS;

/**
 * 接收到发起合唱的消息的回调
 * @param musicID       合唱的歌曲ID
 * @param startDelay    合唱的歌曲延迟秒数
 * @note 此回调将musicId回传出去用来对接曲库查询歌曲信息并调用歌曲播放接口
 */
- (void)onReceiveAnchorSendChorusMsg:(NSString *)musicID startDelay:(NSInteger)startDelay;

/**
 * 接收到合唱伴奏切换的消息的回调
 * @param musicID       合唱的歌曲ID
 * @param isOriginal    合唱的歌曲是否为原声
 * @note 此回调将musicId回传出去用来对接曲库查询歌曲信息并调用歌曲播放接口
 */
- (void)onMusicAccompanimentModeChanged:(NSString *)musicID isOriginal:(BOOL)isOriginal;
@end

#endif /* KaraokeChorusExtensionObserver_h */

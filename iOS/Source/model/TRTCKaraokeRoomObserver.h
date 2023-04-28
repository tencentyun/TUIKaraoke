//
//  TRTCKaraokeRoomObserver.h
//  TXLiteAVDemo
//
//  Created by abyyxwang on 2020/7/8.
//  Copyright © 2020 Tencent. All rights reserved.
//

#ifndef TRTCKaraokeRoomObserver_h
#define TRTCKaraokeRoomObserver_h

#import "TRTCKaraokeRoomDef.h"

NS_ASSUME_NONNULL_BEGIN

@class TRTCVolumeInfo;
@class TRTCStatistics;
@class TRTCQualityInfo;

@protocol TRTCKaraokeRoomObserver <NSObject>

/// 错误回调
/// @param code 错误码
/// @param message 错误信息
- (void)onError:(int)code
                message:(NSString*)message
NS_SWIFT_NAME(onError(code:message:));

/// 警告回调
/// @param code 警告码
/// @param message 警告信息
- (void)onWarning:(int)code
                  message:(NSString *)message
NS_SWIFT_NAME(onWarning(code:message:));

/// Debug日志
/// @param message 信息
- (void)onDebugLog:(NSString *)message
NS_SWIFT_NAME(onDebugLog(message:));

/// 房间销毁回调
/// @param message 销毁信息
- (void)onRoomDestroy:(NSString *)message
NS_SWIFT_NAME(onRoomDestroy(message:));

/// 房间信息变更回调
/// @param roomInfo 房间信息
- (void)onRoomInfoChange:(KaraokeRoomInfo *)roomInfo
NS_SWIFT_NAME(onRoomInfoChange(roomInfo:));

/// 房间作为变更回调
/// @param seatInfolist 座位列表信息
- (void)onSeatInfoChange:(NSArray<KaraokeSeatInfo *> *)seatInfolist
NS_SWIFT_NAME(onSeatListChange(seatInfoList:));

/// 主播上麦回调
/// @param index 麦位号
/// @param user 用户信息
- (void)onAnchorEnterSeat:(NSInteger)index
                     user:(KaraokeUserInfo *)user
NS_SWIFT_NAME(onAnchorEnterSeat(index:user:));

/// 主播下麦回调
/// @param index 麦位号
/// @param user 用户信息
- (void)onAnchorLeaveSeat:(NSInteger)index
                     user:(KaraokeUserInfo *)user
NS_SWIFT_NAME(onAnchorLeaveSeat(index:user:));

/// 座位静音状态回调
/// @param index 座位号
/// @param isMute 静音状态
- (void)onSeatMute:(NSInteger)index
            isMute:(BOOL)isMute
NS_SWIFT_NAME(onSeatMute(index:isMute:));

/// 用户麦克风是否静音回调
/// @param userId 用户id
/// @param mute 是否静音
- (void)onUserMicrophoneMute:(NSString *)userId mute:(BOOL)mute
NS_SWIFT_NAME(onUserMicrophoneMute(userId:mute:));

/// 座位关闭回调
/// @param index 座位号
/// @param isClose 是否关闭
- (void)onSeatClose:(NSInteger)index
            isClose:(BOOL)isClose
NS_SWIFT_NAME(onSeatClose(index:isClose:));

/// 观众进房回调
/// @param userInfo 观众信息
- (void)onAudienceEnter:(KaraokeUserInfo *)userInfo
NS_SWIFT_NAME(onAudienceEnter(userInfo:));

/// 观众退房回调
/// @param userInfo 观众信息
- (void)onAudienceExit:(KaraokeUserInfo *)userInfo
NS_SWIFT_NAME(onAudienceExit(userInfo:));

/// 上麦成员的音量变化
/// @param userVolumes 各个用户音量信息
/// @param totalVolume 整体音量信息
- (void)onUserVolumeUpdate:(NSArray<TRTCVolumeInfo *> *)userVolumes totalVolume:(NSInteger)totalVolume
NS_SWIFT_NAME(onUserVolumeUpdate(userVolumes:totalVolume:));

/// 文本消息接收回调
/// @param message 消息内容
/// @param userInfo 消息发送方信息
- (void)onRecvRoomTextMsg:(NSString *)message
                 userInfo:(KaraokeUserInfo *)userInfo
NS_SWIFT_NAME(onRecvRoomTextMsg(message:userInfo:));

/// 自定义消息（信令消息）接收回调
/// @param cmd 信令
/// @param message 消息内容
/// @param userInfo 发送方信息
- (void)onRecvRoomCustomMsg:(NSString *)cmd
                    message:(NSString *)message
                   userInfo:(KaraokeUserInfo *)userInfo
NS_SWIFT_NAME(onRecvRoomCustomMsg(cmd:message:userInfo:));

/// 邀请信息接收回调
/// @param identifier 目标用户ID
/// @param inviter 邀请者ID
/// @param cmd 信令
/// @param content 内容
- (void)onReceiveNewInvitation:(NSString *)identifier
                       inviter:(NSString *)inviter
                           cmd:(NSString *)cmd
                       content:(NSString *)content
NS_SWIFT_NAME(onReceiveNewInvitation(identifier:inviter:cmd:content:));

/// 邀请被接受回调
/// @param identifier 目标用户ID
/// @param invitee 邀请者ID
- (void)onInviteeAccepted:(NSString *)identifier
                  invitee:(NSString *)invitee
NS_SWIFT_NAME(onInviteeAccepted(identifier:invitee:));

/// 邀请被拒绝回调
/// @param identifier 目标用户ID
/// @param invitee 邀请者ID
- (void)onInviteeRejected:(NSString *)identifier
                  invitee:(NSString *)invitee
NS_SWIFT_NAME(onInviteeRejected(identifier:invitee:));

/// 邀请被取消回调
/// @param identifier 目标用户ID
/// @param invitee 邀请者ID
- (void)onInvitationCancelled:(NSString *)identifier
                      invitee:(NSString *)invitee NS_SWIFT_NAME(onInvitationCancelled(identifier:invitee:));

/// 歌曲播放进度的回调
/// @param musicID 播放时传入的 music ID
/// @param progress 当前播放时间 / ms
/// @param total 总时间 / ms
- (void)onMusicProgressUpdate:(int32_t)musicID
                     progress:(NSInteger)progress
                        total:(NSInteger)total
NS_SWIFT_NAME(onMusicProgressUpdate(musicID:progress:total:));

/// 播放音乐完成回调
/// @param musicID 播放时传入的 music ID
- (void)onMusicPlayCompleted:(int32_t)musicID
NS_SWIFT_NAME(onMusicPlayCompleted(musicID:));

/// 接收到房主发送的合唱消息回调
/// @param musicId    合唱的歌曲 music ID
/// @param startDelay 合唱的歌曲 延迟多少秒播放
- (void)onReceiveAnchorSendChorusMsg:(NSString *)musicId startDelay:(NSInteger)startDelay
NS_SWIFT_NAME(onReceiveAnchorSendChorusMsg(musicId:startDelay:));

/// 接收到房主切换音乐类型
/// @param musicId  合唱的歌曲 ID
/// @param isOrigin 合唱的歌曲 原唱/伴奏
- (void)onMusicAccompanimentModeChanged:(NSString *)musicId isOrigin:(BOOL)isOrigin
NS_SWIFT_NAME(onMusicAccompanimentModeChanged(musicId:isOrigin:));

/// 获取UserSign
/// @param userId UserId
- (void)genUserSign:(NSString *)userId completion:(void (^)(NSString *userSign))completion
NS_SWIFT_NAME(genUserSign(userId:completion:));

/// 更新网络NTP时间回调
/// @param errCode         错误码
/// @param errMsg          错误信息
/// @param retryHandler    重新更新网络时间
- (void)onUpdateNetworkTime:(int)errCode message:(NSString *)errMsg retryHandler:(void (^)(BOOL shouldRetry))retryHandler
NS_SWIFT_NAME(onUpdateNetworkTime(errCode:message:retryHandler:));

/// TRTC网络和性能的汇总统计指标
/// @param statistics      指标对象
- (void)onStatistics:(TRTCStatistics *)statistics
NS_SWIFT_NAME(onStatistics(statistics:));

/// 更新网络质量
/// @param trtcQuality    本地网络质量
/// @param arrayList         远端网络质量
- (void)onNetWorkQuality:(TRTCQualityInfo *)trtcQuality arrayList:(NSArray<TRTCQualityInfo *> *)arrayList
NS_SWIFT_NAME(onNetWorkQuality(trtcQuality:arrayList:));

@end

NS_ASSUME_NONNULL_END


#endif /* TRTCKaraokeRoomObserver_h */



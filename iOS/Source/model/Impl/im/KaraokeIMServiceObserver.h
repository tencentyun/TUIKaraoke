//
//  KaraokeIMServiceObserver.h
//  Pods
//
//  Created by adams on 2023/3/20.
//  Copyright © 2023 tencent. All rights reserved.
//

#ifndef KaraokeIMServiceObserver_h
#define KaraokeIMServiceObserver_h

@protocol KaraokeIMServiceObserver <NSObject>
- (void)onRoomDestroyWithRoomId:(NSString *)roomID;
- (void)onRoomRecvRoomTextMsg:(NSString *)roomID message:(NSString *)message userInfo:(KaraokeUserInfo *)userInfo;
- (void)onRoomRecvRoomCustomMsg:(NSString *)roomID cmd:(NSString *)cmd message:(NSString *)message userInfo:(KaraokeUserInfo *)userInfo;
- (void)onRoomInfoChange:(KaraokeRoomInfo *)roomInfo;
- (void)onSeatInfoListChange:(NSArray<KaraokeSeatInfo *> *)seatInfoList;
- (void)onRoomAudienceEnter:(KaraokeUserInfo *)userInfo;
- (void)onRoomAudienceLeave:(KaraokeUserInfo *)userInfo;
- (void)onSeatTakeWithIndex:(NSInteger)index userInfo:(KaraokeUserInfo *)userInfo;
- (void)onSeatCloseWithIndex:(NSInteger)index isClose:(BOOL)isClose;
- (void)onSeatLeaveWithIndex:(NSInteger)index userInfo:(KaraokeUserInfo *)userInfo;
- (void)onSeatMuteWithIndex:(NSInteger)index mute:(BOOL)isMute;
- (void)onReceiveNewInvitationWithIdentifier:(NSString *)identifier inviter:(NSString *)inviter cmd:(NSString *)cmd content:(NSString *)content;
- (void)onInviteeAcceptedWithIdentifier:(NSString *)identifier invitee:(NSString *)invitee;
- (void)onInviteeRejectedWithIdentifier:(NSString *)identifier invitee:(NSString *)invitee;
- (void)onInviteeCancelledWithIdentifier:(NSString *)identifier invitee:(NSString *)invitee;
@end

#endif /* KaraokeIMServiceObserver_h */

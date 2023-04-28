package com.tencent.liteav.tuikaraoke.model.impl.im;

import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;

import java.util.List;

public interface KaraokeIMServiceObserver {
    void onRoomDestroy(String roomId);

    void onRoomRecvRoomTextMsg(String roomId, String message, TRTCKaraokeRoomDef.UserInfo userInfo);

    void onRoomRecvRoomCustomMsg(String roomId, String cmd, String message, TRTCKaraokeRoomDef.UserInfo userInfo);

    void onRoomInfoChange(TRTCKaraokeRoomDef.RoomInfo txRoomInfo);

    void onSeatInfoListChange(List<TRTCKaraokeRoomDef.SeatInfo> seatInfoList);

    void onRoomAudienceEnter(TRTCKaraokeRoomDef.UserInfo userInfo);

    void onRoomAudienceLeave(TRTCKaraokeRoomDef.UserInfo userInfo);

    void onSeatTake(int index, TRTCKaraokeRoomDef.UserInfo userInfo);

    void onSeatClose(int index, boolean isClose);

    void onSeatLeave(int index, TRTCKaraokeRoomDef.UserInfo userInfo);

    void onSeatMute(int index, boolean mute);

    void onReceiveNewInvitation(String id, String inviter, String cmd, String content);

    void onInviteeAccepted(String id, String invitee);

    void onInviteeRejected(String id, String invitee);

    void onInvitationCancelled(String id, String inviter);
}

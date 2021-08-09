package com.tencent.liteav.tuikaraoke.ui.music;

import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;

import java.util.List;

public class KaraokeMusicUtils {
    public static List<KaraokeRoomSeatEntity> mKaraokeRoomSeatEntityList;
    public static boolean                     mIsAnchor;

    //保存麦位信息
    public static void setSeatEntityList(List<KaraokeRoomSeatEntity> seatEntityList) {
        mKaraokeRoomSeatEntityList = seatEntityList;
    }

    public static List<KaraokeRoomSeatEntity> getSeatEntityList() {
        return mKaraokeRoomSeatEntityList;
    }

    //当前用户是否是主播
    public static void isAnchor(boolean isAnchor) {
        mIsAnchor = isAnchor;
    }
}

package com.tencent.liteav.tuikaraoke.ui.base;

import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;

public class MemberEntity extends TRTCKaraokeRoomDef.UserInfo {
    public static final int TYPE_IDEL         = 0;
    public static final int TYPE_IN_SEAT      = 1;
    public static final int TYPE_WAIT_AGREE   = 2;
    public static final int TYPE_ORDERED_SONG = 4;

    public int type;

}

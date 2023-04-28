package com.tencent.liteav.tuikaraoke.ui.base;

public class KaraokeRoomSeatEntity {
    public int     index;
    public String  userId;
    public String  userName;
    public String  userAvatar;
    public boolean isUsed;
    public boolean isClose;
    public boolean isSeatMute;
    public boolean isUserMute = true;
    public boolean isTalk;

    public static final int QUALITY_GOOD   = 101;
    public static final int QUALITY_NORMAL = 102;
    public static final int QUALITY_BAD    = 103;
    public static final int QUALITY_NONE   = 104;
    
    private             int quality;

    public int getQuality() {
        return quality;
    }

    public void setQuality(int quality) {
        this.quality = quality;
    }

    @Override
    public String toString() {
        return "KaraokeRoomSeatEntity{"
                + "index=" + index
                + ", userId='" + userId + '\''
                + ", userName='" + userName + '\''
                + ", userAvatar='" + userAvatar + '\''
                + ", isUsed=" + isUsed
                + ", isClose=" + isClose
                + ", isSeatMute=" + isSeatMute
                + ", isUserMute=" + isUserMute
                + ", isTalk=" + isTalk
                + ", quality=" + quality
                + '}';
    }
}

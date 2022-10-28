package com.tencent.liteav.tuikaraoke.ui.base;

public class KaraokeMusicModel extends KaraokeMusicInfo {

    public Boolean isSelected;  //歌曲是否已点,点歌的时候将该值置为true ,切歌或删除时置为false
    public boolean isReady;     //歌曲是否已经下载完毕

    @Override
    public String toString() {
        return "KaraokeMusicModel{"
                + "musicId='" + musicId + '\''
                + ", isReady=" + isReady + '\''
                + ", musicName='" + musicName + '\''
                + ", singers=" + singers
                + ", lrcUrl='" + lrcUrl + '\''
                + ", coverUrl='" + coverUrl + '\''
                + ", originUrl='" + originUrl + '\''
                + ", accompanyUrl='" + accompanyUrl + '\''
                + ", status=" + status
                + ", userId='" + userId + '\''
                + ", performId='" + performId + '\''
                + ", pos=" + pos
                + ", playToken='" + playToken + '\''
                + ", isSelected=" + isSelected
                + '}';
    }
}

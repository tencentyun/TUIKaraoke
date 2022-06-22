package com.tencent.liteav.tuikaraoke.ui.base;

public class KaraokeMusicModel extends KaraokeMusicInfo {

    public Boolean isSelected;  //歌曲是否已点,点歌的时候将该值置为true ,切歌或删除时置为false

    @Override
    public String toString() {
        return "KaraokeMusicModel{" +
                "userId='" + userId + '\'' +
                ", isSelected=" + isSelected +
                ", musicId='" + musicId + '\'' +
                ", musicName='" + musicName + '\'' +
                ", singers=" + singers +
                ", lrcUrl='" + lrcUrl + '\'' +
                ", coverUrl='" + coverUrl + '\'' +
                ", originUrl='" + originUrl + '\'' +
                ", accompanyUrl='" + accompanyUrl + '\'' +
                ", status=" + status +
                ", userId='" + userId + '\'' +
                ", performId='" + performId + '\'' +
                ", pos=" + pos +
                ", playToken='" + playToken + '\'' +
                '}';
    }
}

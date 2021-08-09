package com.tencent.liteav.tuikaraoke.ui.base;

public class KaraokeMusicModel extends KaraokeMusicInfo {

    public String  bookUser;    //点歌用户
    public Boolean isSelected;  //歌曲是否已点,点歌的时候将该值置为true ,切歌或删除时置为false

    @Override
    public String toString() {
        return "KaraokeMusicModel {" +
                "musicId='" + musicId +
                ", musicName='" + musicName + '\'' +
                ", singer='" + singer + '\'' +
                ", lrcUrl='" + lrcUrl + '\'' +
                ", contentUrl=" + contentUrl + '\'' +
                ", bookUser=" + bookUser + '\'' +
                ", isSelected=" + isSelected +
                '}';
    }
}

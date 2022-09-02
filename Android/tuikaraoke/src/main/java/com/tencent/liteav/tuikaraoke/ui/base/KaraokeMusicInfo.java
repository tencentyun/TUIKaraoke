package com.tencent.liteav.tuikaraoke.ui.base;

import java.util.List;
import java.util.Objects;

public class KaraokeMusicInfo {
    public String       musicId;       //歌曲Id
    public String       musicName;     //歌曲名称
    public List<String> singers;       //演唱者
    public String       lrcUrl;        //歌词
    public String       coverUrl;      //歌曲封面
    public String       originUrl;     //歌曲原唱Url
    public String       accompanyUrl;  //歌曲伴奏Url
    public int          status;
    public String       userId;
    public String       performId;
    public int          pos;
    public String       playToken;

    @Override
    public String toString() {
        return "KaraokeMusicInfo{"
                + "musicId='" + musicId + '\''
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
                + '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        KaraokeMusicInfo that = (KaraokeMusicInfo) o;
        return status == that.status
                && pos == that.pos
                && Objects.equals(musicId, that.musicId)
                && Objects.equals(musicName, that.musicName)
                && Objects.equals(singers, that.singers)
                && Objects.equals(lrcUrl, that.lrcUrl)
                && Objects.equals(coverUrl, that.coverUrl)
                && Objects.equals(originUrl, that.originUrl)
                && Objects.equals(accompanyUrl, that.accompanyUrl)
                && Objects.equals(userId, that.userId)
                && Objects.equals(performId, that.performId)
                && Objects.equals(playToken, that.playToken);
    }

    @Override
    public int hashCode() {
        return Objects.hash(musicId, musicName, singers, lrcUrl,
                coverUrl, originUrl, accompanyUrl, status, userId, performId, pos, playToken);
    }
}

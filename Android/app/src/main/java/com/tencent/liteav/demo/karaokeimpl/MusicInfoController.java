package com.tencent.liteav.demo.karaokeimpl;

import android.content.Context;

import androidx.core.content.ContextCompat;

import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class MusicInfoController {
    private static final String TAG = "MusicInfoController";

    private              List<KaraokeMusicInfo> mMusicLocalList;
    private static final int                    MUSIC_NUMBER = 5;
    private              String                 mPath;
    private              String                 mDefaultUrl  =
            "https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar2.png";

    public MusicInfoController(Context context) {
        mPath = ContextCompat.getExternalFilesDirs(context, null)[0].getAbsolutePath() + "/";
    }

    public KaraokeMusicInfo getSongEntity(int id) {
        if (mPath == null) {
            return null;
        }

        String houlaiAccomp = mPath + "houlai_bz.mp3";
        String houlaiOrigin = mPath + "houlai_yc.mp3";

        String qfdyOrigin = mPath + "qfdy_yc.mp3";
        String qfdyAccomp = mPath + "qfdy_bz.mp3";

        String xqAccomp = mPath + "xq_bz.mp3";
        String xqOrigin = mPath + "xq_yc.mp3";
        String nuannuanAccomp = mPath + "nuannuan_bz.mp3";
        String nuannuanOrigin = mPath + "nuannuan_yc.mp3";

        String jdaOrigin = mPath + "jda.mp3";
        String jdaAccomp = mPath + "jda_bz.mp3";

        String houlai = mPath + "houlai_lrc.vtt";
        String qfdy = mPath + "qfdy_lrc.vtt";
        String xq = mPath + "xq_lrc.vtt";
        String nuannuan = mPath + "nuannuan_lrc.vtt";
        String jda = mPath + "jda_lrc.vtt";

        KaraokeMusicInfo songEntity = new KaraokeMusicInfo();
        if (id == 0) {
            songEntity.musicId = "1001"; //test
            songEntity.musicName = "后来";
            songEntity.singers = Arrays.asList("刘若英");
            songEntity.coverUrl = mDefaultUrl;
            songEntity.lrcUrl = houlai;
            songEntity.performId = "1001";
            songEntity.originUrl = houlaiOrigin;
            songEntity.accompanyUrl = houlaiAccomp;
            return songEntity;
        } else if (id == 1) {
            songEntity.musicId = "1002"; //test
            songEntity.musicName = "情非得已";
            songEntity.singers = Arrays.asList("庾澄庆");
            songEntity.coverUrl = mDefaultUrl;
            songEntity.lrcUrl = qfdy;
            songEntity.performId = "1002";
            songEntity.originUrl = qfdyOrigin;
            songEntity.accompanyUrl = qfdyAccomp;
            return songEntity;
        } else if (id == 2) {
            songEntity.musicId = "1003"; //test
            songEntity.musicName = "星晴";
            songEntity.singers = Arrays.asList("周杰伦");
            songEntity.coverUrl = mDefaultUrl;
            songEntity.lrcUrl = xq;
            songEntity.performId = "1003";
            songEntity.originUrl = xqOrigin;
            songEntity.accompanyUrl = xqAccomp;
            return songEntity;
        } else if (id == 3) {
            songEntity.musicId = "1004"; //test
            songEntity.musicName = "暖暖";
            songEntity.singers = Arrays.asList("梁静茹");
            songEntity.coverUrl = mDefaultUrl;
            songEntity.lrcUrl = nuannuan;
            songEntity.performId = "1004";
            songEntity.originUrl = nuannuanOrigin;
            songEntity.accompanyUrl = nuannuanAccomp;
            return songEntity;
        } else if (id == 4) {
            songEntity.musicId = "1005"; //test
            songEntity.musicName = "简单爱";
            songEntity.singers = Arrays.asList("周杰伦");
            songEntity.coverUrl = mDefaultUrl;
            songEntity.lrcUrl = jda;
            songEntity.performId = "1005";
            songEntity.originUrl = jdaOrigin;
            songEntity.accompanyUrl = jdaAccomp;
            return songEntity;
        }
        return null;
    }

    public List<KaraokeMusicInfo> getLibraryList() {
        if (mMusicLocalList != null) {
            mMusicLocalList.clear();
        } else {
            mMusicLocalList = new ArrayList<>();
        }
        for (int i = 0; i < MUSIC_NUMBER; i++) {
            mMusicLocalList.add(getSongEntity(i));
        }
        return mMusicLocalList;
    }
}

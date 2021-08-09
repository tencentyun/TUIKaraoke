package com.tencent.liteav.tuikaraoke.ui.music;

import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;

import java.util.List;

public class KaraokeMusicCallback {
    /**
     * 通用回调
     */
    public interface ActionCallback {
        void onCallback(int code, String msg);
    }

    /**
     * 歌曲信息回调
     */
    public interface MusicListCallback {
        void onCallback(int code, String msg, List<KaraokeMusicInfo> list);
    }

    /**
     * 已选列表回调
     */
    public interface MusicSelectedListCallback {
        void onCallback(int code, String msg, List<KaraokeMusicModel> list);
    }

    /**
     * 下载进度回调
     */
    public interface ProgressCallback {
        void onCallback(double progress);
    }
}

package com.tencent.liteav.tuikaraoke.ui.music;

import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokePopularInfo;

import java.util.List;

public class KaraokeMusicCallback {
    /**
     * 通用回调
     */
    public interface ActionCallback {
        void onCallback(int code, String msg);
    }

    /**
     * 热门推荐分类列表回调
     */
    public interface PopularMusicListCallback {
        void onCallBack(List<KaraokePopularInfo> list);
    }

    /**
     * 歌曲信息回调
     */
    public interface MusicListCallback {
        void onCallback(int code, String msg, List<KaraokeMusicInfo> list);
    }

    /**
     * 歌曲信息分页回调
     */
    public interface MusicListPagingCallback {
        void onCallback(int code, String msg, List<KaraokeMusicInfo> list, String scrollToken);
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
    public interface MusicLoadingCallback {
        void onStart(KaraokeMusicInfo musicInfo);

        void onProgress(KaraokeMusicInfo musicInfo, float progress);

        void onFinish(KaraokeMusicInfo musicInfo, int errorCode, String errorMessage);
    }
}

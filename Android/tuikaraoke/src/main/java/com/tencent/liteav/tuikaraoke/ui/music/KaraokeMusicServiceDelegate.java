package com.tencent.liteav.tuikaraoke.ui.music;

import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;

import java.util.List;

/**
 * 已点列表回调接口
 */
public interface KaraokeMusicServiceDelegate {

    /**
     * 已点列表的更新
     *
     * @param musicInfoList 歌曲列表
     */
    void onMusicListChange(List<KaraokeMusicModel> musicInfoList);

    /**
     * 歌词设置回调
     *
     * @param model 应播放的歌曲
     */
    void onShouldSetLyric(KaraokeMusicModel model);

    /**
     * 歌曲播放回调
     *
     * @param model 事件发生的歌曲
     */
    void onShouldPlay(KaraokeMusicModel model);

    /**
     * 歌曲停止回调
     *
     * @param model 事件发生的歌曲
     */
    void onShouldStopPlay(KaraokeMusicModel model);

    /**
     * 点歌信息展示回调
     *
     * @param model 事件发生的歌曲
     */
    void onShouldShowMessage(KaraokeMusicModel model);
}


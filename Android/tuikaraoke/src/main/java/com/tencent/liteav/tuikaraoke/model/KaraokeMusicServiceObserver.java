package com.tencent.liteav.tuikaraoke.model;

import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;

import java.util.List;

/**
 * 已点列表回调接口
 */
public interface KaraokeMusicServiceObserver {

    /**
     * 已点列表的更新
     *
     * @param musicInfoList 歌曲列表
     */
    void onMusicListChanged(List<KaraokeMusicInfo> musicInfoList);
}


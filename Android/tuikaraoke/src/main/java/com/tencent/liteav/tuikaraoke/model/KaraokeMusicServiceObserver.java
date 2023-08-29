package com.tencent.liteav.tuikaraoke.model;

import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.MusicPitchModel;

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

    /**
     * 单句歌词的得分（百分制[0, 100]）
     *
     * @param currentScore 分数
     */
    void onMusicSingleScore(int currentScore);

    /**
     * 歌曲实时回调
     *
     * @param pitch       实时音高
     * @param timeStamp   歌词时间戳（播放进度）
     */
    void onMusicRealTimePitch(int pitch, float timeStamp);

    /**
     * 打分结果（百分制[0, 100]）
     *
     * @param totalScore 最终得分
     */
    void onMusicScoreFinished(int totalScore);

    /**
     * 打分准备就绪
     *
     * @param pitchModels 歌曲音高模型
     */
    void onMusicScorePrepared(List<MusicPitchModel> pitchModels);
}


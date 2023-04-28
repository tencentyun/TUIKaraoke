package com.tencent.liteav.tuikaraoke.model.impl.chorus;


public abstract class KaraokeChorusObserver {
    /**
     * 合唱进度回调
     *
     * @param curPtsMS   合唱音乐当前播放进度，单位：毫秒
     * @param durationMS 合唱音乐总时长，单位：毫秒
     */
    public abstract void onMusicPlayProgress(int musicId, long curPtsMS, long durationMS);

    /**
     * 接收到房主的合唱请求
     *
     * @param musicId 播放时传入的 music ID
     */
    public abstract void onReceiveAnchorSendChorusMsg(String musicId, boolean isOriginal);

    /**
     * 音乐播放结束回调
     *
     * @param musicId 结束播放的音乐ID
     * @note 监听此回调用来更新歌词显示UI
     */
    public abstract void onMusicPlayCompleted(int musicId);

    /**
     * 音乐伴奏类型发生变化
     *
     * @param musicId musicId  合唱的歌曲 ID
     * @param isOriginal 合唱的歌曲 原唱/伴奏
     */
    public abstract void onMusicAccompanimentModeChanged(int musicId, boolean isOriginal);
}
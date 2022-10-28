package com.tencent.liteav.tuikaraoke.ui.audio;

public interface IAudioEffectPanelDelegate {

    // 调整人声音量
    void onMicVolumeChanged(int progress);

    // 调整音乐音量
    void onMusicVolumeChanged(int progress);

    // 调整音乐升降调
    void onPitchLevelChanged(float pitch);

    // 变声效果
    void onChangeRV(int type);

    // 混响效果
    void onReverbRV(int type);
}

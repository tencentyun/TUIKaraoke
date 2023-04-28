package com.tencent.liteav.tuikaraoke.model;

import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;

public interface KaraokeAddMusicCallback {

    void onStart(KaraokeMusicInfo musicInfo);

    void onProgress(KaraokeMusicInfo musicInfo, float progress);

    void onFinish(KaraokeMusicInfo musicInfo, int errorCode, String errorMessage);
}

package com.tencent.liteav.tuikaraoke.ui.audio.impl;

import android.text.TextUtils;
import android.util.Log;

import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoom;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;

/**
 * 音乐管理
 */
public class KaraokeAudioViewModel {
    private static final String TAG = "KaraokeAudioViewModel";

    public TRTCKaraokeRoom mTRTCKaraokeRoom;

    public void setTRTCKaraokeRoom(TRTCKaraokeRoom room) {
        mTRTCKaraokeRoom = room;
    }

    public void startPlayMusic(final KaraokeMusicInfo model) {
        if (model == null || TextUtils.isEmpty(model.performId)) {
            Log.e(TAG, "startPlayMusic params illegal");
            return;
        }
        int musicId;
        try {
            musicId = Integer.parseInt(model.performId);
        } catch (NumberFormatException e) {
            TRTCLogger.e(TAG, "startPlayMusic NumberFormatException : " + e.toString());
            return;
        }

        Log.d(TAG, "startPlayMusic: model = " + model);
        mTRTCKaraokeRoom.startPlayMusic(musicId, model.originUrl, model.accompanyUrl);
    }

    public void stopPlayMusic(final KaraokeMusicInfo model) {
        Log.d(TAG, "stopPlayMusic: model = " + model);
        mTRTCKaraokeRoom.stopPlayMusic();
    }

    public void reset() {
        mTRTCKaraokeRoom.stopPlayMusic();
        mTRTCKaraokeRoom.setVoiceReverbType(0);
        mTRTCKaraokeRoom.setVoiceChangerType(0);
    }
}

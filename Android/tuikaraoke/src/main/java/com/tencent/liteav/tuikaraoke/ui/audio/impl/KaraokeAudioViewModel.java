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

    public static final int MUSIC_PLAYING  = 1;
    public static final int MUSIC_PAUSING  = 2;
    public static final int MUSIC_RESUMING = 3;
    public static final int MUSIC_STOP     = 4;

    public int mCurrentStatus = -1;

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

        int musicState = getCurrentStatus();
        Log.d(TAG, "startPlayMusic: model = " + model + " , status =  " + musicState);
        if (musicState == MUSIC_PLAYING) {
            return;
        }
        mTRTCKaraokeRoom.startPlayMusic(musicId, model.originUrl, model.accompanyUrl);
        setCurrentStatus(MUSIC_PLAYING);
    }

    public void stopPlayMusic(final KaraokeMusicInfo model) {
        Log.d(TAG, "stopPlayMusic: model = " + model + " , status =  " + getCurrentStatus());
        if (getCurrentStatus() == MUSIC_STOP) {
            return;
        }
        setCurrentStatus(MUSIC_STOP);
        mTRTCKaraokeRoom.stopPlayMusic();
    }

    public void setCurrentStatus(int status) {
        mCurrentStatus = status;
    }

    public int getCurrentStatus() {
        return mCurrentStatus;
    }

    public void reset() {
        mTRTCKaraokeRoom.stopPlayMusic();

        setCurrentStatus(-1);
        mTRTCKaraokeRoom.setVoiceReverbType(0);
        mTRTCKaraokeRoom.setVoiceChangerType(0);
    }
}

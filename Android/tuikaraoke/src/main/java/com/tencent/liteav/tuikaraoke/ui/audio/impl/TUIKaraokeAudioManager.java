package com.tencent.liteav.tuikaraoke.ui.audio.impl;

import android.util.Log;

import com.tencent.liteav.audio.TXAudioEffectManager;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoom;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.ui.audio.IAudioEffectPanelDelegate;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;

/**
 * 音乐管理
 */
public class TUIKaraokeAudioManager implements IAudioEffectPanelDelegate {
    private static final String TAG = "TUIKaraokeAudioManager";

    private static final int AUDIO_REVERB_TYPE_0        = 0;
    private static final int AUDIO_REVERB_TYPE_1        = 1;
    private static final int AUDIO_REVERB_TYPE_2        = 2;
    private static final int AUDIO_REVERB_TYPE_3        = 3;
    private static final int AUDIO_REVERB_TYPE_4        = 4;
    private static final int AUDIO_REVERB_TYPE_5        = 5;
    private static final int AUDIO_REVERB_TYPE_6        = 6;
    private static final int AUDIO_REVERB_TYPE_7        = 7;
    private static final int AUDIO_VOICECHANGER_TYPE_0  = 0;
    private static final int AUDIO_VOICECHANGER_TYPE_1  = 1;
    private static final int AUDIO_VOICECHANGER_TYPE_2  = 2;
    private static final int AUDIO_VOICECHANGER_TYPE_3  = 3;
    private static final int AUDIO_VOICECHANGER_TYPE_4  = 4;
    private static final int AUDIO_VOICECHANGER_TYPE_5  = 5;
    private static final int AUDIO_VOICECHANGER_TYPE_6  = 6;
    private static final int AUDIO_VOICECHANGER_TYPE_7  = 7;
    private static final int AUDIO_VOICECHANGER_TYPE_8  = 8;
    private static final int AUDIO_VOICECHANGER_TYPE_9  = 9;
    private static final int AUDIO_VOICECHANGER_TYPE_10 = 10;
    private static final int AUDIO_VOICECHANGER_TYPE_11 = 11;
    private static final int VOICE_MAX_VOLUME           = 117;

    public static final int MUSIC_PLAYING  = 111;
    public static final int MUSIC_PAUSING  = 112;
    public static final int MUSIC_RESUMING = 113;
    public static final int MUSIC_STOP     = 114;

    public        int                    mCurrentStatus = -1;
    private       int                    mBGMId         = -1;
    private       float                  mPitch;
    private       int                    mBGMVolume     = 30;
    private       int                    mMicVolume     = VOICE_MAX_VOLUME;
    public static TUIKaraokeAudioManager sInstance;
    public        TRTCKaraokeRoom        mTRTCKaraokeRoom;

    private static final int     TYPE_ORIGIN    = 0;     //原唱
    private static final int     TYPE_ACCOMPANY = 1;     //伴奏
    private              boolean mIsOrigin      = true;  //true:原唱;false:伴奏

    public  static synchronized TUIKaraokeAudioManager getInstance() {
        if (sInstance == null) {
            sInstance = new TUIKaraokeAudioManager();
        }
        return sInstance;
    }

    public void setTRTCKaraokeRoom(TRTCKaraokeRoom room) {
        mTRTCKaraokeRoom = room;
    }

    public void startPlayMusic(final KaraokeMusicInfo model) {
        mBGMId = Integer.parseInt(model.performId);
        resetVolume(mBGMId);

        Log.d(TAG, "startPlayMusic: model = " + model + " , status =  " + getCurrentStatus());
        if (model != null && model.performId != null) {
            mTRTCKaraokeRoom.startPlayMusic(Integer.parseInt(model.performId), model.originUrl);
        }
    }

    public void switchToOriginalVolume(boolean origin) {
        mIsOrigin = origin;
        //如果开启原唱,则调节原唱的音量,否则调节伴奏的音量
        mBGMId = mIsOrigin ? TYPE_ORIGIN : TYPE_ACCOMPANY;
        resetVolume(mBGMId);
    }

    public boolean isOriginMusic() {
        return mIsOrigin;
    }

    private void resetVolume(int id) {
        // 开始播放音乐时，无论是否首次均需重新设置变调和音量，因为音乐id发生了变化
        TXAudioEffectManager voiceEffectManager = mTRTCKaraokeRoom.getVoiceAudioEffectManager();
        TXAudioEffectManager musicEffectManager = mTRTCKaraokeRoom.getBgmMusicAudioEffectManager();
        if (voiceEffectManager != null) {
            voiceEffectManager.setVoiceCaptureVolume(mMicVolume);
        }
        if (musicEffectManager != null) {
            musicEffectManager.setMusicPlayoutVolume(id, mBGMVolume);
            musicEffectManager.setMusicPublishVolume(id, mBGMVolume);
        }
    }

    public void stopPlayMusic(final KaraokeMusicInfo model) {
        Log.d(TAG, "stopPlayMusic: model = " + model + " , status =  " + getCurrentStatus());
        if (getCurrentStatus() == MUSIC_PLAYING) {
            mTRTCKaraokeRoom.stopPlayMusic();
        }
    }

    public void pauseMusic() {
        if (MUSIC_PLAYING != getCurrentStatus()) {
            return;
        }
        mTRTCKaraokeRoom.pausePlayMusic();
        setCurrentStatus(MUSIC_PAUSING);
    }

    public void resumeMusic() {
        if (MUSIC_PLAYING != getCurrentStatus()
                && MUSIC_STOP != getCurrentStatus()
                && MUSIC_PAUSING != getCurrentStatus()) {
            mTRTCKaraokeRoom.resumePlayMusic();
            setCurrentStatus(MUSIC_PLAYING);
        }
    }

    public void setCurrentStatus(int status) {
        mCurrentStatus = status;
    }

    public int getCurrentStatus() {
        return mCurrentStatus;
    }


    @Override
    public void onMicVolumeChanged(int progress) {
        mMicVolume = VOICE_MAX_VOLUME * progress / 100;
        TXAudioEffectManager effectManager = mTRTCKaraokeRoom.getVoiceAudioEffectManager();
        if (effectManager != null) {
            TRTCLogger.i(TAG, "setVoiceCaptureVolume: mBGMId -> " + mBGMId + ", progress -> " + progress);
            effectManager.setVoiceCaptureVolume(mMicVolume);
        } else {
            TRTCLogger.e(TAG, "onMicVolumeChanged effect manager is null" + mBGMId);
        }
    }

    @Override
    public void onMusicVolumeChanged(int progress) {
        mBGMVolume = progress;
        TXAudioEffectManager effectManager = mTRTCKaraokeRoom.getBgmMusicAudioEffectManager();
        if (effectManager != null && mBGMId != -1) {
            effectManager.setMusicPlayoutVolume(mBGMId, progress);
            effectManager.setMusicPublishVolume(mBGMId, progress);
            TRTCLogger.i(TAG, "setMusicVolume: mBGMId -> " + mBGMId + ", progress -> " + progress);
        } else {
            TRTCLogger.e(TAG, "onMusicVolumeChanged effect manager is null" + mBGMId);
        }
    }

    @Override
    public void onPitchLevelChanged(float pitch) {
        mPitch = pitch;
        TXAudioEffectManager effectManager = mTRTCKaraokeRoom.getBgmMusicAudioEffectManager();
        if (effectManager != null && mBGMId != -1) {
            TRTCLogger.i(TAG, "setMusicPitch: mBGMId -> " + mBGMId + ", pitch -> " + pitch);
            effectManager.setMusicPitch(mBGMId, pitch);
        } else {
            TRTCLogger.e(TAG, "onPitchLevelChanged effect manager is null" + mBGMId);
        }
    }

    @Override
    public void onChangeRV(int type) {
        TXAudioEffectManager effectManager = mTRTCKaraokeRoom.getVoiceAudioEffectManager();
        if (effectManager != null) {
            TRTCLogger.i(TAG, "setVoiceChangerType: mBGMId -> " + mBGMId + ", type -> " + type);
            effectManager.setVoiceChangerType(translateChangerType(type));
        } else {
            TRTCLogger.e(TAG, "onChangeRV effect manager is null" + mBGMId);
        }
    }

    @Override
    public void onReverbRV(int type) {
        TXAudioEffectManager effectManager = mTRTCKaraokeRoom.getVoiceAudioEffectManager();
        if (effectManager != null) {
            TRTCLogger.i(TAG, "setVoiceReverbType: mBGMId -> " + mBGMId + ", type -> " + type);
            effectManager.setVoiceReverbType(translateReverbType(type));
        } else {
            TRTCLogger.e(TAG, "onReverbRV effect manager is null" + mBGMId);
        }
    }

    public void unInit() {
        mTRTCKaraokeRoom.stopPlayMusic();
    }

    public void reset() {
        mTRTCKaraokeRoom.stopPlayMusic();
        mBGMId = -1;

        mBGMVolume = 100;
        mPitch = 0;
        setCurrentStatus(-1);
        TXAudioEffectManager effectManager = mTRTCKaraokeRoom.getVoiceAudioEffectManager();
        if (effectManager != null) {
            Log.d(TAG, "select changer type1 " + translateChangerType(0));
            effectManager.setVoiceChangerType(translateChangerType(0));
            effectManager.setVoiceReverbType(translateReverbType(0));
        }
    }

    private TXAudioEffectManager.TXVoiceChangerType translateChangerType(int type) {
        TXAudioEffectManager.TXVoiceChangerType changerType = TXAudioEffectManager
                .TXVoiceChangerType.TXLiveVoiceChangerType_0;
        switch (type) {
            case AUDIO_VOICECHANGER_TYPE_0:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_0;
                break;
            case AUDIO_VOICECHANGER_TYPE_1:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_1;
                break;
            case AUDIO_VOICECHANGER_TYPE_2:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_2;
                break;
            case AUDIO_VOICECHANGER_TYPE_3:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_3;
                break;
            case AUDIO_VOICECHANGER_TYPE_4:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_4;
                break;
            case AUDIO_VOICECHANGER_TYPE_5:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_5;
                break;
            case AUDIO_VOICECHANGER_TYPE_6:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_6;
                break;
            case AUDIO_VOICECHANGER_TYPE_7:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_7;
                break;
            case AUDIO_VOICECHANGER_TYPE_8:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_8;
                break;
            case AUDIO_VOICECHANGER_TYPE_9:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_9;
                break;
            case AUDIO_VOICECHANGER_TYPE_10:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_10;
                break;
            case AUDIO_VOICECHANGER_TYPE_11:
                changerType = TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_11;
                break;
            default:
                break;
        }
        return changerType;
    }

    private TXAudioEffectManager.TXVoiceReverbType translateReverbType(int type) {
        TXAudioEffectManager.TXVoiceReverbType reverbType = TXAudioEffectManager
                .TXVoiceReverbType.TXLiveVoiceReverbType_0;
        switch (type) {
            case AUDIO_REVERB_TYPE_0:
                reverbType = TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_0;
                break;
            case AUDIO_REVERB_TYPE_1:
                reverbType = TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_1;
                break;
            case AUDIO_REVERB_TYPE_2:
                reverbType = TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_2;
                break;
            case AUDIO_REVERB_TYPE_3:
                reverbType = TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_3;
                break;
            case AUDIO_REVERB_TYPE_4:
                reverbType = TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_4;
                break;
            case AUDIO_REVERB_TYPE_5:
                reverbType = TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_5;
                break;
            case AUDIO_REVERB_TYPE_6:
                reverbType = TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_6;
                break;
            case AUDIO_REVERB_TYPE_7:
                reverbType = TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_7;
                break;
            default:
                break;
        }
        return reverbType;
    }
}

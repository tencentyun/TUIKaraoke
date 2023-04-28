package com.tencent.liteav.tuikaraoke.model.impl.chorus;

import android.content.Context;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.gson.Gson;
import com.tencent.liteav.audio.TXAudioEffectManager;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.model.impl.trtc.KaraokeTRTCService;
import com.tencent.rtmp.TXLiveBase;
import com.tencent.trtc.TRTCCloud;

import org.json.JSONException;
import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Timer;
import java.util.TimerTask;

public class KaraokeChorusExtension implements TXAudioEffectManager.TXMusicPlayObserver {

    private static final String TAG = "KaraokeChorusExtension";

    private static final String KEY_CMD                 = "cmd";
    private static final String KEY_MUSIC_ID            = "music_id";
    private static final String KEY_START_PLAY_MUSIC_TS = "start_play_music_ts";
    private static final String KEY_REQUEST_STOP_TS     = "request_stop_ts";
    private static final String KEY_MUSIC_DURATION      = "music_duration";
    private static final String MSG_START_CHORUS        = "start_chorus";
    private static final String MSG_STOP_CHORUS         = "stop_chorus";
    private static final String KEY_IS_ORIGIN_MUSIC     = "is_origin_music";
    private static final int    MUSIC_START_DELAY       = 3000;
    private static final int    MUSIC_PRELOAD_DELAY     = 400;
    private static final int    MESSAGE_SEND_INTERVAL   = 1000;

    private KaraokeTRTCService    mTRTCVoiceService; //人声实例
    private KaraokeTRTCService    mTRTCBgmService;   //bgm实例
    private Timer                 mTimer;
    private HandlerThread         mWorkThread;
    private Handler               mWorkHandler;
    private KaraokeChorusObserver mObserver;

    private          String  mOriginalUrl;
    private          String  mAccompanyUrl;
    private          int     mMusicID;
    private volatile long    mMusicDuration;
    private volatile boolean mIsChorusOn;
    private          long    mRevStartPlayMusicTs;
    private volatile long    mStartPlayMusicTs;
    private          long    mRequestStopPlayMusicTs;
    private          boolean mIsOriginMusic = false;
    private SimpleDateFormat mDateFormatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");


    private ChorusStartType mChorusStartType = ChorusStartType.Local;//记录开始合唱的原因，可以确定播放者身份:房主/副唱

    public KaraokeChorusExtension(@NonNull Context context, @NonNull KaraokeTRTCService voiceService) {
        this(context, voiceService, null);
    }

    public KaraokeChorusExtension(@NonNull Context context, @NonNull KaraokeTRTCService voiceService,
                                  @NonNull KaraokeTRTCService bgmService) {
        mTRTCVoiceService = voiceService;
        mTRTCBgmService = bgmService;
        mWorkThread = new HandlerThread("TRTCChorusManagerWorkThread");
        mWorkThread.start();
        mWorkHandler = new Handler(mWorkThread.getLooper());
    }

    private TXAudioEffectManager getAudioEffectManager() {
        if (mTRTCBgmService != null) {
            return mTRTCBgmService.getAudioEffectManager();
        }
        return mTRTCVoiceService.getAudioEffectManager();
    }

    public void setObserver(KaraokeChorusObserver observer) {
        mObserver = observer;
    }

    public void setOriginMusicAccompanimentMode(boolean isOriginMusic) {
        mIsOriginMusic = isOriginMusic;
    }

    /**
     * 开始合唱
     *
     * @return true：合唱启动成功；false：合唱启动失败
     */
    public boolean startChorus(int musicId, String originalUrl, String accompanyUrl, boolean isPublish) {
        TRTCLogger.i(TAG, "startChorus");
        this.mMusicID = musicId;
        this.mOriginalUrl = originalUrl;
        mAccompanyUrl = accompanyUrl;
        mMusicDuration = getAudioEffectManager().getMusicDurationInMS(mOriginalUrl);
        boolean result;
        if (mChorusStartType == ChorusStartType.Local) {
            result = startPlayMusic(mChorusStartType, MUSIC_START_DELAY, isPublish);
        } else {
            result = startPlayMusic(mChorusStartType, (int) (mRevStartPlayMusicTs - getNtpTime()), isPublish);
        }
        return result;
    }

    /**
     * 停止合唱
     */
    public void stopChorus() {
        TRTCLogger.i(TAG, "stopChorus");
        stopPlayMusic(ChorusStopReason.LocalStop);
        // stopPlayMusic 需要用到 mChorusStartType，所以 clearStatus 得随后清除；
        clearStatus();
    }

    /**
     * 清除状态
     */
    public void clearStatus() {
        mChorusStartType = ChorusStartType.Local;
    }

    /**
     * 当前是否正在合唱
     *
     * @return true：当前正在合唱中；false：当前不在合唱
     */
    public boolean isChorusOn() {
        return mIsChorusOn;
    }


    /**
     * TRTC 自定义消息回调，用于接收房间内其他用户发送的自定义消息，用于解析处理合唱相关消息
     *
     * @param userId  用户标识
     * @param cmdID   命令 ID
     * @param seq     消息序号
     * @param message 消息数据
     */
    public void onReceiveCustomCmdMsg(String userId, int cmdID, int seq, byte[] message) {
        if (!isNtpReady() || message == null || message.length <= 0) {
            return;
        }
        try {
            JSONObject json = new JSONObject(new String(message, "UTF-8"));
            if (!json.has(KEY_CMD)) {
                return;
            }

            switch (json.getString(KEY_CMD)) {
                case MSG_START_CHORUS:
                    Log.d(TAG, "receive start chorus message userId :" + userId + " mIsChorusOn:" + mIsChorusOn
                            + ", message : " + json);
                    mRevStartPlayMusicTs = json.getLong(KEY_START_PLAY_MUSIC_TS);

                    if (mRevStartPlayMusicTs < mRequestStopPlayMusicTs) {
                        // 当前收到的命令是在请求停止合唱之前发出的，需要忽略掉，否则会导致请求停止后又开启了合唱
                        return;
                    }

                    String musicId = json.optString(KEY_MUSIC_ID);
                    boolean isOriginMusic = json.getBoolean(KEY_IS_ORIGIN_MUSIC);
                    if (isOriginMusic != mIsOriginMusic && mObserver != null) {
                        mObserver.onMusicAccompanimentModeChanged(Integer.parseInt(musicId), isOriginMusic);
                    }

                    if (!mIsChorusOn && mObserver != null) {
                        mChorusStartType = ChorusStartType.Remote;
                        mObserver.onReceiveAnchorSendChorusMsg(musicId, isOriginMusic);
                    }
                    break;
                case MSG_STOP_CHORUS:
                    mRequestStopPlayMusicTs = json.getLong(KEY_REQUEST_STOP_TS);
                    TRTCLogger.i(TAG, "receive stop chorus message. stopTs:" + mRequestStopPlayMusicTs);
                    stopPlayMusic(ChorusStopReason.RemoteStop);
                    break;
                default:
                    break;
            }
        } catch (Exception e) {
            TRTCLogger.e(TAG, "parse custom message failed. " + e);
        }
    }

    public void onReceiveSEIMsg(String userId, byte[] data) {
        if (data == null) {
            return;
        }
        Gson gson = new Gson();
        String result = new String(data);
        Log.d(TAG, "receive sei message userId :" + userId + ", result : " + result);
        try {
            KaraokeSEIJsonData jsonData = gson.fromJson(result, KaraokeSEIJsonData.class);
            long progressTime = jsonData.getCurrentTime();
            int musicId = jsonData.getMusicId();
            long totalTime = jsonData.getTotalTime();
            if (mObserver != null) {
                mObserver.onMusicPlayProgress(musicId, progressTime, totalTime);
            }

        } catch (Exception e) {
            TRTCLogger.e(TAG, "onRecvSEIMsg parse error " + e + " , result = " + result);
        }
    }

    private void preloadMusic(int startTimeMS) {
        TRTCLogger.i(TAG, "preloadMusic currentNtp:" + getNtpTime());
        String body = "";
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("api", "preloadMusic");
            JSONObject paramJsonObject = new JSONObject();
            paramJsonObject.put("musicId", mMusicID);
            paramJsonObject.put("path", mOriginalUrl);
            paramJsonObject.put("startTimeMS", startTimeMS);
            jsonObject.put("params", paramJsonObject);
            body = jsonObject.toString();
        } catch (JSONException e) {
            e.printStackTrace();
        }
        TRTCCloud trtcCloud;
        if (mTRTCBgmService != null) {
            //如果有bgm实例，说明是主唱，选择背景音乐实例TRTCCloud加载歌曲
            trtcCloud = mTRTCBgmService.getTRTCCloud();
        } else {
            //如果没有bgm实例，说明是副唱，选择主实例TRTCCloud加载歌曲
            trtcCloud = mTRTCVoiceService.getTRTCCloud();
        }
        trtcCloud.callExperimentalAPI(body);
    }

    private boolean isNtpReady() {
        return TXLiveBase.getNetworkTimestamp() > 0;
    }

    private long getNtpTime() {
        return TXLiveBase.getNetworkTimestamp();
    }

    private boolean startPlayMusic(ChorusStartType reason, int delayMs, boolean isPublish) {
        if (!isNtpReady() || mMusicDuration <= 0) {
            TRTCLogger.e(TAG, "startPlayMusic failed. isNtpReady:" + isNtpReady()
                    + " mMusicDuration:" + mMusicDuration);
            return false;
        }
        if (delayMs <= -mMusicDuration) {
            //若 delayMs 为负数，代表约定的合唱开始时间在当前时刻之前
            //进一步，若 delayMs 为负，并且绝对值大于 BGM 时长，证明此时合唱已经结束了，应当忽略此次消息
            return false;
        }
        if (mIsChorusOn) {
            return false;
        }
        mIsChorusOn = true;
        TRTCLogger.i(TAG, "startPlayMusic delayMs:" + delayMs + " mMusicDuration:" + mMusicDuration);

        startTimer(reason, reason == ChorusStartType.Local ? (getNtpTime() + MUSIC_START_DELAY) :
                mRevStartPlayMusicTs);
        final TXAudioEffectManager.AudioMusicParam audioMusicParam =
                new TXAudioEffectManager.AudioMusicParam(mMusicID, mOriginalUrl);
        audioMusicParam.publish = isPublish;
        audioMusicParam.loopCount = 0;
        getAudioEffectManager().setMusicObserver(mMusicID, this);

        final TXAudioEffectManager.AudioMusicParam accompanyParam =
                new TXAudioEffectManager.AudioMusicParam(mMusicID + 1, mAccompanyUrl);
        accompanyParam.publish = isPublish;

        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                if (!mIsChorusOn) {
                    // 若达到预期播放时间时，合唱已被停止，则跳过此次播放
                    return;
                }
                // 如果是观众上麦，此时音乐可能已经开始播放了，此时不能再从头开始播放
                if (mChorusStartType == ChorusStartType.Remote) {
                    long curNtpTime = getNtpTime();
                    long position = curNtpTime - mRevStartPlayMusicTs;
                    audioMusicParam.startTimeMS = position > 0 ? position : 0;
                    accompanyParam.startTimeMS = position > 0 ? position : 0;
                }

                TRTCLogger.i(TAG, "startPlayMusic. startTs:" + mRevStartPlayMusicTs
                        + " start time: " + mDateFormatter.format(new Date(mRevStartPlayMusicTs))
                        + " current time: " + mDateFormatter.format(new Date(getNtpTime())));

                TXAudioEffectManager audioEffectManager = getAudioEffectManager();
                audioEffectManager.startPlayMusic(audioMusicParam);
                audioEffectManager.startPlayMusic(accompanyParam);
            }
        };

        if (delayMs > 0) {
            preloadMusic(0);
            mWorkHandler.postDelayed(runnable, delayMs);
        } else {
            preloadMusic(Math.abs(delayMs) + MUSIC_PRELOAD_DELAY);
            mWorkHandler.postDelayed(runnable, MUSIC_PRELOAD_DELAY);
        }
        return true;
    }

    private void startTimer(final ChorusStartType reason, final long startTs) {
        TRTCLogger.i(TAG, "startTimer. startTs:" + startTs + " start time: "
                + mDateFormatter.format(new Date(startTs)));
        if (mTimer == null) {
            mTimer = new Timer();
            mTimer.schedule(new TimerTask() {
                @Override
                public void run() {
                    //若本地开始播放，则发送合唱信令
                    if (reason == ChorusStartType.Local) {
                        sendStartMusicMsg(startTs);
                    }
                    checkMusicProgress();
                }
            }, 0, MESSAGE_SEND_INTERVAL);
            mStartPlayMusicTs = startTs;
        }
    }

    private void sendStartMusicMsg(long startTs) {
        String body = "";
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put(KEY_CMD, MSG_START_CHORUS);
            jsonObject.put(KEY_START_PLAY_MUSIC_TS, startTs);
            jsonObject.put(KEY_MUSIC_ID, String.valueOf(mMusicID));
            jsonObject.put(KEY_MUSIC_DURATION, String.valueOf(mMusicDuration));
            jsonObject.put(KEY_IS_ORIGIN_MUSIC, String.valueOf(mIsOriginMusic));
            body = jsonObject.toString();
        } catch (JSONException e) {
            e.printStackTrace();
        }
        mTRTCVoiceService.sendCustomCmdMsg(0, body.getBytes(), false, false);
    }

    private void stopPlayMusic(ChorusStopReason reason) {
        if (!mIsChorusOn) {
            return;
        }
        mWorkHandler.removeCallbacksAndMessages(null);
        mIsChorusOn = false;
        TRTCLogger.i(TAG, "stopPlayMusic reason:" + reason);
        if (mTimer != null) {
            mTimer.cancel();
            mTimer = null;
        }
        getAudioEffectManager().setMusicObserver(mMusicID, null);
        getAudioEffectManager().stopPlayMusic(mMusicID);
        getAudioEffectManager().stopPlayMusic(mMusicID + 1);
        if (reason == ChorusStopReason.LocalStop && mChorusStartType == ChorusStartType.Local) {
            sendStopBgmMsg();
        }
        //停止播放时,清空合唱停止时间信息
        if (reason == ChorusStopReason.LocalStop) {
            mRequestStopPlayMusicTs = 0;
        }
        if (mObserver != null) {
            mObserver.onMusicPlayCompleted(mMusicID);
        }
    }

    private void sendStopBgmMsg() {
        mRequestStopPlayMusicTs = getNtpTime();
        TRTCLogger.i(TAG, "sendStopBgmMsg. stopTs:" + mRequestStopPlayMusicTs + " stop time: "
                + mDateFormatter.format(new Date(mRequestStopPlayMusicTs)));
        String body = "";
        try {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put(KEY_CMD, MSG_STOP_CHORUS);
            jsonObject.put(KEY_REQUEST_STOP_TS, mRequestStopPlayMusicTs);
            jsonObject.put(KEY_MUSIC_ID, mMusicID);
            body = jsonObject.toString();
        } catch (JSONException e) {
            e.printStackTrace();
        }
        mTRTCVoiceService.sendCustomCmdMsg(0, body.getBytes(), true, true);
    }

    private void checkMusicProgress() {
        int expectedPositionMs = (int) (getNtpTime() - mStartPlayMusicTs);
        long curOriginPositionMs = getAudioEffectManager().getMusicCurrentPosInMS(mMusicID);
        long curAccompanyPositionMs = getAudioEffectManager().getMusicCurrentPosInMS(mMusicID + 1);

        if (expectedPositionMs >= 0 && Math.abs(curOriginPositionMs - expectedPositionMs) > 60
                && Math.abs(curOriginPositionMs - curAccompanyPositionMs) > 10) {
            TRTCLogger.i(TAG,
                    "checkMusicProgress curOriginPositionMs=" + curOriginPositionMs + " curAccompanyPositionMs="
                            + curAccompanyPositionMs + " expectedPosition=" + expectedPositionMs);
            getAudioEffectManager().seekMusicToPosInMS(mMusicID, expectedPositionMs);
            getAudioEffectManager().seekMusicToPosInMS(mMusicID + 1, expectedPositionMs);
        }
    }

    @Override
    public void onStart(int id, int errCode) {
        TRTCLogger.i(TAG, "onStart currentNtp:" + getNtpTime());
        if (errCode < 0) {
            TRTCLogger.e(TAG, "start play music failed. errCode:" + errCode);
            stopPlayMusic(ChorusStopReason.MusicPlayFailed);
        }
    }

    @Override
    public void onPlayProgress(int id, long curPtsMS, long durationMS) {
        if (mObserver != null) {
            mObserver.onMusicPlayProgress(id, curPtsMS, durationMS);
        }
        if (mTRTCBgmService != null) {
            sendMusicPositionMsg();
        }
    }

    @Override
    public void onComplete(int id, int errCode) {
        TRTCLogger.i(TAG, "onComplete currentNtp:" + getNtpTime());
        if (errCode < 0) {
            TRTCLogger.e(TAG, "music play error. errCode:" + errCode);
            stopPlayMusic(ChorusStopReason.MusicPlayFailed);
        } else {
            stopPlayMusic(ChorusStopReason.MusicPlayFinished);
        }
        if (mObserver != null) {
            mObserver.onMusicPlayCompleted(id);
        }
    }

    private void sendMusicPositionMsg() {
        long currentPosInMs = getAudioEffectManager().getMusicCurrentPosInMS(mMusicID);
        KaraokeSEIJsonData data = new KaraokeSEIJsonData();
        data.setMusicId(mMusicID);
        data.setCurrentTime(currentPosInMs > 0 ? currentPosInMs : 0);
        data.setTotalTime(mMusicDuration);
        data.setIsOriginMusic(mIsOriginMusic);
        Gson gson = new Gson();
        String body = gson.toJson(data);
        mTRTCBgmService.sendSEIMsg(body.getBytes(), 1);
    }

    /**
     * 合唱开始原因
     */
    public enum ChorusStartType {
        // 本地用户发起合唱
        Local,
        // 远端某个用户发起合唱
        Remote
    }

    /**
     * 合唱结束原因
     */
    public enum ChorusStopReason {
        // 合唱歌曲播放完毕，自动停止
        MusicPlayFinished,
        // 合唱音乐起播失败，被迫终止
        MusicPlayFailed,
        // 本地用户停止合唱
        LocalStop,
        // 远端某个用户请求停止合唱
        RemoteStop
    }
}

package com.tencent.liteav.tuikaraoke.model.impl.trtc;

import static com.tencent.liteav.TXLiteAVCode.ERR_TRTC_USER_SIG_CHECK_FAILED;

import android.content.Context;
import android.os.Bundle;
import android.text.TextUtils;

import com.tencent.liteav.audio.TXAudioEffectManager;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.model.impl.base.TXCallback;
import com.tencent.rtmp.ui.TXCloudVideoView;
import com.tencent.trtc.TRTCCloud;
import com.tencent.trtc.TRTCCloudDef;
import com.tencent.trtc.TRTCCloudListener;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Locale;

public class TRTCKtvRoomService extends TRTCCloudListener {
    private static final String TAG = "TRTCKtvRoomService";

    private static final int KTC_COMPONENT_KARAOKE = 8;
    public static final  int AUDIO_VOICE           = 0;
    public static final  int AUDIO_BGM_MUSIC       = 1;

    private TRTCCloud                  mTRTCCloud;
    private TRTCCloud                  mMainCloud;
    private boolean                    mIsInRoom;
    private TRTCKtvRoomServiceDelegate mDelegate;
    private TXCallback                 mEnterRoomCallback;
    private TXCallback                 mExitRoomCallback;
    private String                     mTaskId;
    private int                        mAudioType;

    public TRTCKtvRoomService(Context context, int audioType) {
        mTRTCCloud = TRTCCloud.sharedInstance(context);
        TRTCLogger.i(TAG, "init context:" + context);
        mAudioType = audioType;
    }

    public TRTCKtvRoomService(TRTCCloud mainCloud, int audioType) {
        mMainCloud = mainCloud;
        if (mainCloud != null) {
            mTRTCCloud = mainCloud.createSubCloud();
        }
        mAudioType = audioType;
    }

    public TRTCCloud getMainCloud() {
        if (mMainCloud != null) {
            return mMainCloud;
        }
        return mTRTCCloud;
    }

    public TRTCCloud getSubCloud() {
        if (mMainCloud != null) {
            return mTRTCCloud;
        }
        return null;
    }

    public void setDelegate(TRTCKtvRoomServiceDelegate delegate) {
        TRTCLogger.i(TAG, "init delegate:" + delegate);
        mDelegate = delegate;
    }

    public void destroySubCloud() {
        if (mMainCloud != null && mTRTCCloud != null) {
            mMainCloud.destroySubCloud(mTRTCCloud);
        }
    }

    @Override
    public void onStartPublishMediaStream(String taskId, int code, String message, Bundle extraInfo) {
        mTaskId = taskId;
        TRTCLogger.i(TAG, "onStartPublishMediaStream taskId:" + taskId + " code:" + code + " message:" + message);
    }

    @Override
    public void onUpdatePublishMediaStream(String taskId, int code, String message, Bundle extraInfo) {
        TRTCLogger.i(TAG, "onUpdatePublishMediaStream taskId:" + taskId + " code:" + code + " message:" + message);
    }


    public void enterRoom(int sdkAppId, int roomId, String userId, String userSign, int role, TXCallback callback) {
        if (sdkAppId == 0 || roomId == 0 || TextUtils.isEmpty(userId) || TextUtils.isEmpty(userSign)) {
            // 参数非法，可能执行了退房，或者登出
            TRTCLogger.e(TAG, "enter trtc room fail. params invalid. room id:" + roomId
                    + " user id:" + userId + " sign is empty:" + TextUtils.isEmpty(userSign));
            if (callback != null) {
                callback.onCallback(-1, "enter trtc room fail. params invalid. room id:"
                        + roomId + " user id:" + userId + " sign is empty:" + TextUtils.isEmpty(userSign));
            }
            return;
        }
        mEnterRoomCallback = callback;
        TRTCLogger.i(TAG, "enter room, app id:" + sdkAppId + " room id:" + roomId + " user id:"
                + userId + " sign:" + TextUtils.isEmpty(userId));
        TRTCCloudDef.TRTCParams params = new TRTCCloudDef.TRTCParams();
        params.sdkAppId = sdkAppId;
        params.userId = userId;
        params.userSig = userSign;
        params.role = role;
        params.roomId = roomId;
        internalEnterRoom(params);
    }

    public boolean startTRTCPush(int roomId, String mixUserId, boolean update) {
        TRTCLogger.i(TAG, "startTRTCPush  roomId:" + roomId + " mixUserId:" + mixUserId + " update:" + update);
        TRTCCloudDef.TRTCUser mixStreamIdentity = new TRTCCloudDef.TRTCUser();
        //混流机器人的id
        mixStreamIdentity.userId = mixUserId;
        mixStreamIdentity.intRoomId = roomId;
        TRTCCloudDef.TRTCPublishTarget publishTarget = new TRTCCloudDef.TRTCPublishTarget();
        publishTarget.mixStreamIdentity = mixStreamIdentity;
        publishTarget.mode = TRTCCloudDef.TRTC_PublishMixStream_ToRoom;

        TRTCCloudDef.TRTCStreamEncoderParam streamEncoderParam = new TRTCCloudDef.TRTCStreamEncoderParam();
        streamEncoderParam.videoEncodedFPS = 15;
        streamEncoderParam.videoEncodedGOP = 3;
        streamEncoderParam.videoEncodedKbps = 30;
        streamEncoderParam.audioEncodedSampleRate = 48000;
        streamEncoderParam.audioEncodedChannelNum = 2;
        streamEncoderParam.audioEncodedKbps = 64;
        streamEncoderParam.audioEncodedCodecType = 2;
        TRTCCloudDef.TRTCStreamMixingConfig streamMixingConfig = new TRTCCloudDef.TRTCStreamMixingConfig();
        if (update) {
            if (mTaskId != null) {
                mTRTCCloud.updatePublishMediaStream(mTaskId, publishTarget, streamEncoderParam, streamMixingConfig);
            }
        } else {
            mTRTCCloud.startPublishMediaStream(publishTarget, streamEncoderParam, streamMixingConfig);
        }
        return true;
    }

    public void setDefaultStreamRecvMode(boolean autoRecvAudio, boolean autoRecvVideo) {
        mTRTCCloud.setDefaultStreamRecvMode(autoRecvAudio, autoRecvAudio);
    }

    public void stopTRTCPublish() {
        if (mTaskId != null) {
            mTRTCCloud.stopPublishMediaStream(mTaskId);
        }
    }

    private void setFramework() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("api", "setFramework");
            JSONObject params = new JSONObject();
            params.put("framework", 1);
            params.put("component", KTC_COMPONENT_KARAOKE);
            jsonObject.put("params", params);
            mTRTCCloud.callExperimentalAPI(jsonObject.toString());
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void internalEnterRoom(TRTCCloudDef.TRTCParams params) {
        // 进房前设置一下监听，不然可能会被其他信息打断
        if (params == null) {
            return;
        }
        setFramework();
        mTRTCCloud.setListener(this);
        mTRTCCloud.enterRoom(params, TRTCCloudDef.TRTC_APP_SCENE_LIVE);
        if (params.role == TRTCCloudDef.TRTCRoleAnchor) {
            enableChorus(true);
            setLowLatencyMode(true);
            startMicrophone();
        }
        // enable volume callback
        enableAudioEvaluation(true);
    }

    public void exitRoom(TXCallback callback) {
        TRTCLogger.i(TAG, "exit room.");
        mEnterRoomCallback = null;
        mExitRoomCallback = callback;
        enableChorus(false);
        setLowLatencyMode(false);
        mTRTCCloud.exitRoom();
    }

    public void muteLocalAudio(boolean mute) {
        TRTCLogger.i(TAG, "mute local audio, mute:" + mute);
        mTRTCCloud.muteLocalAudio(mute);
    }

    public void muteRemoteAudio(String userId, boolean mute) {
        TRTCLogger.i(TAG, "mute remote audio, user id:" + userId + " mute:" + mute);
        mTRTCCloud.muteRemoteAudio(userId, mute);
    }

    public void muteAllRemoteAudio(boolean mute) {
        TRTCLogger.i(TAG, "mute all remote audio, mute:" + mute);
        mTRTCCloud.muteAllRemoteAudio(mute);
    }

    public boolean isEnterRoom() {
        return mIsInRoom;
    }

    @Override
    public void onEnterRoom(long l) {
        TRTCLogger.i(TAG, "on enter room, result:" + l);
        if (mEnterRoomCallback != null) {
            if (l > 0) {
                mIsInRoom = true;
                mEnterRoomCallback.onCallback(0, "enter room success.");
            } else {
                mIsInRoom = false;
                mEnterRoomCallback.onCallback((int) l, l == ERR_TRTC_USER_SIG_CHECK_FAILED
                        ? "userSig invalid, please login again" : "enter room fail");
            }
        }
    }

    @Override
    public void onExitRoom(int i) {
        TRTCLogger.i(TAG, "on exit room.");
        if (mExitRoomCallback != null) {
            mIsInRoom = false;
            mExitRoomCallback.onCallback(0, "exit room success.");
            mExitRoomCallback = null;
        }
    }

    @Override
    public void onRemoteUserEnterRoom(String userId) {
        TRTCLogger.i(TAG, "on user enter, user id:" + userId);
        if (mDelegate != null) {
            mDelegate.onTRTCAnchorEnter(userId);
        }
    }

    @Override
    public void onRemoteUserLeaveRoom(String userId, int i) {
        TRTCLogger.i(TAG, "on user exit, user id:" + userId);
        if (mDelegate != null) {
            mDelegate.onTRTCAnchorExit(userId);
        }
    }

    @Override
    public void onUserVideoAvailable(String userId, boolean available) {
        TRTCLogger.i(TAG, "on user video available, user id:" + userId + " available:" + available);
        if (mDelegate != null) {
            mDelegate.onTRTCVideoAvailable(userId, available);
        }
    }

    @Override
    public void onUserAudioAvailable(String userId, boolean available) {
        TRTCLogger.i(TAG, "on user audio available, user id:" + userId + " available:" + available);
        if (mDelegate != null) {
            mDelegate.onTRTCAudioAvailable(userId, available);
        }
    }

    @Override
    public void onError(int errorCode, String errorMsg, Bundle bundle) {
        TRTCLogger.i(TAG, "onError: " + errorCode);
        if (mDelegate != null) {
            mDelegate.onError(errorCode, errorMsg);
        }
    }


    @Override
    public void onNetworkQuality(final TRTCCloudDef.TRTCQuality trtcQuality,
                                 final ArrayList<TRTCCloudDef.TRTCQuality> arrayList) {
        if (mDelegate != null) {
            mDelegate.onNetworkQuality(trtcQuality, arrayList);
        }
    }

    @Override
    public void onUserVoiceVolume(final ArrayList<TRTCCloudDef.TRTCVolumeInfo> userVolumes, int totalVolume) {
        if (mDelegate != null && userVolumes.size() != 0) {
            mDelegate.onUserVoiceVolume(userVolumes, totalVolume);
        }
    }

    @Override
    public void onSetMixTranscodingConfig(int i, String s) {
        super.onSetMixTranscodingConfig(i, s);
        TRTCLogger.i(TAG, "on set mix transcoding, code:" + i + " msg:" + s);
    }

    public void setAudioQuality(int quality) {
        mTRTCCloud.setAudioQuality(quality);
    }

    public void startMicrophone() {
        if (mAudioType == AUDIO_VOICE) {
            mTRTCCloud.startLocalAudio(TRTCCloudDef.TRTC_AUDIO_QUALITY_MUSIC);
        }
        mTRTCCloud.setSystemVolumeType(TRTCCloudDef.TRTCSystemVolumeTypeMedia);
    }

    public void enableAudioEarMonitoring(boolean enable) {
        mTRTCCloud.enableAudioEarMonitoring(enable);
    }

    public void switchToAnchor() {
        enableChorus(true);
        setLowLatencyMode(true);
        mTRTCCloud.switchRole(TRTCCloudDef.TRTCRoleAnchor);
        startMicrophone();
    }


    public void switchToAudience() {
        enableChorus(false);
        setLowLatencyMode(false);
        stopMicrophone();
        mTRTCCloud.switchRole(TRTCCloudDef.TRTCRoleAudience);
    }

    private void enableChorus(boolean enable) {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("api", "enableChorus");
            JSONObject params = new JSONObject();
            params.put("enable", enable);
            params.put("audioSource", mAudioType);
            jsonObject.put("params", params);
            mTRTCCloud.callExperimentalAPI(String.format(Locale.ENGLISH, jsonObject.toString()));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    private void setLowLatencyMode(boolean enable) {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("api", "setLowLatencyModeEnabled");
            JSONObject params = new JSONObject();
            params.put("enable", enable);
            jsonObject.put("params", params);
            mTRTCCloud.callExperimentalAPI(String.format(Locale.ENGLISH, jsonObject.toString()));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public void stopMicrophone() {
        mTRTCCloud.stopLocalAudio();
    }

    public void setSpeaker(boolean useSpeaker) {
        mTRTCCloud.setAudioRoute(useSpeaker ? TRTCCloudDef.TRTC_AUDIO_ROUTE_SPEAKER :
                TRTCCloudDef.TRTC_AUDIO_ROUTE_EARPIECE);
    }

    public void setAudioCaptureVolume(int volume) {
        mTRTCCloud.setAudioCaptureVolume(volume);
    }

    public void setAudioPlayoutVolume(int volume) {
        mTRTCCloud.setAudioPlayoutVolume(volume);
    }

    public void enableAudioEvaluation(boolean enable) {
        mTRTCCloud.enableAudioVolumeEvaluation(enable ? 300 : 0);
    }

    public TXAudioEffectManager getAudioEffectManager() {
        return mTRTCCloud.getAudioEffectManager();
    }

    public boolean sendSEIMsg(byte[] data, int repeatCount) {
        return mTRTCCloud.sendSEIMsg(data, repeatCount);
    }

    public boolean sendCustomCmdMsg(int cmdID, byte[] data, boolean reliable, boolean ordered) {
        return mTRTCCloud.sendCustomCmdMsg(cmdID, data, reliable, ordered);
    }

    public void enableBlackStream(boolean enable) {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("api", "enableBlackStream");
            JSONObject params = new JSONObject();
            params.put("enable", enable);
            jsonObject.put("params", params);
            mTRTCCloud.callExperimentalAPI(jsonObject.toString());
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onRecvSEIMsg(String userId, byte[] data) {
        if (mDelegate != null && data != null) {
            mDelegate.onRecvSEIMsg(userId, data);
        }
    }

    @Override
    public void onRecvCustomCmdMsg(String userId, int cmdID, int seq, byte[] message) {
        if (mDelegate != null && message != null) {
            mDelegate.onRecvCustomCmdMsg(userId, cmdID, seq, message);
        }
    }

    public void startRemoteView(String userId, TXCloudVideoView view) {
        mTRTCCloud.startRemoteView(userId, view);
    }

    public void stopRemoteView(String userId) {
        mTRTCCloud.stopRemoteView(userId);
    }

}

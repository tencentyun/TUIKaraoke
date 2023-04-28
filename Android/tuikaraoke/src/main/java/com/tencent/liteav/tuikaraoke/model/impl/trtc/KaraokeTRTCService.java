package com.tencent.liteav.tuikaraoke.model.impl.trtc;

import static com.tencent.liteav.TXLiteAVCode.ERR_TRTC_USER_SIG_CHECK_FAILED;

import android.content.Context;
import android.os.Bundle;
import android.text.TextUtils;

import com.tencent.liteav.audio.TXAudioEffectManager;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.qcloud.tuicore.interfaces.TUICallback;
import com.tencent.rtmp.ui.TXCloudVideoView;
import com.tencent.trtc.TRTCCloud;
import com.tencent.trtc.TRTCCloudDef;
import com.tencent.trtc.TRTCCloudListener;
import com.tencent.trtc.TRTCStatistics;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Locale;

public class KaraokeTRTCService extends TRTCCloudListener {
    private static final String TAG = "KaraokeTRTCService";

    private static final int KTC_COMPONENT_KARAOKE = 8;
    public static final  int AUDIO_VOICE           = 0;
    public static final  int AUDIO_MUSIC           = 1;

    private TRTCCloud                  mTRTCCloud;
    private TRTCCloud                  mMainCloud;
    private KaraokeTRTCServiceObserver mDelegate;
    private TUICallback                mEnterRoomCallback;
    private TUICallback                mExitRoomCallback;
    private String                     mTaskId;
    private int                        mAudioType;

    private TRTCCloudDef.TRTCPublishTarget mPublishTarget;
    private TRTCCloudDef.TRTCStreamEncoderParam mStreamEncoderParam;
    private TRTCCloudDef.TRTCStreamMixingConfig mStreamMixingConfig;

    public KaraokeTRTCService(Context context, int audioType) {
        mMainCloud = TRTCCloud.sharedInstance(context);
        mTRTCCloud = mMainCloud;
        mAudioType = audioType;
        TRTCLogger.i(TAG, "KaraokeTRTCService instance@" + this + " initialized");
    }

    public KaraokeTRTCService(TRTCCloud mainCloud, int audioType) {
        mMainCloud = mainCloud;
        if (mMainCloud != null) {
            mTRTCCloud = mMainCloud.createSubCloud();
            mTRTCCloud.setAudioQuality(TRTCCloudDef.TRTC_AUDIO_QUALITY_MUSIC);
        }
        mAudioType = audioType;
    }

    public TRTCCloud getTRTCCloud() {
        return mTRTCCloud;
    }

    public void setDelegate(KaraokeTRTCServiceObserver delegate) {
        mDelegate = delegate;
    }

    public void destroyTRTCCloud() {
        if (mAudioType == AUDIO_VOICE && mTRTCCloud != null) {
            mTRTCCloud.destroySubCloud(mTRTCCloud);
            TRTCCloud.destroySharedInstance();
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

    public void enterRoom(int sdkAppId, int roomId, String userId, String userSign, int role,
                          TUICallback callback) {
        if (sdkAppId == 0 || roomId == 0 || TextUtils.isEmpty(userId) || TextUtils.isEmpty(userSign)) {
            // 参数非法，可能执行了退房，或者登出
            TRTCLogger.e(TAG, "enter trtc room fail. params invalid. room id:" + roomId
                    + " user id:" + userId + " sign is empty:" + TextUtils.isEmpty(userSign));
            TUICallback.onError(callback, -1, "enter trtc room fail. params invalid. room id:"
                    + roomId + " user id:" + userId + " sign is empty:" + TextUtils.isEmpty(userSign));
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

    public void startPublishMediaStream(int roomId, String targetUserId, String bgmUserId) {
        TRTCLogger.i(TAG, "startPublishMediaStream roomId:" + roomId + " targetUserId:" + targetUserId
                + " bgmUserId: " + bgmUserId);
        TRTCCloudDef.TRTCUser mixStreamIdentity = new TRTCCloudDef.TRTCUser();
        mixStreamIdentity.userId = targetUserId;
        mixStreamIdentity.intRoomId = roomId;
        mPublishTarget  = new TRTCCloudDef.TRTCPublishTarget();
        mPublishTarget.mixStreamIdentity = mixStreamIdentity;
        mPublishTarget.mode = TRTCCloudDef.TRTC_PublishMixStream_ToRoom;

        mStreamEncoderParam = new TRTCCloudDef.TRTCStreamEncoderParam();
        mStreamEncoderParam.videoEncodedFPS = 15;
        mStreamEncoderParam.videoEncodedGOP = 3;
        mStreamEncoderParam.videoEncodedKbps = 30;
        mStreamEncoderParam.videoEncodedWidth = 64;
        mStreamEncoderParam.videoEncodedHeight = 64;
        mStreamEncoderParam.audioEncodedSampleRate = 48000;
        mStreamEncoderParam.audioEncodedChannelNum = 2;
        mStreamEncoderParam.audioEncodedKbps = 128;
        mStreamEncoderParam.audioEncodedCodecType = 2;

        mStreamMixingConfig = new TRTCCloudDef.TRTCStreamMixingConfig();
        TRTCCloudDef.TRTCUser mixVideoUser = new TRTCCloudDef.TRTCUser();
        mixVideoUser.intRoomId = roomId;
        mixVideoUser.userId = bgmUserId;

        TRTCCloudDef.TRTCVideoLayout videoLayout = new TRTCCloudDef.TRTCVideoLayout();
        videoLayout.fixedVideoStreamType = TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG;
        videoLayout.x = 0;
        videoLayout.y = 0;
        videoLayout.width = 64;
        videoLayout.height = 64;
        videoLayout.zOrder = 0;
        videoLayout.fixedVideoUser = mixVideoUser;

        mStreamMixingConfig.videoLayoutList.add(videoLayout);

        mTRTCCloud.startPublishMediaStream(mPublishTarget, mStreamEncoderParam, mStreamMixingConfig);
    }

    public void updatePublishMediaStream() {
        if (mPublishTarget == null || mStreamEncoderParam == null || mStreamMixingConfig == null) {
            TRTCLogger.e(TAG, "update publish media stream params invalid");
            return;
        }
        mTRTCCloud.updatePublishMediaStream(mTaskId, mPublishTarget, mStreamEncoderParam, mStreamMixingConfig);
    }


    public void stopPublishMediaStream() {
        if (TextUtils.isEmpty(mTaskId)) {
            TRTCLogger.e(TAG, "stop publish media stream task id is empty");
            return;
        }
            mTRTCCloud.stopPublishMediaStream(mTaskId);
    }

    public void setDefaultStreamRecvMode(boolean autoRecvAudio, boolean autoRecvVideo) {
        mTRTCCloud.setDefaultStreamRecvMode(autoRecvAudio, autoRecvVideo);
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
            startMicrophone();
        }
    }

    public void exitRoom(TUICallback callback) {
        TRTCLogger.i(TAG, "exit room, mAudioType: " + mAudioType);
        mEnterRoomCallback = null;
        mExitRoomCallback = callback;
        enableChorus(false);
        setLowLatencyMode(false);
        mTRTCCloud.exitRoom();
    }

    public void muteLocalAudio(boolean mute) {
        mTRTCCloud.muteLocalAudio(mute);
    }

    public void muteRemoteAudio(String userId, boolean mute) {
        mTRTCCloud.muteRemoteAudio(userId, mute);
    }

    public void muteRemoteVideo(String userId, boolean mute) {
        mTRTCCloud.muteRemoteVideoStream(userId, TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG, mute);
    }

    public void muteAllRemoteAudio(boolean mute) {
        mTRTCCloud.muteAllRemoteAudio(mute);
    }

    @Override
    public void onEnterRoom(long result) {
        TRTCLogger.i(TAG, "on enter room, result:" + result);
        if (mEnterRoomCallback != null) {
            if (result > 0) {
                mEnterRoomCallback.onSuccess();
            } else {
                mEnterRoomCallback.onError((int) result, result == ERR_TRTC_USER_SIG_CHECK_FAILED
                        ? "userSig invalid, please login again" : "enter room fail");
            }
        }
    }

    @Override
    public void onExitRoom(int i) {
        TRTCLogger.i(TAG, "on exit room, mAudioType: " + mAudioType);
        if (mExitRoomCallback != null) {
            mExitRoomCallback.onSuccess();
            mExitRoomCallback = null;
        }
        destroyTRTCCloud();
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
    public void onStatistics(TRTCStatistics statistics) {
        if (mDelegate != null) {
            mDelegate.onStatistics(statistics);
        }
    }


    @Override
    public void onSetMixTranscodingConfig(int i, String s) {
        super.onSetMixTranscodingConfig(i, s);
        TRTCLogger.i(TAG, "on set mix transcoding, code:" + i + " msg:" + s);
    }

    public void startMicrophone() {
        mTRTCCloud.setSystemVolumeType(TRTCCloudDef.TRTCSystemVolumeTypeMedia);
        if (mAudioType == AUDIO_VOICE) {
            mTRTCCloud.startLocalAudio(TRTCCloudDef.TRTC_AUDIO_QUALITY_DEFAULT);
        }
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
        mTRTCCloud.startRemoteView(userId, TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG, view);
    }

    public void stopRemoteView(String userId) {
        mTRTCCloud.stopRemoteView(userId, TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG);
    }

}

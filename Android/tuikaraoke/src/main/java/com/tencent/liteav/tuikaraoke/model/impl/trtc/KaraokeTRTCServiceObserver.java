package com.tencent.liteav.tuikaraoke.model.impl.trtc;

import com.tencent.trtc.TRTCCloudDef;
import com.tencent.trtc.TRTCStatistics;

import java.util.ArrayList;

public interface KaraokeTRTCServiceObserver {
    void onTRTCAnchorEnter(String userId);

    void onTRTCAnchorExit(String userId);

    void onTRTCVideoAvailable(String userId, boolean available);

    void onTRTCAudioAvailable(String userId, boolean available);

    void onError(int errorCode, String errorMsg);

    void onNetworkQuality(TRTCCloudDef.TRTCQuality trtcQuality, ArrayList<TRTCCloudDef.TRTCQuality> arrayList);

    void onUserVoiceVolume(ArrayList<TRTCCloudDef.TRTCVolumeInfo> userVolumes, int totalVolume);

    void onStatistics(TRTCStatistics statistics);

    void onRecvSEIMsg(String userId, byte[] data);

    void onRecvCustomCmdMsg(String userId, int cmdID, int seq, byte[] message);

    void onCapturedAudioFrame(TRTCCloudDef.TRTCAudioFrame trtcAudioFrame);
}

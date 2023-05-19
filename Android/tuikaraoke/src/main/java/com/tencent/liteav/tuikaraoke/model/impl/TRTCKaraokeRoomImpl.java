package com.tencent.liteav.tuikaraoke.model.impl;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.tencent.liteav.audio.TXAudioEffectManager;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoom;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef.UserInfo;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomObserver;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.model.impl.chorus.KaraokeChorusExtension;
import com.tencent.liteav.tuikaraoke.model.impl.chorus.KaraokeChorusObserver;
import com.tencent.liteav.tuikaraoke.model.impl.im.KaraokeIMService;
import com.tencent.liteav.tuikaraoke.model.impl.im.KaraokeIMServiceObserver;
import com.tencent.liteav.tuikaraoke.model.impl.server.TRTCKaraokeRoomManager;
import com.tencent.liteav.tuikaraoke.model.impl.trtc.KaraokeTRTCService;
import com.tencent.liteav.tuikaraoke.model.impl.trtc.KaraokeTRTCServiceObserver;
import com.tencent.qcloud.tuicore.interfaces.TUICallback;
import com.tencent.qcloud.tuicore.interfaces.TUIValueCallback;
import com.tencent.rtmp.TXLiveBase;
import com.tencent.rtmp.TXLiveBaseListener;
import com.tencent.trtc.TRTCCloud;
import com.tencent.trtc.TRTCCloudDef;
import com.tencent.trtc.TRTCStatistics;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class TRTCKaraokeRoomImpl extends TRTCKaraokeRoom implements KaraokeIMServiceObserver,
        KaraokeTRTCServiceObserver {
    private static final String TAG = "TRTCKaraokeRoomImpl";

    private static final String MIX_ROBOT      = "_robot";
    private static final String AUDIO_BGM      = "_bgm";

    private static final int DEFAULT_MUSIC_VOLUME = 60;
    private static final int DEFAULT_VOICE_VOLUME = 80;

    private static TRTCKaraokeRoomImpl    sInstance;
    private final Context                 mContext;
    private       TRTCKaraokeRoomObserver mDelegate;

    private Handler mMainHandler;    // 所有调用都切到主线程使用，保证内部多线程安全问题
    private Handler mDelegateHandler;     // 外部可指定的回调线程
    private int     mSdkAppId;
    private String  mUserId;
    private String  mUserSig;
    private int     mTakeSeatIndex;
    private int     mRoomId;
    private String  mBgmUserId;        //双实例bgm流的userId
    private String  mMixRobotUserId;   //混流机器人userId
    private int     mCurrentPlayingOriginalMusicID = 0;
    private boolean mIsOriginalMusic               = false;
    private int     mMusicVolume                   = DEFAULT_MUSIC_VOLUME;
    private float   mMusicPitch                    = 0.0f;

    // 已抛出的观众列表
    private Set<String>                            mAudienceList;
    private List<TRTCKaraokeRoomDef.SeatInfo>      mSeatInfoList;
    private TUICallback mEnterSeatCallback;
    private TUICallback mLeaveSeatCallback;
    private TUICallback mPickSeatCallback;
    private TUICallback mKickSeatCallback;

    private KaraokeTRTCService     mTRTCVoiceService; //人声实例
    private KaraokeTRTCService     mTRTCMusicService; //音乐实例
    private KaraokeIMService       mKaraokeIMService;
    private KaraokeMusicService    mKaraokeMusicService;
    private KaraokeChorusExtension mChorusExtension;

    private static final TXAudioEffectManager.TXVoiceChangerType[] VOICE_CHANGER_ARR = {
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_0,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_1,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_2,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_3,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_4,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_5,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_6,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_7,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_8,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_9,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_10,
            TXAudioEffectManager.TXVoiceChangerType.TXLiveVoiceChangerType_11};

    private static final TXAudioEffectManager.TXVoiceReverbType[] VOICE_REVERB_ARR = {
            TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_0,
            TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_1,
            TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_2,
            TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_3,
            TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_4,
            TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_5,
            TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_6,
            TXAudioEffectManager.TXVoiceReverbType.TXLiveVoiceReverbType_7};


    private TXLiveBaseListener mTXLiveBaseListener = new TXLiveBaseListener() {
        @Override
        public void onUpdateNetworkTime(int code, String message) {
            runOnDelegateThread(new Runnable() {
                @Override
                public void run() {
                    TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onUpdateNetworkTime code: " + code
                            + " message: " + message);
                    if (mDelegate != null) {
                        mDelegate.onUpdateNetworkTime(code, message);
                    }
                }
            });

        }
    };

    public static synchronized TRTCKaraokeRoom sharedInstance(Context context) {
        if (sInstance == null) {
            sInstance = new TRTCKaraokeRoomImpl(context.getApplicationContext());
            TRTCLogger.i(TAG, "TRTCKaraokeRoom api: sharedInstance@" + sInstance.hashCode());
        }
        return sInstance;
    }

    public static synchronized void destroySharedInstance() {
        if (sInstance != null) {
            TRTCLogger.i(TAG, "TRTCKaraokeRoom api: destroySharedInstance@" + sInstance.hashCode());
            sInstance = null;
        }
    }

    private TRTCKaraokeRoomImpl(Context context) {
        mContext = context;
        mMainHandler = new Handler(Looper.getMainLooper());
        mDelegateHandler = new Handler(Looper.getMainLooper());
        mSeatInfoList = new ArrayList<>();
        mAudienceList = new HashSet<>();
        mTakeSeatIndex = -1;
        mKaraokeIMService = new KaraokeIMService(context);
        mKaraokeIMService.setDelegate(this);
        TXLiveBase.setListener(mTXLiveBaseListener);
    }

    private KaraokeTRTCService createMusicService() {
        TRTCCloud voiceCloud = mTRTCVoiceService.getTRTCCloud();
        KaraokeTRTCService service = new KaraokeTRTCService(voiceCloud, KaraokeTRTCService.AUDIO_MUSIC);
        return service;
    }

    private void clearList() {
        mSeatInfoList.clear();
        mAudienceList.clear();
        if (mChorusExtension != null && mChorusExtension.isChorusOn()) {
            mChorusExtension.stopChorus();
            mChorusExtension.setObserver(null);
        }
        if (mTRTCVoiceService != null) {
            mTRTCVoiceService.setDelegate(null);
        }
        resetAudioEffect();
        mTakeSeatIndex = -1;
    }

    private void resetAudioEffect() {
        mCurrentPlayingOriginalMusicID = 0;
        mIsOriginalMusic = false;
        mMusicVolume = DEFAULT_MUSIC_VOLUME;
        mMusicPitch = 0.0f;
    }

    private void runOnMainThread(Runnable runnable) {
        Handler handler = mMainHandler;
        if (handler != null) {
            if (handler.getLooper() == Looper.myLooper()) {
                runnable.run();
            } else {
                handler.post(runnable);
            }
        } else {
            runnable.run();
        }
    }

    private void runOnDelegateThread(Runnable runnable) {
        Handler handler = mDelegateHandler;
        if (handler != null) {
            if (handler.getLooper() == Looper.myLooper()) {
                runnable.run();
            } else {
                handler.post(runnable);
            }
        } else {
            runnable.run();
        }
    }

    @Override
    public void setDelegate(TRTCKaraokeRoomObserver delegate) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: setDelegate @" + delegate);
        mDelegate = delegate;
    }

    @Override
    public void setDelegateHandler(Handler handler) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: setDelegateHandler @" + handler);
        mDelegateHandler = handler;
    }

    @Override
    public void login(final int sdkAppId, final String userId, final String userSig,
                      final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG,
                        "TRTCKaraokeRoom api: login, sdkAppId:" + sdkAppId + " userId:" + userId
                                + " sign is empty:" + TextUtils.isEmpty(userSig));
                if (sdkAppId == 0 || TextUtils.isEmpty(userId) || TextUtils.isEmpty(userSig)) {
                    TRTCLogger.e(TAG, "start login fail. params invalid.");
                    TUICallback.onError(callback, -1, "start login fail. params invalid.");
                    return;
                }
                mSdkAppId = sdkAppId;
                mUserId = userId;
                mUserSig = userSig;
                TRTCLogger.i(TAG, "start login room service");
                mKaraokeIMService.login(sdkAppId, userId, userSig, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(int code, String msg) {
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void logout(final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: logout");
                mSdkAppId = 0;
                mUserId = "";
                mUserSig = "";
                TRTCLogger.i(TAG, "start logout room service");
                mKaraokeIMService.logout(new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(int code, String msg) {
                        TRTCLogger.e(TAG, "logout room service finish, code:" + code + " msg:" + msg);
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void setSelfProfile(final String userName, final String avatarURL,
                               final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: setSelfProfile, user name:" + userName
                        + " avatar url:" + avatarURL);
                mKaraokeIMService.setSelfProfile(userName, avatarURL, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(int code, String msg) {
                        TRTCLogger.i(TAG, "set profile finish, code:" + code + " msg:" + msg);
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void createRoom(final int roomId, final TRTCKaraokeRoomDef.RoomParam roomParam,
                           final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: createRoom, roomId:" + roomId + " info:" + roomParam);
                if (roomId == 0 || roomParam == null || TextUtils.isEmpty(roomParam.roomName)
                        || TextUtils.isEmpty(roomParam.coverUrl) || roomParam.seatCount < 0) {
                    TRTCLogger.e(TAG, "create room fail. params invalid");
                    return;
                }
                mRoomId = roomId;

                if (roomParam.seatInfoList != null) {
                    mSeatInfoList.addAll(roomParam.seatInfoList);
                } else {
                    for (int i = 0; i < roomParam.seatCount; i++) {
                        mSeatInfoList.add(new TRTCKaraokeRoomDef.SeatInfo());
                    }
                }

                mKaraokeIMService.createRoom(String.valueOf(roomId), roomParam.roomName,
                        roomParam.coverUrl, roomParam.needRequest, mSeatInfoList, new TUICallback() {
                            @Override
                            public void onSuccess() {
                                notifyCallbackEvent(callback, 0, "");
                            }

                            @Override
                            public void onError(int code, String msg) {
                                TRTCLogger.e(TAG, "create room in service, code:" + code + " msg:" + msg);
                                notifyCallbackEvent(callback, code, msg);
                                notifyErrorEvent(code, msg);
                            }
                        });
            }
        });
    }

    @Override
    public void enterRoom(final int roomId, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: enterRoom roomId:" + roomId);
                mRoomId = roomId;
                mMixRobotUserId = roomId + MIX_ROBOT;
                mTRTCVoiceService = new KaraokeTRTCService(mContext, KaraokeTRTCService.AUDIO_VOICE);
                mTRTCVoiceService.setDelegate(TRTCKaraokeRoomImpl.this);
                mTRTCVoiceService.setAudioCaptureVolume(DEFAULT_VOICE_VOLUME);

                if (mKaraokeIMService.isOwner()) {
                    mTRTCMusicService = createMusicService();
                    mChorusExtension = new KaraokeChorusExtension(mContext, mTRTCVoiceService, mTRTCMusicService);
                } else {
                    mChorusExtension = new KaraokeChorusExtension(mContext, mTRTCVoiceService);
                }
                mChorusExtension.setObserver(mKaraokeChorusObserver);

                enterIMRoomInner(String.valueOf(roomId), new TUICallback() {
                    @Override
                    public void onError(int errorCode, String errorMessage) {
                        notifyCallbackEvent(callback, errorCode, errorMessage);
                    }

                    @Override
                    public void onSuccess() {
                        int roleType = mKaraokeIMService.isOwner()
                                ? TRTCCloudDef.TRTCRoleAnchor
                                : TRTCCloudDef.TRTCRoleAudience;
                        enterTRTCRoomInner(roomId, mUserId, mUserSig, roleType, new TUICallback() {
                            @Override
                            public void onSuccess() {
                                notifyCallbackEvent(callback, 0, "");
                            }

                            @Override
                            public void onError(int errorCode, String errorMessage) {
                                notifyCallbackEvent(callback, errorCode, errorMessage);
                            }
                        });
                    }
                });
            }
        });
    }

    private void enterIMRoomInner(String roomId, TUICallback callback) {
        mKaraokeIMService.enterRoom(roomId, new TUICallback() {
            @Override
            public void onSuccess() {
                mBgmUserId = mKaraokeIMService.getOwnerUserId() + AUDIO_BGM;
                notifyCallbackEvent(callback, 0, "");
            }

            @Override
            public void onError(int code, String msg) {
                TRTCLogger.e(TAG, "enter room service finish, room id:" + roomId
                        + " code:" + code + " msg:" + msg);
                notifyErrorEvent(code, msg);
                notifyCallbackEvent(callback, code, msg);
            }
        });
    }

    private void genBgmUserSigInner(TUIValueCallback<String> callback) {
        TRTCKaraokeRoomManager.getInstance().genUserSig(mBgmUserId,
                new TRTCKaraokeRoomManager.GenUserSigCallback() {
                    @Override
                    public void onSuccess(String userSig) {
                        TRTCLogger.i(TAG, "successfully generated bgm " + "instance usersig.");
                        TUIValueCallback.onSuccess(callback, userSig);
                    }

                    @Override
                    public void onError(int errorCode, String message) {
                        TRTCLogger.e(TAG, "request generated bgm instance usersig, "
                                + "error code:" + errorCode + "message:" + message);
                        TUIValueCallback.onError(callback, errorCode, message);
                    }
                });
    }

    private void enterTRTCRoomInner(final int roomId, final String userId, final String userSig,
                                    final int role, final TUICallback callback) {
        mTRTCVoiceService.enterRoom(mSdkAppId, roomId, userId, userSig, role, new TUICallback() {
            @Override
            public void onSuccess() {
                mTRTCVoiceService.enableAudioEvaluation(true);
                mTRTCVoiceService.muteRemoteAudio(mBgmUserId, true);
                mTRTCVoiceService.muteRemoteVideo(mBgmUserId, true);

                if (mKaraokeIMService.isOwner()) {
                    genBgmUserSigInner(new TUIValueCallback<String>() {
                        @Override
                        public void onError(int code, String msg) {
                            TUICallback.onError(callback, code, msg);
                        }

                        @Override
                        public void onSuccess(String bgmUserSig) {
                            mTRTCMusicService.setDefaultStreamRecvMode(false, false);
                            mTRTCMusicService.enterRoom(mSdkAppId, roomId, mBgmUserId, bgmUserSig, role, null);
                            mTRTCVoiceService.startPublishMediaStream(roomId, mMixRobotUserId, mBgmUserId);
                            TUICallback.onSuccess(callback);
                        }
                    });
                } else {
                    notifyCallbackEvent(callback, 0, "");
                }
            }

            @Override
            public void onError(int code, String msg) {
                TRTCLogger.e(TAG, "enter trtc room finish, code:" + code + " msg:" + msg);
                notifyCallbackEvent(callback, code, msg);
            }
        });
    }

    @Override
    public void destroyRoom(final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: destroyRoom.");
                mKaraokeIMService.destroyRoom(new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(int code, String msg) {
                        TRTCLogger.e(TAG, "destroy room finish, code:" + code + " msg:" + msg);
                        notifyCallbackEvent(callback, code, msg);
                    }
                });

                // 恢复设定
                clearList();
            }
        });
    }

    private void notifyCallbackEvent(TUICallback callback, int code, String message) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (code == 0) {
                    TUICallback.onSuccess(callback);
                } else {
                    TUICallback.onError(callback, code, message);
                }
            }
        });
    }

    private <T> void notifyValueCallbackEvent(TUIValueCallback<T> callback, int code, String message, T value) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (code == 0) {
                    TUIValueCallback.onSuccess(callback, value);
                } else {
                    TUIValueCallback.onError(callback, code, message);
                }
            }
        });
    }

    private void notifyErrorEvent(int code, String message) {
        if (code == 0) {
            return;
        }
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    mDelegate.onError(code, message);
                }
            }
        });
    }

    @Override
    public void exitRoom(final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: exitRoom.");
                if (mTRTCMusicService != null) {
                    mTRTCMusicService.exitRoom(new TUICallback() {
                        @Override
                        public void onSuccess() {

                        }

                        @Override
                        public void onError(int code, String msg) {
                            TRTCLogger.e(TAG, "music instance exit room finish, code:" + code + " msg:" + msg);
                            notifyErrorEvent(code, msg);
                        }
                    });
                    mTRTCVoiceService.stopPublishMediaStream();
                }

                if (mTRTCVoiceService != null) {
                    mTRTCVoiceService.enableAudioEvaluation(false);
                    mTRTCVoiceService.exitRoom(new TUICallback() {
                        @Override
                        public void onSuccess() {

                        }

                        @Override
                        public void onError(final int code, final String msg) {
                            TRTCLogger.e(TAG, "voice instance exit room finish, code:" + code + " msg:" + msg);
                            notifyErrorEvent(code, msg);
                        }
                    });
                }

                if (mKaraokeIMService.isOwner()) {
                    notifyCallbackEvent(callback, 0, "");
                } else {
                    if (isOnSeat(mUserId)) {
                        leaveSeat(new TUICallback() {
                            @Override
                            public void onSuccess() {
                                exitIMRoomInternal(callback);
                            }

                            @Override
                            public void onError(int errorCode, String errorMessage) {
                                exitIMRoomInternal(callback);
                            }
                        });
                    } else {
                        exitIMRoomInternal(callback);
                    }
                }
                clearList();
            }
        });
    }

    private void exitIMRoomInternal(TUICallback callback) {
        TRTCLogger.i(TAG, "start exit im room service.");
        mKaraokeIMService.exitRoom(new TUICallback() {
            @Override
            public void onSuccess() {
                notifyCallbackEvent(callback, 0, "");
            }

            @Override
            public void onError(final int code, final String msg) {
                TRTCLogger.e(TAG, "IM exit room finish, code:" + code + " msg:" + msg);
                notifyCallbackEvent(callback, code, msg);
            }
        });
    }

    private boolean isOnSeat(String userId) {
        // 判断某个userid 是不是在座位上
        if (mSeatInfoList == null) {
            return false;
        }
        for (TRTCKaraokeRoomDef.SeatInfo seatInfo : mSeatInfoList) {
            if (userId != null && userId.equals(seatInfo.user)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void getUserInfoList(final List<String> userIdList, final TUIValueCallback<List<UserInfo>> callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: getUserInfoList userIdList:" + userIdList);
                if (userIdList == null || userIdList.isEmpty()) {
                    getAudienceList(callback);
                    return;
                }

                mKaraokeIMService.getUserInfo(userIdList, new TUIValueCallback<List<UserInfo>>() {
                    @Override
                    public void onSuccess(List<UserInfo> userList) {
                        TRTCLogger.i(TAG, "get audience list success, list:"
                                + (userList != null ? userList.size() : 0));
                        notifyValueCallbackEvent(callback, 0, "", userList);
                    }

                    @Override
                    public void onError(int code, String msg) {
                        TRTCLogger.e(TAG, "get audience list failed, code:" + code + " msg:" + msg);
                        notifyValueCallbackEvent(callback, code, msg, Collections.EMPTY_LIST);
                    }
                });
            }
        });
    }

    private void getAudienceList(final TUIValueCallback<List<UserInfo>> callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                mKaraokeIMService.getAudienceList(new TUIValueCallback<List<UserInfo>>() {
                    @Override
                    public void onSuccess(List<UserInfo> userList) {
                        TRTCLogger.i(TAG, "get audience list success, code: userList:"
                                        + (userList != null ? userList.size() : 0));
                        notifyValueCallbackEvent(callback, 0, "", userList);
                    }

                    @Override
                    public void onError(int code, String msg) {
                        TRTCLogger.i(TAG, "get audience list failed, code:" + code + " msg:" + msg);
                        notifyValueCallbackEvent(callback, code, msg, Collections.EMPTY_LIST);
                    }
                });
            }
        });
    }

    @Override
    public void enterSeat(final int seatIndex, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: enterSeat index:" + seatIndex);
                if (isOnSeat(mUserId)) {
                    notifyCallbackEvent(callback, 0, "you are already in the seat");
                    return;
                }
                mEnterSeatCallback = callback;
                mKaraokeIMService.takeSeat(seatIndex, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        TRTCLogger.i(TAG, "take seat callback success, and wait attrs changed.");
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(int code, String msg) {
                        //出错了，恢复callback
                        mEnterSeatCallback = null;
                        mTakeSeatIndex = -1;
                        TUICallback.onError(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void leaveSeat(final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: leaveSeat index:" + mTakeSeatIndex);
                if (mTakeSeatIndex == -1) {
                    //已经不在座位上了
                    notifyCallbackEvent(callback, -1, "you are not in the seat");
                    return;
                }
                mLeaveSeatCallback = callback;
                mKaraokeIMService.leaveSeat(mTakeSeatIndex, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(final int code, final String msg) {
                        //出错了，恢复callback
                        mLeaveSeatCallback = null;
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void pickSeat(final int seatIndex, final String userId, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                //判断该用户是否已经在麦上
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: pickSeat index:" + seatIndex);
                if (isOnSeat(userId)) {
                    notifyCallbackEvent(callback, -1, "the user is already on seat");
                    return;
                }
                mPickSeatCallback = callback;
                mKaraokeIMService.pickSeat(seatIndex, userId, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(final int code, final String msg) {
                        //出错了，恢复callback
                        mPickSeatCallback = null;
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void kickSeat(final int index, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: kickSeat index:" + index);
                mKickSeatCallback = callback;
                mKaraokeIMService.kickSeat(index, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(int code, String msg) {
                        //出错了，恢复callback
                        mKickSeatCallback = null;
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void muteSeat(final int seatIndex, final boolean isMute, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: muteSeat index: " + seatIndex + " mute: " + isMute);
                mKaraokeIMService.muteSeat(seatIndex, isMute, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(final int code, final String msg) {
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void closeSeat(final int seatIndex, final boolean isClose, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: closeSeat index: " + seatIndex + " close: " + isClose);
                mKaraokeIMService.closeSeat(seatIndex, isClose, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(final int code, final String msg) {
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void startMicrophone() {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: startMicrophone");
                mTRTCVoiceService.startMicrophone();
            }
        });
    }

    @Override
    public void stopMicrophone() {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: stopMicrophone");
                mTRTCVoiceService.stopMicrophone();
            }
        });
    }

    /**
     * 静音本地
     * <p>
     * 直接调用 TRTC 设置：TXTRTCLiveRoom.muteLocalAudio
     *
     * @param mute
     */
    @Override
    public void muteLocalAudio(final boolean mute) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: muteLocalAudio mute: " + mute);
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                mTRTCVoiceService.muteLocalAudio(mute);
            }
        });
    }

    /**
     * 静音音频
     *
     * @param userId
     * @param mute
     */
    @Override
    public void muteRemoteAudio(final String userId, final boolean mute) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: muteRemoteAudio userId: " + userId + " mute: " + mute);
                mTRTCVoiceService.muteRemoteAudio(userId, mute);
            }
        });
    }

    /**
     * 静音所有音频
     *
     * @param mute
     */
    @Override
    public void muteAllRemoteAudio(final boolean mute) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: muteAllRemoteAudio");
                mTRTCVoiceService.muteAllRemoteAudio(mute);
            }
        });
    }

    @Override
    public TXAudioEffectManager getVoiceAudioEffectManager() {
        if (mTRTCVoiceService != null) {
            return mTRTCVoiceService.getAudioEffectManager();
        }
        TRTCLogger.e(TAG, "getVoiceAudioEffectManager is null");
        return null;
    }

    @Override
    public TXAudioEffectManager getMusicAudioEffectManager() {
        if (mTRTCMusicService != null) {
            return mTRTCMusicService.getAudioEffectManager();
        }
        if (mTRTCVoiceService != null) {
            return mTRTCVoiceService.getAudioEffectManager();
        }
        TRTCLogger.e(TAG, "getBgmMusicAudioEffectManager is null");
        return null;
    }

    @Override
    public KaraokeMusicService getKaraokeMusicService() {
        return mKaraokeMusicService;
    }

    @Override
    public void sendRoomTextMsg(final String message, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: sendRoomTextMsg");
                mKaraokeIMService.sendRoomTextMsg(message, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(final int code, final String msg) {
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void sendRoomCustomMsg(final String cmd, final String message, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: sendRoomCustomMsg cmd: " + cmd
                        + " message: " + message);
                mKaraokeIMService.sendRoomCustomMsg(cmd, message, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(final int code, final String msg) {
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public String sendInvitation(final String cmd, final String userId, final String content,
                                 final TUICallback callback) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: sendInvitation to " + userId + " cmd:" + cmd
                + " content:" + content);
        return mKaraokeIMService.sendInvitation(cmd, userId, content, new TUICallback() {
            @Override
            public void onSuccess() {
                notifyCallbackEvent(callback, 0, "");
            }

            @Override
            public void onError(final int code, final String msg) {
                notifyCallbackEvent(callback, code, msg);
            }
        });
    }

    @Override
    public void acceptInvitation(final String id, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: acceptInvitation id: " + id);
                mKaraokeIMService.acceptInvitation(id, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(final int code, final String msg) {
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void rejectInvitation(final String id, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api: rejectInvitation id:" + id);
                mKaraokeIMService.rejectInvitation(id, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(final int code, final String msg) {
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void cancelInvitation(final String id, final TUICallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  cancelInvitation id: " + id);
                mKaraokeIMService.cancelInvitation(id, new TUICallback() {
                    @Override
                    public void onSuccess() {
                        notifyCallbackEvent(callback, 0, "");
                    }

                    @Override
                    public void onError(final int code, final String msg) {
                        notifyCallbackEvent(callback, code, msg);
                    }
                });
            }
        });
    }

    @Override
    public void onRoomDestroy(final String roomId) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onRoomDestroy roomId: " + roomId);
                if (mDelegate != null) {
                    mDelegate.onRoomDestroy(roomId);
                }
            }
        });
    }

    @Override
    public void onRoomRecvRoomTextMsg(final String roomId, final String message,
                                      final TRTCKaraokeRoomDef.UserInfo userInfo) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onRoomRecvRoomTextMsg roomId: " + roomId);
                if (mDelegate != null) {
                    mDelegate.onRecvRoomTextMsg(message, userInfo);
                }
            }
        });
    }

    @Override
    public void onRoomRecvRoomCustomMsg(final String roomId, final String cmd, final String message,
                                        final TRTCKaraokeRoomDef.UserInfo userInfo) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onRoomRecvRoomCustomMsg roomId: "
                        + roomId + " cmd:" + cmd + " message: " + message);
                if (mDelegate != null) {
                    mDelegate.onRecvRoomCustomMsg(cmd, message, userInfo);
                }
            }
        });
    }

    @Override
    public void onRoomInfoChange(final TRTCKaraokeRoomDef.RoomInfo roomInfo) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onRoomInfoChange " + roomInfo.roomName);
                if (mDelegate != null) {
                    mDelegate.onRoomInfoChange(roomInfo);
                }
            }
        });
    }

    @Override
    public void onSeatInfoListChange(final List<TRTCKaraokeRoomDef.SeatInfo> seatInfoList) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onSeatInfoListChange");
                mSeatInfoList = seatInfoList;
                if (mDelegate != null) {
                    mDelegate.onSeatListChange(seatInfoList);
                }
            }
        });
    }

    @Override
    public void onRoomAudienceEnter(final TRTCKaraokeRoomDef.UserInfo userInfo) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onRoomAudienceEnter userInfo: " + userInfo.userId);
                if (mDelegate != null) {
                    mDelegate.onAudienceEnter(userInfo);
                }
            }
        });
    }

    @Override
    public void onRoomAudienceLeave(final TRTCKaraokeRoomDef.UserInfo userInfo) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onRoomAudienceLeave userInfo: " + userInfo.userId);
                if (mDelegate != null) {
                    mDelegate.onAudienceExit(userInfo);
                }
            }
        });
    }

    @Override
    public void onSeatTake(final int index, final TRTCKaraokeRoomDef.UserInfo userInfo) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onSeatTake index: " + index + " userInfo: "
                        + userInfo.userId);
                boolean isOwner = mKaraokeIMService.isOwner();
                if (userInfo.userId.equals(mUserId)) {
                    //是自己上线了, 切换角色
                    mTakeSeatIndex = index;
                    mTRTCVoiceService.switchToAnchor();
                    boolean mute = mSeatInfoList.get(index).mute;
                    mTRTCVoiceService.muteLocalAudio(mute);
                    if (mDelegate != null && !mute) {
                        mDelegate.onUserMicrophoneMute(userInfo.userId, false);
                    }
                } else {
                    if (isOwner) {
                        mTRTCVoiceService.updatePublishMediaStream();
                    }
                }
                runOnDelegateThread(new Runnable() {
                    @Override
                    public void run() {
                        if (mDelegate != null) {
                            mDelegate.onAnchorEnterSeat(index, userInfo);
                        }
                        if (mPickSeatCallback != null) {
                            mPickSeatCallback.onSuccess();
                            mPickSeatCallback = null;
                        }
                    }
                });
                if (userInfo.userId.equals(mUserId)) {
                    //再回调出去
                    runOnDelegateThread(new Runnable() {
                        @Override
                        public void run() {
                            if (mEnterSeatCallback != null) {
                                mEnterSeatCallback.onSuccess();
                                mEnterSeatCallback = null;
                            }
                        }
                    });
                }
            }
        });
    }

    @Override
    public void onSeatClose(final int index, final boolean isClose) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onSeatTake index: " + index + " isClose: "
                        + isClose);
                if (mTakeSeatIndex == index && isClose) {
                    mTRTCVoiceService.switchToAudience();
                    mTakeSeatIndex = -1;
                }
                runOnDelegateThread(new Runnable() {
                    @Override
                    public void run() {
                        if (mDelegate != null) {
                            mDelegate.onSeatClose(index, isClose);
                        }
                    }
                });
            }
        });
    }

    @Override
    public void onSeatLeave(final int index, final TRTCKaraokeRoomDef.UserInfo userInfo) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onSeatLeave index: " + index + " userInfo: "
                        + userInfo.userId);
                if (userInfo.userId.equals(mUserId)) {
                    //自己下线了~
                    mTakeSeatIndex = -1;
                    mTRTCVoiceService.switchToAudience();
                }
                runOnDelegateThread(new Runnable() {
                    @Override
                    public void run() {
                        if (mDelegate != null) {
                            mDelegate.onAnchorLeaveSeat(index, userInfo);
                        }
                        if (mKickSeatCallback != null) {
                            mKickSeatCallback.onSuccess();
                            mKickSeatCallback = null;
                        }
                    }
                });
                if (userInfo.userId.equals(mUserId)) {
                    runOnDelegateThread(new Runnable() {
                        @Override
                        public void run() {
                            if (mLeaveSeatCallback != null) {
                                mLeaveSeatCallback.onSuccess();
                                mLeaveSeatCallback = null;
                            }
                        }
                    });
                }
            }
        });
    }

    @Override
    public void onSeatMute(final int index, final boolean mute) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onSeatTake index: " + index + " mute: "
                        + mute);
                if (mDelegate != null) {
                    mDelegate.onSeatMute(index, mute);
                }
            }
        });
    }

    @Override
    public void onReceiveNewInvitation(final String id, final String inviter, final String cmd, final String content) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onReceiveNewInvitation id: " + id + " inviter: "
                        + inviter + " cmd: " + cmd);
                if (mDelegate != null) {
                    mDelegate.onReceiveNewInvitation(id, inviter, cmd, content);
                }
            }
        });
    }

    @Override
    public void onInviteeAccepted(final String id, final String invitee) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onInviteeAccepted id: " + id + " invitee: "
                        + invitee);
                if (mDelegate != null) {
                    mDelegate.onInviteeAccepted(id, invitee);
                }
            }
        });
    }

    @Override
    public void onInviteeRejected(final String id, final String invitee) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onInviteeRejected id: " + id + " invitee: "
                        + invitee);
                if (mDelegate != null) {
                    mDelegate.onInviteeRejected(id, invitee);
                }
            }
        });
    }

    @Override
    public void onInvitationCancelled(final String id, final String inviter) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onInvitationCancelled id: " + id + " inviter: "
                        + inviter);
                if (mDelegate != null) {
                    mDelegate.onInvitationCancelled(id, inviter);
                }
            }
        });
    }

    @Override
    public void onTRTCAnchorEnter(String userId) {
    }

    @Override
    public void onTRTCAnchorExit(String userId) {
        if (mKaraokeIMService.isOwner()) {
            // 主播是房主
            if (mSeatInfoList != null) {
                int kickSeatIndex = -1;
                for (int i = 0; i < mSeatInfoList.size(); i++) {
                    if (userId.equals(mSeatInfoList.get(i).user)) {
                        kickSeatIndex = i;
                        break;
                    }
                }
                if (kickSeatIndex != -1) {
                    kickSeat(kickSeatIndex, null);
                }
            }
        }
    }

    @Override
    public void onTRTCVideoAvailable(final String userId, final boolean available) {
        if (!userId.equals(mMixRobotUserId)) {
            return;
        }

        if (available) {
            mTRTCVoiceService.startRemoteView(userId, null);
        } else {
            mTRTCVoiceService.stopRemoteView(userId);
        }
    }

    @Override
    public void onTRTCAudioAvailable(final String userId, final boolean available) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    mDelegate.onUserMicrophoneMute(userId, !available);
                }
            }
        });
    }

    @Override
    public void onError(final int errorCode, final String errorMsg) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    mDelegate.onError(errorCode, errorMsg);
                }
            }
        });
    }

    @Override
    public void onNetworkQuality(final TRTCCloudDef.TRTCQuality trtcQuality,
                                 final ArrayList<TRTCCloudDef.TRTCQuality> arrayList) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    mDelegate.onNetworkQuality(trtcQuality, arrayList);
                }
            }
        });
    }

    @Override
    public void onUserVoiceVolume(final ArrayList<TRTCCloudDef.TRTCVolumeInfo> userVolumes, final int totalVolume) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null && userVolumes != null) {
                    mDelegate.onUserVolumeUpdate(userVolumes, totalVolume);
                }
            }
        });
    }

    @Override
    public void onStatistics(TRTCStatistics statistics) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    mDelegate.onStatistics(statistics);
                }
            }
        });
    }


    @Override
    public void startPlayMusic(int musicId, @NonNull String originalUrl, @NonNull String accompanyUrl) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: startPlayMusic musicID: " + musicId + "  originalUrl: "
                + originalUrl + "  accompanyUrl: " + accompanyUrl);
        if (TextUtils.isEmpty(originalUrl) && TextUtils.isEmpty(accompanyUrl)) {
            TRTCLogger.e(TAG, "startPlayMusic contains empty param");
            return;
        }

        mCurrentPlayingOriginalMusicID = musicId;
        boolean isOwner = mKaraokeIMService.isOwner();
        if (isOwner) {
            enableBlackStream(true);
        }
        if (mChorusExtension != null) {
            mChorusExtension.startChorus(musicId, originalUrl, accompanyUrl, isOwner);
        }

        if (TextUtils.isEmpty(accompanyUrl)) {
            switchMusicAccompanimentMode(true);
        }
        restoreMusicState();
    }

    private void restoreMusicState() {
        if (mCurrentPlayingOriginalMusicID == 0) {
            return;
        }
        updateMusicVolumeInner();
        setMusicPitch(mMusicPitch);
    }

    @Override
    public void stopPlayMusic() {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: stopPlayMusic musicId：" + mCurrentPlayingOriginalMusicID);
        mCurrentPlayingOriginalMusicID = 0;
        boolean isOwner = mKaraokeIMService.isOwner();
        if (isOwner) {
            enableBlackStream(false);
        }
        if (mChorusExtension != null) {
            mChorusExtension.stopChorus();
        }
    }

    @Override
    public void pausePlayMusic() {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: pausePlayMusic musicId：" + mCurrentPlayingOriginalMusicID);
        if (mCurrentPlayingOriginalMusicID == 0) {
            TRTCLogger.i(TAG, "pausePlayMusic mCurrentPlayingOriginalMusicID=0");
            return;
        }
        getMusicAudioEffectManager().pausePlayMusic(mCurrentPlayingOriginalMusicID);
        getMusicAudioEffectManager().pausePlayMusic(mCurrentPlayingOriginalMusicID + 1);
    }

    @Override
    public void resumePlayMusic() {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: resumePlayMusic musicId：" + mCurrentPlayingOriginalMusicID);
        if (mCurrentPlayingOriginalMusicID == 0) {
            TRTCLogger.i(TAG, "resumePlayMusic mCurrentPlayingOriginalMusicID=0");
            return;
        }
        getMusicAudioEffectManager().resumePlayMusic(mCurrentPlayingOriginalMusicID);
        getMusicAudioEffectManager().resumePlayMusic(mCurrentPlayingOriginalMusicID + 1);
    }

    @Override
    public void switchMusicAccompanimentMode(boolean isOriginal) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: switchMusicAccompanimentMode isOriginal：" + isOriginal
                + " current musicId: " + mCurrentPlayingOriginalMusicID + " original: " + mIsOriginalMusic);
        if (mCurrentPlayingOriginalMusicID == 0 || mIsOriginalMusic == isOriginal) {
            return;
        }
        mIsOriginalMusic = isOriginal;
        mChorusExtension.setOriginMusicAccompanimentMode(isOriginal);
        updateMusicVolumeInner();

        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    mDelegate.onMusicAccompanimentModeChanged(mCurrentPlayingOriginalMusicID, mIsOriginalMusic);
                }
            }
        });
    }

    @Override
    public void setMusicVolume(int musicVolume) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: setMusicVolume volume: " + musicVolume);
        if (musicVolume < 0 || musicVolume > 100) {
            musicVolume = DEFAULT_MUSIC_VOLUME;
        }
        if (mCurrentPlayingOriginalMusicID == 0) {
            mMusicVolume = musicVolume;
            return;
        }
        mMusicVolume = musicVolume;
        updateMusicVolumeInner();
    }

    @Override
    public void enableVoiceEarMonitor(boolean enable) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: enableVoiceEarMonitor enable: " + enable);
        TXAudioEffectManager voiceEffectManager = getVoiceAudioEffectManager();
        if (voiceEffectManager != null) {
            voiceEffectManager.enableVoiceEarMonitor(enable);
        }
    }

    @Override
    public void setVoiceVolume(int voiceVolume) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: setVoiceVolume voiceVolume: " + voiceVolume);
        if (voiceVolume < 0 || voiceVolume > 100) {
            voiceVolume = DEFAULT_VOICE_VOLUME;
        }

        TXAudioEffectManager voiceEffectManager = getVoiceAudioEffectManager();
        if (voiceEffectManager != null) {
            voiceEffectManager.setVoiceCaptureVolume(voiceVolume);
            voiceEffectManager.setVoiceEarMonitorVolume(voiceVolume);
        }
    }

    @Override
    public void setMusicPitch(float musicPitch) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  setMusicPitch musicPitch:" + musicPitch);
        if (musicPitch < -1.0f || musicPitch > 1.0f) {
            musicPitch = 0.0f;
        }
        if (mCurrentPlayingOriginalMusicID == 0) {
            mMusicPitch = musicPitch;
            return;
        }
        TXAudioEffectManager musicEffectManager = getMusicAudioEffectManager();
        musicEffectManager.setMusicPitch(mCurrentPlayingOriginalMusicID, musicPitch);
        musicEffectManager.setMusicPitch(mCurrentPlayingOriginalMusicID + 1, musicPitch);
    }

    @Override
    public void setVoiceReverbType(int reverbType) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: setVoiceReverbType reverbType:" + reverbType);
        if (reverbType < 0 || reverbType >= VOICE_REVERB_ARR.length) {
            reverbType = 0;
        }
        TXAudioEffectManager voiceEffectManager = getVoiceAudioEffectManager();
        if (voiceEffectManager != null) {
            voiceEffectManager.setVoiceReverbType(VOICE_REVERB_ARR[reverbType]);
        }
    }

    @Override
    public void setVoiceChangerType(int changerType) {
        TRTCLogger.i(TAG, "TRTCKaraokeRoom api: setVoiceChangerType changerType: " + changerType);
        if (changerType < 0 || changerType >= VOICE_CHANGER_ARR.length) {
            changerType = 0;
        }
        TXAudioEffectManager voiceEffectManager = getVoiceAudioEffectManager();
        if (voiceEffectManager != null) {
            voiceEffectManager.setVoiceChangerType(VOICE_CHANGER_ARR[changerType]);
        }
    }

    private void updateMusicVolumeInner() {
        TXAudioEffectManager musicEffectManager = getMusicAudioEffectManager();
        // 设置原唱音量
        musicEffectManager.setMusicPlayoutVolume(mCurrentPlayingOriginalMusicID,
                mIsOriginalMusic ? mMusicVolume : 0);
        musicEffectManager.setMusicPublishVolume(mCurrentPlayingOriginalMusicID,
                mIsOriginalMusic ? mMusicVolume : 0);

        // 设置伴奏音量
        musicEffectManager.setMusicPlayoutVolume(mCurrentPlayingOriginalMusicID + 1,
                mIsOriginalMusic ? 0 : mMusicVolume);
        musicEffectManager.setMusicPublishVolume(mCurrentPlayingOriginalMusicID + 1,
                mIsOriginalMusic ? 0 : mMusicVolume);
    }

    private void enableBlackStream(boolean enable) {
        if (mTRTCMusicService != null) {
            mTRTCMusicService.enableBlackStream(enable);
        }
    }

    @Override
    public void onRecvSEIMsg(String userId, byte[] data) {
        if (mChorusExtension != null) {
            mChorusExtension.onReceiveSEIMsg(userId, data);
        }
    }

    @Override
    public void onRecvCustomCmdMsg(String userId, int cmdID, int seq, byte[] message) {
        if (mChorusExtension != null) {
            mChorusExtension.onReceiveCustomCmdMsg(userId, cmdID, seq, message);
        }
    }

    @Override
    public void updateNetworkTime() {
        TXLiveBase.updateNetworkTime();
    }


    private KaraokeChorusObserver mKaraokeChorusObserver = new KaraokeChorusObserver() {
        @Override
        public void onMusicPlayProgress(int musicId, long curPtsMS, long durationMS) {
            runOnDelegateThread(new Runnable() {
                @Override
                public void run() {
                    if (mDelegate != null) {
                        mDelegate.onMusicProgressUpdate(String.valueOf(musicId), curPtsMS, durationMS);
                    }
                }
            });


        }

        @Override
        public void onReceiveAnchorSendChorusMsg(String musicID, boolean isOriginal) {
            if (mTakeSeatIndex == -1) {
                return;
            }
            runOnDelegateThread(new Runnable() {
                @Override
                public void run() {
                    TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onReceiveAnchorSendChorusMsg musicID: " + musicID);
                    if (mDelegate != null) {
                        mDelegate.onReceiveAnchorSendChorusMsg(musicID);
                    }
                }
            });
        }

        @Override
        public void onMusicPlayCompleted(int musicID) {
            runOnDelegateThread(new Runnable() {
                @Override
                public void run() {
                    TRTCLogger.i(TAG, "TRTCKaraokeRoom api:  onMusicPlayCompleted musicID: " + musicID);
                    if (mDelegate != null) {
                        mDelegate.onMusicPlayCompleted(String.valueOf(musicID));
                    }
                }
            });
        }

        @Override
        public void onMusicAccompanimentModeChanged(int musicId, boolean isOriginal) {
            boolean isOwner = mKaraokeIMService.isOwner();
            if (!isOwner && mTakeSeatIndex != -1 && isOriginal != mIsOriginalMusic) {
                switchMusicAccompanimentMode(isOriginal);
            }
        }
    };
}

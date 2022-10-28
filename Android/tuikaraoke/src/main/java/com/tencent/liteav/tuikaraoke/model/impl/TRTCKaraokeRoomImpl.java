package com.tencent.liteav.tuikaraoke.model.impl;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;

import com.google.gson.Gson;
import com.tencent.liteav.audio.TXAudioEffectManager;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoom;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomCallback;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDelegate;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomManager;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.model.impl.base.TXCallback;
import com.tencent.liteav.tuikaraoke.model.impl.base.TXRoomInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.TXSeatInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.TXUserInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.TXUserListCallback;
import com.tencent.liteav.tuikaraoke.model.impl.chorus.ChorusExtension;
import com.tencent.liteav.tuikaraoke.model.impl.room.ITXRoomServiceDelegate;
import com.tencent.liteav.tuikaraoke.model.impl.room.impl.TXRoomService;
import com.tencent.liteav.tuikaraoke.model.impl.trtc.TRTCKtvRoomService;
import com.tencent.liteav.tuikaraoke.model.impl.trtc.TRTCKtvRoomServiceDelegate;
import com.tencent.liteav.tuikaraoke.model.KaraokeSEIJsonData;
import com.tencent.qcloud.tuicore.TUILogin;
import com.tencent.rtmp.ui.TXCloudVideoView;
import com.tencent.trtc.TRTCCloud;
import com.tencent.trtc.TRTCCloudDef;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class TRTCKaraokeRoomImpl extends TRTCKaraokeRoom implements ITXRoomServiceDelegate, TRTCKtvRoomServiceDelegate,
        ChorusExtension.ChorusListener {
    private static final String TAG = "TRTCKaraokeRoomImpl";

    private static final int    TYPE_ORIGIN    = 0; //原唱
    private static final int    TYPE_ACCOMPANY = 1; //伴奏
    private static final String MIX_ROBOT      = "_robot";
    private static final String AUDIO_BGM      = "_bgm";

    private static TRTCKaraokeRoomImpl     sInstance;
    private final  Context                 mContext;
    private        TRTCKaraokeRoomDelegate mDelegate;
    // 所有调用都切到主线程使用，保证内部多线程安全问题
    private        Handler                 mMainHandler;
    // 外部可指定的回调线程
    private        Handler                 mDelegateHandler;
    private        int                     mSdkAppId;
    private        String                  mUserId;
    private        String                  mUserSig;

    // 已抛出的观众列表
    private Set<String>                            mAudienceList;
    private List<TRTCKaraokeRoomDef.SeatInfo>      mSeatInfoList;
    private TRTCKaraokeRoomCallback.ActionCallback mEnterSeatCallback;
    private TRTCKaraokeRoomCallback.ActionCallback mLeaveSeatCallback;
    private TRTCKaraokeRoomCallback.ActionCallback mPickSeatCallback;
    private TRTCKaraokeRoomCallback.ActionCallback mKickSeatCallback;
    private int                                    mTakeSeatIndex;

    private boolean            mIsAuthor;         //是否是主播
    private int                mRoomId;
    private TRTCKtvRoomService mTRTCVoiceService; //人声实例
    private TRTCKtvRoomService mTRTCBgmService;   //bgm实例
    private String             mBgmUserId;        //双实例bgm流的userId
    private String             mMixRobotUserId;   //混流机器人userId
    private ChorusExtension    mChorusExtension;
    private String             mBgmUserSig;

    public static synchronized TRTCKaraokeRoom sharedInstance(Context context) {
        if (sInstance == null) {
            sInstance = new TRTCKaraokeRoomImpl(context.getApplicationContext());
        }
        return sInstance;
    }

    public static synchronized void destroySharedInstance() {
        if (sInstance != null) {
            sInstance.destroy();
            sInstance = null;
        }
    }

    private void destroy() {
        TXRoomService.getInstance().destroy();
    }

    private TRTCKaraokeRoomImpl(Context context) {
        mContext = context;
        mMainHandler = new Handler(Looper.getMainLooper());
        mDelegateHandler = new Handler(Looper.getMainLooper());
        mSeatInfoList = new ArrayList<>();
        mAudienceList = new HashSet<>();
        mTakeSeatIndex = -1;
        TXRoomService.getInstance().init(context);
        TXRoomService.getInstance().setDelegate(this);
    }

    private TRTCKtvRoomService createBgmService() {
        TRTCCloud voiceCloud = mTRTCVoiceService.getMainCloud();
        TRTCKtvRoomService service = new TRTCKtvRoomService(voiceCloud, TRTCKtvRoomService.AUDIO_BGM_MUSIC);
        return service;
    }

    private void clearList() {
        mSeatInfoList.clear();
        mAudienceList.clear();
        if (mChorusExtension != null && mChorusExtension.isChorusOn()) {
            mChorusExtension.stopChorus();
            mChorusExtension.setListener(null);
        }
        if (mTRTCVoiceService != null) {
            mTRTCVoiceService.setDelegate(null);
        }
        mTRTCBgmService = null;
        mTRTCVoiceService = null;
        mChorusExtension = null;
        mIsAuthor = false;
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
    public void setDelegate(TRTCKaraokeRoomDelegate delegate) {
        mDelegate = delegate;
    }

    @Override
    public void setDelegateHandler(Handler handler) {
        mDelegateHandler = handler;
    }

    @Override
    public void login(final int sdkAppId, final String userId, final String userSig,
                      final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG,
                        "start login, sdkAppId:" + sdkAppId + " userId:" + userId + " sign is empty:"
                                + TextUtils.isEmpty(userSig));
                if (sdkAppId == 0 || TextUtils.isEmpty(userId) || TextUtils.isEmpty(userSig)) {
                    TRTCLogger.e(TAG, "start login fail. params invalid.");
                    if (callback != null) {
                        callback.onCallback(-1, "登录失败，参数有误");
                    }
                    return;
                }
                mSdkAppId = sdkAppId;
                mUserId = userId;
                mUserSig = userSig;
                TRTCLogger.i(TAG, "start login room service");
                TXRoomService.getInstance().login(sdkAppId, userId, userSig, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void logout(final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "start logout");
                mSdkAppId = 0;
                mUserId = "";
                mUserSig = "";
                TRTCLogger.i(TAG, "start logout room service");
                TXRoomService.getInstance().logout(new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        TRTCLogger.i(TAG, "logout room service finish, code:" + code + " msg:" + msg);
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void setSelfProfile(final String userName, final String avatarURL,
                               final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "set profile, user name:" + userName + " avatar url:" + avatarURL);
                TXRoomService.getInstance().setSelfProfile(userName, avatarURL, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        TRTCLogger.i(TAG, "set profile finish, code:" + code + " msg:" + msg);
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void createRoom(final int roomId, final TRTCKaraokeRoomDef.RoomParam roomParam,
                           final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "create room, room id:" + roomId + " info:" + roomParam);
                if (roomId == 0) {
                    TRTCLogger.e(TAG, "create room fail. params invalid");
                    return;
                }
                mRoomId = roomId;
                mIsAuthor = true;
                final String strRoomId = String.valueOf(roomId);
                clearList();
                mTRTCVoiceService = new TRTCKtvRoomService(mContext, TRTCKtvRoomService.AUDIO_VOICE);
                mTRTCVoiceService.setDelegate(TRTCKaraokeRoomImpl.this);
                mTRTCBgmService = createBgmService();
                mChorusExtension = new ChorusExtension(mContext, mTRTCVoiceService, mTRTCBgmService);
                mChorusExtension.setListener(TRTCKaraokeRoomImpl.this);
                final String roomName = (roomParam == null ? "" : roomParam.roomName);
                final String roomCover = (roomParam == null ? "" : roomParam.coverUrl);
                final boolean isNeedRequest = (roomParam != null && roomParam.needRequest);
                final int seatCount = (roomParam == null ? 8 : roomParam.seatCount);
                final List<TXSeatInfo> txSeatInfoList = new ArrayList<>();
                if (roomParam != null && roomParam.seatInfoList != null) {
                    for (TRTCKaraokeRoomDef.SeatInfo seatInfo : roomParam.seatInfoList) {
                        TXSeatInfo item = new TXSeatInfo();
                        item.status = seatInfo.status;
                        item.mute = seatInfo.mute;
                        item.user = seatInfo.userId;
                        txSeatInfoList.add(item);
                        mSeatInfoList.add(seatInfo);
                    }
                } else {
                    for (int i = 0; i < seatCount; i++) {
                        txSeatInfoList.add(new TXSeatInfo());
                        mSeatInfoList.add(new TRTCKaraokeRoomDef.SeatInfo());
                    }
                }
                mBgmUserId = TUILogin.getLoginUser() + AUDIO_BGM;
                mMixRobotUserId = roomId + MIX_ROBOT;
                // 创建房间
                TXRoomService.getInstance().createRoom(strRoomId, roomName, roomCover, isNeedRequest, txSeatInfoList,
                        new TXCallback() {
                            @Override
                            public void onCallback(final int code, final String msg) {
                                TRTCLogger.i(TAG, "create room in service, code:" + code + " msg:" + msg);
                                if (code == 0) {
                                    TRTCKaraokeRoomManager.getInstance().genUserSig(mBgmUserId,
                                            new TRTCKaraokeRoomManager.GenUserSigCallback() {
                                                @Override
                                                public void onSuccess(String userSig) {
                                                    TRTCLogger.e(TAG, "onSuccess.");
                                                    mBgmUserSig = userSig;
                                                    enterTRTCRoomInner(roomId, mUserId, mUserSig,
                                                            TRTCCloudDef.TRTCRoleAnchor, callback);
                                                }

                                                @Override
                                                public void onError(int errorCode, String message) {
                                                    TRTCLogger.e(TAG,
                                                            "onError code:" + errorCode + " message:" + message);
                                                }
                                            });
                                    return;
                                } else {
                                    runOnDelegateThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            if (mDelegate != null) {
                                                mDelegate.onError(code, msg);
                                            }
                                        }
                                    });
                                }
                                runOnDelegateThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (callback != null) {
                                            callback.onCallback(code, msg);
                                        }
                                    }
                                });
                            }
                        });
            }
        });
    }

    @Override
    public void destroyRoom(final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "start destroy room.");
                // TRTC 房间退房结果不关心
                TRTCLogger.i(TAG, "start exit trtc room.");
                mTRTCVoiceService.stopTRTCPublish();
                mTRTCBgmService.destroySubCloud();
                mTRTCVoiceService.exitRoom(new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        TRTCLogger.i(TAG, "exit trtc room finish, code:" + code + " msg:" + msg);
                        if (code != 0) {
                            runOnDelegateThread(new Runnable() {
                                @Override
                                public void run() {
                                    if (mDelegate != null) {
                                        mDelegate.onError(code, msg);
                                    }
                                }
                            });
                        }
                    }
                });

                TRTCLogger.i(TAG, "start destroy room service.");
                TXRoomService.getInstance().destroyRoom(new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        TRTCLogger.i(TAG, "destroy room finish, code:" + code + " msg:" + msg);
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
                    }
                });

                // 恢复设定
                clearList();
            }
        });
    }

    @Override
    public void enterRoom(final int roomId, final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                // 恢复设定
                clearList();
                mRoomId = roomId;
                mTRTCVoiceService = new TRTCKtvRoomService(mContext, TRTCKtvRoomService.AUDIO_VOICE);
                mTRTCVoiceService.setDelegate(TRTCKaraokeRoomImpl.this);
                mChorusExtension = new ChorusExtension(mContext, mTRTCVoiceService);
                mChorusExtension.setListener(TRTCKaraokeRoomImpl.this);
                TRTCLogger.i(TAG, "start enter room, room id:" + roomId);
                mMixRobotUserId = roomId + MIX_ROBOT;
                enterTRTCRoomInner(roomId, mUserId, mUserSig, TRTCCloudDef.TRTCRoleAudience,
                        new TRTCKaraokeRoomCallback.ActionCallback() {
                            @Override
                            public void onCallback(final int code, final String msg) {
                                TRTCLogger.i(TAG,
                                        "trtc enter room finish, room id:" + roomId + " code:" + code
                                                + " msg:" + msg);
                                runOnDelegateThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        if (callback != null) {
                                            callback.onCallback(code, msg);
                                        }
                                    }
                                });
                            }
                        });
                String strRoomId = String.valueOf(roomId);
                TXRoomService.getInstance().enterRoom(strRoomId, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        TRTCLogger.i(TAG,
                                "enter room service finish, room id:" + roomId
                                        + " code:" + code + " msg:" + msg);
                        runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                if (code != 0) {
                                    runOnDelegateThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            if (mDelegate != null) {
                                                mDelegate.onError(code, msg);
                                            }
                                        }
                                    });
                                } else {
                                    mBgmUserId = TXRoomService.getInstance().getOwnerUserId() + AUDIO_BGM;
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void exitRoom(final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "start exit room.");
                // 退房的时候需要判断主播是否在座位，如果是麦上主播，需要先清空座位列表
                if (isOnSeat(mUserId)) {
                    leaveSeat(new TRTCKaraokeRoomCallback.ActionCallback() {
                        @Override
                        public void onCallback(int code, String msg) {
                            exitRoomInternal(callback);
                        }
                    });
                } else {
                    exitRoomInternal(callback);
                }
            }
        });
    }

    private void exitRoomInternal(final TRTCKaraokeRoomCallback.ActionCallback callback) {
        if (mTRTCBgmService != null) {
            mTRTCBgmService.destroySubCloud();
        }
        if (mTRTCVoiceService != null) {
            mTRTCVoiceService.exitRoom(new TXCallback() {
                @Override
                public void onCallback(final int code, final String msg) {
                    if (code != 0) {
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (mDelegate != null) {
                                    mDelegate.onError(code, msg);
                                }
                            }
                        });
                    }
                }
            });
        }

        TRTCLogger.i(TAG, "start exit room service.");
        TXRoomService.getInstance().exitRoom(new TXCallback() {
            @Override
            public void onCallback(final int code, final String msg) {
                TRTCLogger.i(TAG, "exit room finish, code:" + code + " msg:" + msg);
                runOnDelegateThread(new Runnable() {
                    @Override
                    public void run() {
                        if (callback != null) {
                            callback.onCallback(code, msg);
                        }
                    }
                });
            }
        });
        clearList();
    }

    private boolean isOnSeat(String userId) {
        // 判断某个userid 是不是在座位上
        if (mSeatInfoList == null) {
            return false;
        }
        for (TRTCKaraokeRoomDef.SeatInfo seatInfo : mSeatInfoList) {
            if (userId != null && userId.equals(seatInfo.userId)) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void getUserInfoList(final List<String> userIdList,
                                final TRTCKaraokeRoomCallback.UserListCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                if (userIdList == null) {
                    getAudienceList(callback);
                    return;
                }
                TXRoomService.getInstance().getUserInfo(userIdList, new TXUserListCallback() {
                    @Override
                    public void onCallback(final int code, final String msg, final List<TXUserInfo> list) {
                        TRTCLogger.i(TAG,
                                "get audience list finish, code:" + code + " msg:" + msg + " list:"
                                        + (list != null ? list.size() : 0));
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    List<TRTCKaraokeRoomDef.UserInfo> userList = new ArrayList<>();
                                    if (list != null) {
                                        for (TXUserInfo info : list) {
                                            TRTCKaraokeRoomDef.UserInfo trtcUserInfo =
                                                    new TRTCKaraokeRoomDef.UserInfo();
                                            trtcUserInfo.userId = info.userId;
                                            trtcUserInfo.userAvatar = info.avatarURL;
                                            trtcUserInfo.userName = info.userName;
                                            userList.add(trtcUserInfo);
                                            TRTCLogger.i(TAG, "info:" + info);
                                        }
                                    }
                                    callback.onCallback(code, msg, userList);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    private void getAudienceList(final TRTCKaraokeRoomCallback.UserListCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TXRoomService.getInstance().getAudienceList(new TXUserListCallback() {
                    @Override
                    public void onCallback(final int code, final String msg, final List<TXUserInfo> list) {
                        TRTCLogger.i(TAG,
                                "get audience list finish, code:" + code + " msg:" + msg + " list:"
                                        + (list != null ? list.size() : 0));
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    List<TRTCKaraokeRoomDef.UserInfo> userList = new ArrayList<>();
                                    if (list != null) {
                                        for (TXUserInfo info : list) {
                                            TRTCKaraokeRoomDef.UserInfo trtcUserInfo =
                                                    new TRTCKaraokeRoomDef.UserInfo();
                                            trtcUserInfo.userId = info.userId;
                                            trtcUserInfo.userAvatar = info.avatarURL;
                                            trtcUserInfo.userName = info.userName;
                                            userList.add(trtcUserInfo);
                                            TRTCLogger.i(TAG, "info:" + info);
                                        }
                                    }
                                    callback.onCallback(code, msg, userList);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void enterSeat(final int seatIndex, final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "enterSeat " + seatIndex);
                if (isOnSeat(mUserId)) {
                    runOnDelegateThread(new Runnable() {
                        @Override
                        public void run() {
                            if (callback != null) {
                                callback.onCallback(-1, "you are already in the seat");
                            }
                        }
                    });
                    return;
                }
                mEnterSeatCallback = callback;
                TXRoomService.getInstance().takeSeat(seatIndex, new TXCallback() {
                    @Override
                    public void onCallback(int code, String msg) {
                        if (code != 0) {
                            //出错了，恢复callback
                            mEnterSeatCallback = null;
                            mTakeSeatIndex = -1;
                            if (callback != null) {
                                callback.onCallback(code, msg);
                            }
                        } else {
                            TRTCLogger.i(TAG, "take seat callback success, and wait attrs changed.");
                        }
                    }
                });
            }
        });
    }

    @Override
    public void leaveSeat(final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "leaveSeat " + mTakeSeatIndex);
                if (mTakeSeatIndex == -1) {
                    //已经不再座位上了
                    runOnDelegateThread(new Runnable() {
                        @Override
                        public void run() {
                            if (callback != null) {
                                callback.onCallback(-1, "you are not in the seat");
                            }
                        }
                    });
                    return;
                }
                mLeaveSeatCallback = callback;
                TXRoomService.getInstance().leaveSeat(mTakeSeatIndex, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        if (code != 0) {
                            //出错了，恢复callback
                            mLeaveSeatCallback = null;
                            runOnDelegateThread(new Runnable() {
                                @Override
                                public void run() {
                                    if (callback != null) {
                                        callback.onCallback(code, msg);
                                    }
                                }
                            });
                        }
                    }
                });
            }
        });
    }

    @Override
    public void pickSeat(final int seatIndex, final String userId,
                         final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                //判断该用户是否已经在麦上
                TRTCLogger.i(TAG, "pickSeat " + seatIndex);
                if (isOnSeat(userId)) {
                    runOnDelegateThread(new Runnable() {
                        @Override
                        public void run() {
                            if (callback != null) {
                                callback.onCallback(-1, "该用户已经是麦上主播了");
                            }
                        }
                    });
                    return;
                }
                mPickSeatCallback = callback;
                TXRoomService.getInstance().pickSeat(seatIndex, userId, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        if (code != 0) {
                            //出错了，恢复callback
                            mPickSeatCallback = null;
                            runOnDelegateThread(new Runnable() {
                                @Override
                                public void run() {
                                    if (callback != null) {
                                        callback.onCallback(code, msg);
                                    }
                                }
                            });
                        }
                    }
                });
            }
        });
    }

    @Override
    public void kickSeat(final int index, final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "kickSeat " + index);
                mKickSeatCallback = callback;
                TXRoomService.getInstance().kickSeat(index, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        if (code != 0) {
                            //出错了，恢复callback
                            mKickSeatCallback = null;
                            runOnDelegateThread(new Runnable() {
                                @Override
                                public void run() {
                                    if (callback != null) {
                                        callback.onCallback(code, msg);
                                    }
                                }
                            });
                        }
                    }
                });
            }
        });
    }

    @Override
    public void muteSeat(final int seatIndex, final boolean isMute,
                         final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "muteSeat " + seatIndex + " " + isMute);
                TXRoomService.getInstance().muteSeat(seatIndex, isMute, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void closeSeat(final int seatIndex, final boolean isClose,
                          final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "closeSeat " + seatIndex + " " + isClose);
                TXRoomService.getInstance().closeSeat(seatIndex, isClose, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
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
                mTRTCVoiceService.startMicrophone();
            }
        });
    }

    @Override
    public void stopMicrophone() {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                mTRTCVoiceService.stopMicrophone();
            }
        });
    }

    @Override
    public void setAudioQuality(final int quality) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                mTRTCVoiceService.setAudioQuality(quality);
            }
        });
    }

    @Override
    public void setVoiceEarMonitorEnable(final boolean enable) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                mTRTCVoiceService.enableAudioEarMonitoring(enable);
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
        TRTCLogger.i(TAG, "mute local audio, mute:" + mute);
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                mTRTCVoiceService.muteLocalAudio(mute);
            }
        });
    }

    @Override
    public void setSpeaker(final boolean useSpeaker) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                mTRTCVoiceService.setSpeaker(useSpeaker);
            }
        });
    }

    @Override
    public void setAudioCaptureVolume(final int volume) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                mTRTCVoiceService.setAudioCaptureVolume(volume);
            }
        });
    }

    @Override
    public void setAudioPlayoutVolume(final int volume) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                mTRTCVoiceService.setAudioPlayoutVolume(volume);
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
                TRTCLogger.i(TAG, "mute trtc audio, user id:" + userId);
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
                TRTCLogger.i(TAG, "mute all trtc remote audio success, mute:" + mute);
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
    public TXAudioEffectManager getBgmMusicAudioEffectManager() {
        if (mTRTCBgmService != null) {
            return mTRTCBgmService.getAudioEffectManager();
        }
        if (mTRTCVoiceService != null) {
            return mTRTCVoiceService.getAudioEffectManager();
        }
        TRTCLogger.e(TAG, "getBgmMusicAudioEffectManager is null");
        return null;
    }

    @Override
    public void sendRoomTextMsg(final String message, final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "sendRoomTextMsg");
                TXRoomService.getInstance().sendRoomTextMsg(message, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void sendRoomCustomMsg(final String cmd, final String message,
                                  final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "sendRoomCustomMsg");
                TXRoomService.getInstance().sendRoomCustomMsg(cmd, message, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public String sendInvitation(final String cmd, final String userId, final String content,
                                 final TRTCKaraokeRoomCallback.ActionCallback callback) {
        TRTCLogger.i(TAG, "sendInvitation to " + userId + " cmd:" + cmd + " content:" + content);
        return TXRoomService.getInstance().sendInvitation(cmd, userId, content, new TXCallback() {
            @Override
            public void onCallback(final int code, final String msg) {
                runOnDelegateThread(new Runnable() {
                    @Override
                    public void run() {
                        if (callback != null) {
                            callback.onCallback(code, msg);
                        }
                    }
                });
            }
        });
    }

    @Override
    public void acceptInvitation(final String id, final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "acceptInvitation " + id);
                TXRoomService.getInstance().acceptInvitation(id, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void rejectInvitation(final String id, final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "rejectInvitation " + id);
                TXRoomService.getInstance().rejectInvitation(id, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    @Override
    public void cancelInvitation(final String id, final TRTCKaraokeRoomCallback.ActionCallback callback) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                TRTCLogger.i(TAG, "cancelInvitation " + id);
                TXRoomService.getInstance().cancelInvitation(id, new TXCallback() {
                    @Override
                    public void onCallback(final int code, final String msg) {
                        runOnDelegateThread(new Runnable() {
                            @Override
                            public void run() {
                                if (callback != null) {
                                    callback.onCallback(code, msg);
                                }
                            }
                        });
                    }
                });
            }
        });
    }

    private void enterTRTCRoomInner(final int roomId, final String userId, final String userSig,
                                    final int role, final TRTCKaraokeRoomCallback.ActionCallback callback) {
        // 进入 TRTC 房间
        TRTCLogger.i(TAG, "enter trtc room.");
        mTRTCVoiceService.enterRoom(mSdkAppId, roomId, userId, userSig, role, new TXCallback() {
            @Override
            public void onCallback(final int code, final String msg) {
                TRTCLogger.i(TAG, "enter trtc room finish, code:" + code + " msg:" + msg);
                runOnDelegateThread(new Runnable() {
                    @Override
                    public void run() {
                        if (callback != null) {
                            callback.onCallback(code, msg);
                        }
                    }
                });
                if (code == 0) {
                    if (TXRoomService.getInstance().isOwner()) {
                        mTRTCBgmService.setDefaultStreamRecvMode(false, false);
                        mTRTCBgmService.enterRoom(mSdkAppId, roomId, mBgmUserId, mBgmUserSig, role, null);
                        //房主占座1号麦位
                        enterSeat(0, null);
                        mTRTCVoiceService.muteRemoteAudio(mBgmUserId, true);
                        mTRTCVoiceService.startTRTCPush(roomId, mMixRobotUserId, false);
                    }
                }
            }
        });
    }

    @Override
    public void onRoomDestroy(final String roomId) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                exitRoom(null);
                runOnDelegateThread(new Runnable() {
                    @Override
                    public void run() {
                        if (mDelegate != null) {
                            mDelegate.onRoomDestroy(roomId);
                        }
                    }
                });
            }
        });
    }

    @Override
    public void onRoomRecvRoomTextMsg(final String roomId, final String message, final TXUserInfo userInfo) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    TRTCKaraokeRoomDef.UserInfo throwUser = new TRTCKaraokeRoomDef.UserInfo();
                    throwUser.userId = userInfo.userId;
                    throwUser.userName = userInfo.userName;
                    throwUser.userAvatar = userInfo.avatarURL;
                    mDelegate.onRecvRoomTextMsg(message, throwUser);
                }
            }
        });
    }

    @Override
    public void onRoomRecvRoomCustomMsg(final String roomId, final String cmd, final String message,
                                        final TXUserInfo userInfo) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    TRTCKaraokeRoomDef.UserInfo throwUser = new TRTCKaraokeRoomDef.UserInfo();
                    throwUser.userId = userInfo.userId;
                    throwUser.userName = userInfo.userName;
                    throwUser.userAvatar = userInfo.avatarURL;
                    mDelegate.onRecvRoomCustomMsg(cmd, message, throwUser);
                }
            }
        });
    }

    @Override
    public void onRoomInfoChange(final TXRoomInfo txRoomInfo) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                TRTCKaraokeRoomDef.RoomInfo roomInfo = new TRTCKaraokeRoomDef.RoomInfo();
                roomInfo.roomName = txRoomInfo.roomName;
                int translateRoomId = 0;
                try {
                    translateRoomId = Integer.parseInt(txRoomInfo.roomId);
                } catch (NumberFormatException e) {
                    TRTCLogger.e(TAG, e.getMessage());
                }
                roomInfo.roomId = translateRoomId;
                roomInfo.ownerId = txRoomInfo.ownerId;
                roomInfo.ownerName = txRoomInfo.ownerName;
                roomInfo.coverUrl = txRoomInfo.cover;
                roomInfo.memberCount = txRoomInfo.memberCount;
                roomInfo.needRequest = (txRoomInfo.needRequest == 1);
                if (mDelegate != null) {
                    mDelegate.onRoomInfoChange(roomInfo);
                }
            }
        });
    }

    @Override
    public void onSeatInfoListChange(final List<TXSeatInfo> txSeatInfoList) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                List<TRTCKaraokeRoomDef.SeatInfo> seatInfoList = new ArrayList<>();
                for (TXSeatInfo seatInfo : txSeatInfoList) {
                    TRTCKaraokeRoomDef.SeatInfo info = new TRTCKaraokeRoomDef.SeatInfo();
                    info.userId = seatInfo.user;
                    info.mute = seatInfo.mute;
                    info.status = seatInfo.status;
                    seatInfoList.add(info);
                }
                mSeatInfoList = seatInfoList;
                if (mDelegate != null) {
                    mDelegate.onSeatListChange(seatInfoList);
                }
            }
        });
    }

    @Override
    public void onRoomAudienceEnter(final TXUserInfo userInfo) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    TRTCKaraokeRoomDef.UserInfo throwUser = new TRTCKaraokeRoomDef.UserInfo();
                    throwUser.userId = userInfo.userId;
                    throwUser.userName = userInfo.userName;
                    throwUser.userAvatar = userInfo.avatarURL;
                    mDelegate.onAudienceEnter(throwUser);
                }
            }
        });
    }

    @Override
    public void onRoomAudienceLeave(final TXUserInfo userInfo) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    TRTCKaraokeRoomDef.UserInfo throwUser = new TRTCKaraokeRoomDef.UserInfo();
                    throwUser.userId = userInfo.userId;
                    throwUser.userName = userInfo.userName;
                    throwUser.userAvatar = userInfo.avatarURL;
                    mDelegate.onAudienceExit(throwUser);
                }
            }
        });
    }

    @Override
    public void onSeatTake(final int index, final TXUserInfo userInfo) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                boolean isOwner = TXRoomService.getInstance().isOwner();
                if (userInfo.userId.equals(mUserId)) {
                    //是自己上线了, 切换角色
                    mTakeSeatIndex = index;
                    if (!isOwner) {
                        mTRTCVoiceService.switchToAnchor();
                        mIsAuthor = true;
                        mTRTCVoiceService.muteRemoteAudio(mBgmUserId, true);
                    }
                    boolean mute = mSeatInfoList.get(index).mute;
                    mTRTCVoiceService.muteLocalAudio(mute);
                    if (!mute) {
                        mDelegate.onUserMicrophoneMute(userInfo.userId, false);
                    }
                } else {
                    if (isOwner) {
                        mTRTCVoiceService.startTRTCPush(mRoomId, mMixRobotUserId, true);
                    }
                }
                runOnDelegateThread(new Runnable() {
                    @Override
                    public void run() {
                        if (mDelegate != null) {
                            TRTCKaraokeRoomDef.UserInfo info = new TRTCKaraokeRoomDef.UserInfo();
                            info.userId = userInfo.userId;
                            info.userAvatar = userInfo.avatarURL;
                            info.userName = userInfo.userName;
                            mDelegate.onAnchorEnterSeat(index, info);
                        }
                        if (mPickSeatCallback != null) {
                            mPickSeatCallback.onCallback(0, "pick seat success");
                            mPickSeatCallback = null;
                        }
                    }
                });
                if (userInfo.userId.equals(mUserId)) {
                    //在回调出去
                    runOnDelegateThread(new Runnable() {
                        @Override
                        public void run() {
                            if (mEnterSeatCallback != null) {
                                mEnterSeatCallback.onCallback(0, "enter seat success");
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
    public void onSeatLeave(final int index, final TXUserInfo userInfo) {
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                if (userInfo.userId.equals(mUserId)) {
                    //自己下线了~
                    mTakeSeatIndex = -1;
                    mTRTCVoiceService.switchToAudience();
                }
                runOnDelegateThread(new Runnable() {
                    @Override
                    public void run() {
                        if (mDelegate != null) {
                            TRTCKaraokeRoomDef.UserInfo info = new TRTCKaraokeRoomDef.UserInfo();
                            info.userId = userInfo.userId;
                            info.userAvatar = userInfo.avatarURL;
                            info.userName = userInfo.userName;
                            mDelegate.onAnchorLeaveSeat(index, info);
                        }
                        if (mKickSeatCallback != null) {
                            mKickSeatCallback.onCallback(0, "kick seat success");
                            mKickSeatCallback = null;
                        }
                    }
                });
                if (userInfo.userId.equals(mUserId)) {
                    runOnDelegateThread(new Runnable() {
                        @Override
                        public void run() {
                            if (mLeaveSeatCallback != null) {
                                mLeaveSeatCallback.onCallback(0, "enter seat success");
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
        if (TXRoomService.getInstance().isOwner()) {
            // 主播是房主
            if (mSeatInfoList != null) {
                int kickSeatIndex = -1;
                for (int i = 0; i < mSeatInfoList.size(); i++) {
                    if (userId.equals(mSeatInfoList.get(i).userId)) {
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
        Log.d(TAG, "onTRTCVideoAvailable: userId = " + userId + " , available = " + available);
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                if (available) {
                    startRemoteView(userId, null);
                } else {
                    stopRemoteView(userId);
                }
            }
        });
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
    public void startPlayMusic(int musicID, String originalUrl) {
        boolean isOwner = TXRoomService.getInstance().isOwner();
        if (isOwner) {
            enableBlackStream(true);
        }
        if (mChorusExtension != null) {
            mChorusExtension.startChorus(musicID, originalUrl, isOwner);
        }
    }

    public void setMusicVolume(int id, int volume) {
        if (volume < 0) {
            volume = 0;
        }
        if (volume > 100) {
            volume = 100;
        }
        getBgmMusicAudioEffectManager().setMusicPublishVolume(id, volume);
        getBgmMusicAudioEffectManager().setMusicPlayoutVolume(id, volume);
    }

    @Override
    public void stopPlayMusic() {
        boolean isOwner = TXRoomService.getInstance().isOwner();
        if (isOwner) {
            enableBlackStream(false);
        }
        if (mChorusExtension != null) {
            mChorusExtension.stopChorus();
        }
    }

    @Override
    public void pausePlayMusic() {
        getBgmMusicAudioEffectManager().pausePlayMusic(TYPE_ORIGIN);
        getBgmMusicAudioEffectManager().pausePlayMusic(TYPE_ACCOMPANY);
    }

    @Override
    public void resumePlayMusic() {
        getBgmMusicAudioEffectManager().resumePlayMusic(TYPE_ORIGIN);
        getBgmMusicAudioEffectManager().resumePlayMusic(TYPE_ACCOMPANY);
    }

    @Override
    public void onChorusProgress(int musicId, long curPtsMS, long durationMS) {
        if (mDelegate != null) {
            mDelegate.onMusicProgressUpdate(String.valueOf(musicId), curPtsMS, durationMS);
        }
    }

    @Override
    public void onMusicCompletePlaying(final int musicID) {
        runOnDelegateThread(new Runnable() {
            @Override
            public void run() {
                if (mDelegate != null) {
                    mDelegate.onMusicCompletePlaying(String.valueOf(musicID));
                }
            }
        });
    }

    @Override
    public void onReceiveAnchorSendChorusMsg(String musicID) {
        if (!mIsAuthor) {
            return;
        }
        if (mDelegate != null) {
            mDelegate.onReceiveAnchorSendChorusMsg(musicID);
        }
    }

    private void enableBlackStream(boolean enable) {
        mTRTCVoiceService.enableBlackStream(enable);
    }

    @Override
    public void onRecvSEIMsg(final String userId, final byte[] data) {
        if (mIsAuthor) {
            return;
        }
        if (data == null) {
            return;
        }
        Gson gson = new Gson();
        String result = new String(data);
        try {
            KaraokeSEIJsonData jsonData = gson.fromJson(result, KaraokeSEIJsonData.class);
            final long progressTime = jsonData.getCurrentTime();
            final int musicId = jsonData.getMusicId();
            final long totalTime = jsonData.getTotalTime();
            runOnDelegateThread(new Runnable() {
                @Override
                public void run() {
                    if (mDelegate != null && data != null) {
                        mDelegate.onMusicProgressUpdate(String.valueOf(musicId), progressTime, totalTime);
                    }
                }
            });
        } catch (Exception e) {
            TRTCLogger.e(TAG, "onRecvSEIMsg parse error " + e + " , result = " + result);
        }
    }

    @Override
    public void onRecvCustomCmdMsg(String userId, int cmdID, int seq, byte[] message) {
        if (mChorusExtension != null) {
            mChorusExtension.onRecvCustomCmdMsg(userId, cmdID, seq, message);
        }
    }

    public void startRemoteView(final String userId, final TXCloudVideoView view) {
        mTRTCVoiceService.startRemoteView(userId, view);
    }

    public void stopRemoteView(final String userId) {
        mTRTCVoiceService.stopRemoteView(userId);
    }

}

package com.tencent.liteav.tuikaraoke.model.impl.im;

import android.content.Context;
import android.text.TextUtils;
import android.util.Pair;

import com.google.gson.Gson;
import com.tencent.imsdk.BaseConstants;
import com.tencent.imsdk.v2.V2TIMCallback;
import com.tencent.imsdk.v2.V2TIMGroupInfo;
import com.tencent.imsdk.v2.V2TIMGroupListener;
import com.tencent.imsdk.v2.V2TIMGroupMemberFullInfo;
import com.tencent.imsdk.v2.V2TIMGroupMemberInfo;
import com.tencent.imsdk.v2.V2TIMGroupMemberInfoResult;
import com.tencent.imsdk.v2.V2TIMManager;
import com.tencent.imsdk.v2.V2TIMMessage;
import com.tencent.imsdk.v2.V2TIMSDKConfig;
import com.tencent.imsdk.v2.V2TIMSDKListener;
import com.tencent.imsdk.v2.V2TIMSignalingListener;
import com.tencent.imsdk.v2.V2TIMSimpleMsgListener;
import com.tencent.imsdk.v2.V2TIMUserFullInfo;
import com.tencent.imsdk.v2.V2TIMValueCallback;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef.UserInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.qcloud.tuicore.TUILogin;
import com.tencent.qcloud.tuicore.interfaces.TUICallback;
import com.tencent.qcloud.tuicore.interfaces.TUIValueCallback;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class KaraokeIMService extends V2TIMSDKListener {
    private static final String TAG = "KaraokeIMService";
    private static final int CODE_ERROR = -1;

    private Context                           mContext;
    private KaraokeIMServiceObserver          mDelegate;
    private boolean                           mIsInitIMSDK;
    private boolean                           mIsLogin;
    private boolean                           mIsEnterRoom;
    private String                            mRoomId;
    private String                            mSelfUserId;
    private String                            mOwnerUserId;
    private String                            mSelfUserName;
    private TRTCKaraokeRoomDef.RoomInfo       mRoomInfo;
    private List<TRTCKaraokeRoomDef.SeatInfo> mSeatInfoList;
    private KtvRoomSimpleListener             mSimpleListener;
    private KtvRoomGroupListener              mGroupListener;
    private KtvRoomSignalListener             mSignalListener;

    public KaraokeIMService(Context context) {
        mContext = context;
        mSelfUserId = "";
        mOwnerUserId = "";
        mRoomId = "";
        mRoomInfo = null;
        mSimpleListener = new KtvRoomSimpleListener();
        mGroupListener = new KtvRoomGroupListener();
        mSignalListener = new KtvRoomSignalListener();
    }

    public void setDelegate(KaraokeIMServiceObserver delegate) {
        mDelegate = delegate;
    }

    public void login(int sdkAppId, final String userId, String userSig, final TUICallback callback) {
        if (TUILogin.isUserLogined()) {
            mIsLogin = true;
            mSelfUserId = userId;
            TRTCLogger.i(TAG, "already login.");
            TUICallback.onSuccess(callback);
            return;
        }
        // 未初始化 IM 先初始化 IM
        if (!mIsInitIMSDK) {
            V2TIMSDKConfig config = new V2TIMSDKConfig();
            TUILogin.init(mContext, sdkAppId, config, null);
            mIsInitIMSDK = true;
        }
        TUILogin.login(userId, userSig, new V2TIMCallback() {
            @Override
            public void onError(int code, String msg) {
                TRTCLogger.e(TAG, "login fail code: " + code + " msg:" + msg);
                TUICallback.onError(callback, code, msg);
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "login onSuccess");
                mIsLogin = true;
                mSelfUserId = userId;
                getSelfInfo();
                TUICallback.onSuccess(callback);
            }
        });
    }

    private void initIMListener() {
        V2TIMManager.getInstance().addGroupListener(mGroupListener);
        V2TIMManager.getSignalingManager().addSignalingListener(mSignalListener);
        V2TIMManager.getMessageManager();
        V2TIMManager.getInstance().addSimpleMsgListener(mSimpleListener);
    }

    private void unInitImListener() {
        V2TIMManager.getInstance().removeGroupListener(mGroupListener);
        V2TIMManager.getSignalingManager().removeSignalingListener(mSignalListener);
        V2TIMManager.getInstance().removeSimpleMsgListener(mSimpleListener);
    }

    private void getSelfInfo() {
        List<String> userIds = new ArrayList<>();
        userIds.add(mSelfUserId);
        V2TIMManager.getInstance().getUsersInfo(userIds, new V2TIMValueCallback<List<V2TIMUserFullInfo>>() {
            @Override
            public void onError(int i, String s) {

            }

            @Override
            public void onSuccess(List<V2TIMUserFullInfo> v2TIMUserFullInfos) {
                mSelfUserName = v2TIMUserFullInfos.get(0).getNickName();
            }
        });
    }

    public void logout(final TUICallback callback) {
        if (!isLogin()) {
            TRTCLogger.e(TAG, "start logout fail, not login yet.");
            TUICallback.onError(callback, CODE_ERROR, "start logout fail, not login yet.");
            return;
        }
        if (isEnterRoom()) {
            TRTCLogger.e(TAG, "start logout fail, you are in room:" + mRoomId
                    + ", please exit room before logout.");
            TUICallback.onError(callback, CODE_ERROR, "start logout fail, you are in room:"
                        + mRoomId + ", please exit room" + " before logout.");
            return;
        }
        mIsLogin = false;
        mSelfUserId = "";
        TUILogin.logout(new V2TIMCallback() {
            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "logout im success.");
                TUICallback.onSuccess(callback);
            }

            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "logout fail, code:" + i + " msg:" + s);
                TUICallback.onError(callback, i, s);
            }
        });
    }

    public void setSelfProfile(final String userName, final String avatarUrl, final TUICallback callback) {
        if (!isLogin()) {
            TRTCLogger.e(TAG, "set profile fail, not login yet.");
            TUICallback.onError(callback, CODE_ERROR, "set profile fail, not login yet.");
            return;
        }
        mSelfUserName = userName;
        V2TIMUserFullInfo v2TIMUserFullInfo = new V2TIMUserFullInfo();
        v2TIMUserFullInfo.setNickname(userName);
        v2TIMUserFullInfo.setFaceUrl(avatarUrl);
        V2TIMManager.getInstance().setSelfInfo(v2TIMUserFullInfo, new V2TIMCallback() {
            @Override
            public void onError(int code, String desc) {
                TRTCLogger.e(TAG, "set profile code:" + code + " msg:" + desc);
                TUICallback.onError(callback, code, desc);
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "set profile success.");
                TUICallback.onSuccess(callback);
            }
        });
    }

    public void createRoom(final String roomId, final String roomName, final String coverUrl, boolean needRequest,
                           final List<TRTCKaraokeRoomDef.SeatInfo> seatInfoList, final TUICallback callback) {
        // 如果已经在一个房间了，则不允许再次进入
        if (isEnterRoom()) {
            TRTCLogger.e(TAG, "you have been in room:" + mRoomId + " can't create another room:" + roomId);
            TUICallback.onError(callback, CODE_ERROR,
                        "you have been in room:" + mRoomId + " can't create another room:" + roomId);
            return;
        }
        if (!isLogin()) {
            TRTCLogger.e(TAG, "im not login yet, create room fail.");
            TUICallback.onError(callback, CODE_ERROR, "im not login yet, create room fail.");
            return;
        }
        resetStatus();
        final V2TIMManager manager = V2TIMManager.getInstance();
        mRoomId = roomId;
        mOwnerUserId = mSelfUserId;
        mSeatInfoList = seatInfoList;
        mRoomInfo = new TRTCKaraokeRoomDef.RoomInfo();
        mRoomInfo.ownerId = mSelfUserId;
        mRoomInfo.ownerName = mSelfUserName;
        mRoomInfo.roomName = roomName;
        mRoomInfo.cover = coverUrl;
        mRoomInfo.seatSize = seatInfoList.size();
        mRoomInfo.needRequest = needRequest ? 1 : 0;
        manager.createGroup(V2TIMManager.GROUP_TYPE_AVCHATROOM, roomId, roomName, new V2TIMValueCallback<String>() {
            @Override
            public void onError(final int code, String s) {
                TRTCLogger.e(TAG, "createRoom error " + code);
                String msg = s;
                // 通用提示
                if (code == 10036) {
                    msg = mContext.getString(R.string.trtckaraoke_create_room_limit);
                }
                if (code == 10037) {
                    msg = mContext.getString(R.string.trtckaraoke_create_or_join_group_limit);
                }
                if (code == 10038) {
                    msg = mContext.getString(R.string.trtckaraoke_group_member_limit);
                }
                //特殊处理
                if (code == 10025 || code == 10021) {
                    // 10025 表明群主是自己，那么认为创建房间成功
                    // 10021 表明群组 ID 已被其他人使用，那么认为创建房间成功
                    onSuccess(s);
                } else {
                    TRTCLogger.e(TAG, "create room fail, code:" + code + " msg:" + msg);
                    TUICallback.onError(callback, code, msg);
                }
            }

            @Override
            public void onSuccess(String s) {
                setGroupInfo(roomId, roomName, coverUrl, mSelfUserName);
                TUICallback.onSuccess(callback);
            }
        });
    }

    /**
     * 将一些基本信息写到IM里面方便列表的读取
     *
     * @param roomId
     * @param roomName
     * @param coverUrl
     * @param userName
     */
    private void setGroupInfo(String roomId, String roomName, String coverUrl, String userName) {
        V2TIMGroupInfo groupInfo = new V2TIMGroupInfo();
        groupInfo.setGroupID(roomId);
        groupInfo.setGroupName(roomName);
        groupInfo.setFaceUrl(coverUrl);
        groupInfo.setIntroduction(userName);
        V2TIMManager.getGroupManager().setGroupInfo(groupInfo, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.w(TAG, "set group info error:" + i + " msg:" + s);
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "set group info success");
            }
        });
    }

    private void initGroupAttributes(final TUICallback callback) {
        // 创建房间需要初始化座位
        HashMap<String, String> roomMap = IMProtocol.getInitRoomMap(mRoomInfo, mSeatInfoList);
        V2TIMManager.getGroupManager().initGroupAttributes(mRoomId, roomMap, new V2TIMCallback() {
            @Override
            public void onError(int code, String s) {
                TRTCLogger.i(TAG, "init room info and seat failed. code:" + code + " message: " + s);
                if (code == BaseConstants.ERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT) {
                    onSuccess();
                } else {
                    TUICallback.onError(callback, code, s);
                }
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "init room info and seat success.");
                TUICallback.onSuccess(callback);
            }
        });
    }

    public void destroyRoom(final TUICallback callback) {
        if (!isOwner()) {
            TRTCLogger.e(TAG, "only owner could destroy room");
            TUICallback.onError(callback, -1, "only owner could destroy room");
            return;
        }
        V2TIMManager.getInstance().dismissGroup(mRoomId, new V2TIMCallback() {
            @Override
            public void onError(int code, String msg) {
                if (code == 10007) {
                    //权限不足
                    TRTCLogger.i(TAG, "you're not real owner, start logic destroy.");
                    //清空群属性
                    cleanGroupAttr();
                    sendGroupMsg(IMProtocol.getRoomDestroyMsg(), callback);
                }
                resetStatus();
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "you're real owner, destroy success.");
                resetStatus();
                TUICallback.onSuccess(callback);
            }
        });
    }

    private void cleanGroupAttr() {
        V2TIMManager.getGroupManager().deleteGroupAttributes(mRoomId, null, null);
    }

    public void enterRoom(final String roomId, final TUICallback callback) {
        resetStatus();
        mRoomId = roomId;
        initIMListener();
        V2TIMManager.getInstance().joinGroup(roomId, "", new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                if (i == BaseConstants.ERR_SVR_GROUP_ALLREADY_MEMBER) {
                    onSuccess();
                } else {
                    TRTCLogger.e(TAG, "join group error, enter room fail. code:" + i + " msg:" + s);
                    TUICallback.onError(callback, -1,
                            "join group error, enter room fail. code:" + i + " msg:" + s);
                }
            }

            @Override
            public void onSuccess() {
                getGroupAttrs(callback);
            }
        });
    }

    public void exitRoom(final TUICallback callback) {
        if (!isEnterRoom()) {
            TRTCLogger.e(TAG, "not enter room yet, can't exit room.");
            TUICallback.onError(callback, CODE_ERROR, "not enter room yet, can't exit room.");
            return;
        }
        V2TIMManager.getInstance().quitGroup(mRoomId, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "exit room fail, code:" + i + " msg:" + s);
                resetStatus();
                TUICallback.onError(callback, i, s);
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "exit room success.");
                resetStatus();
                TUICallback.onSuccess(callback);
            }
        });
    }

    public void takeSeat(int index, TUICallback callback) {
        if (mSeatInfoList == null || index >= mSeatInfoList.size()) {
            TRTCLogger.e(TAG, "seat info list is empty or index error");
            TUICallback.onError(callback, -1, "seat info list is empty or index error");
            return;
        }
        TRTCKaraokeRoomDef.SeatInfo info = mSeatInfoList.get(index);
        if (info.status == TRTCKaraokeRoomDef.SeatInfo.STATUS_USED
                || info.status == TRTCKaraokeRoomDef.SeatInfo.STATUS_CLOSE) {
            TRTCLogger.e(TAG, "seat status is " + info.status);
            TUICallback.onError(callback, -1,
                    info.status == TRTCKaraokeRoomDef.SeatInfo.STATUS_USED ? "seat is used" : "seat is close");
            return;
        }

        if (TextUtils.isEmpty(mSelfUserId)) {
            TUICallback.onError(callback, -1, "self userId is null");
            return;
        }

        // 修改属性列表
        TRTCKaraokeRoomDef.SeatInfo changeInfo = new TRTCKaraokeRoomDef.SeatInfo();
        changeInfo.status = TRTCKaraokeRoomDef.SeatInfo.STATUS_USED;
        changeInfo.mute = info.mute;
        changeInfo.user = mSelfUserId;
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void leaveSeat(int index, TUICallback callback) {
        if (mSeatInfoList == null || index >= mSeatInfoList.size()) {
            TRTCLogger.e(TAG, "seat info list is empty or index error");
            TUICallback.onError(callback, -1, "seat info list is empty or index error");
            return;
        }
        TRTCKaraokeRoomDef.SeatInfo info = mSeatInfoList.get(index);
        if (!mSelfUserId.equals(info.user)) {
            TRTCLogger.e(TAG, mSelfUserId + " not in the seat " + index);
            TUICallback.onError(callback, -1, mSelfUserId + " not in the seat " + index);
            return;
        }

        TRTCKaraokeRoomDef.SeatInfo changeInfo = new TRTCKaraokeRoomDef.SeatInfo();
        changeInfo.status = TRTCKaraokeRoomDef.SeatInfo.STATUS_UNUSED;
        changeInfo.mute = info.mute;
        changeInfo.user = "";
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void pickSeat(int index, String userId, TUICallback callback) {
        if (TextUtils.isEmpty(userId)) {
            TUICallback.onError(callback, -1, "userId is null");
            return;
        }

        if (!isOwner()) {
            TRTCLogger.e(TAG, "only owner could pick seat");
            TUICallback.onError(callback, -1, "only owner could pick seat");
            return;
        }
        if (mSeatInfoList == null || index >= mSeatInfoList.size()) {
            TRTCLogger.e(TAG, "seat info list is empty or index error");
            TUICallback.onError(callback, -1, "seat info list is empty or index error");
            return;
        }
        TRTCKaraokeRoomDef.SeatInfo info = mSeatInfoList.get(index);
        if (info.status == TRTCKaraokeRoomDef.SeatInfo.STATUS_USED
                || info.status == TRTCKaraokeRoomDef.SeatInfo.STATUS_CLOSE) {
            TRTCLogger.e(TAG, "seat status is " + info.status);
            if (callback != null) {
                TUICallback.onError(callback, -1,
                        info.status == TRTCKaraokeRoomDef.SeatInfo.STATUS_USED ? "seat is used" : "seat is close");
            }
            return;
        }

        TRTCKaraokeRoomDef.SeatInfo changeInfo = new TRTCKaraokeRoomDef.SeatInfo();
        changeInfo.status = TRTCKaraokeRoomDef.SeatInfo.STATUS_USED;
        changeInfo.mute = info.mute;
        changeInfo.user = userId;
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void kickSeat(int index, TUICallback callback) {
        if (!isOwner()) {
            TRTCLogger.e(TAG, "only owner could kick seat");
            TUICallback.onError(callback, -1, "only owner could kick seat");
            return;
        }
        if (mSeatInfoList == null || index >= mSeatInfoList.size()) {
            TRTCLogger.e(TAG, "seat info list is empty or index error");
            TUICallback.onError(callback, -1, "seat info list is empty or index error");
            return;
        }

        TRTCKaraokeRoomDef.SeatInfo info = mSeatInfoList.get(index);
        TRTCKaraokeRoomDef.SeatInfo changeInfo = new TRTCKaraokeRoomDef.SeatInfo();
        changeInfo.status = TRTCKaraokeRoomDef.SeatInfo.STATUS_UNUSED;
        changeInfo.mute = info.mute;
        changeInfo.user = "";
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void muteSeat(int index, boolean mute, TUICallback callback) {
        if (!isOwner()) {
            TRTCLogger.e(TAG, "only owner could kick seat");
            TUICallback.onError(callback, -1, "only owner could kick seat");
            return;
        }

        TRTCKaraokeRoomDef.SeatInfo info = mSeatInfoList.get(index);
        TRTCKaraokeRoomDef.SeatInfo changeInfo = new TRTCKaraokeRoomDef.SeatInfo();
        changeInfo.status = info.status;
        changeInfo.mute = mute;
        changeInfo.user = info.user;
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void closeSeat(int index, boolean isClose, TUICallback callback) {
        if (!isOwner()) {
            TRTCLogger.e(TAG, "only owner could close seat");
            TUICallback.onError(callback, -1, "only owner could close seat");
            return;
        }
        int changeStatus = isClose ? TRTCKaraokeRoomDef.SeatInfo.STATUS_CLOSE :
                TRTCKaraokeRoomDef.SeatInfo.STATUS_UNUSED;
        TRTCKaraokeRoomDef.SeatInfo info = mSeatInfoList.get(index);
        if (info.status == changeStatus) {
            TUICallback.onSuccess(callback);
            return;
        }
        TRTCKaraokeRoomDef.SeatInfo changeInfo = new TRTCKaraokeRoomDef.SeatInfo();
        changeInfo.status = changeStatus;
        changeInfo.mute = info.mute;
        changeInfo.user = "";
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    private void getGroupAttrs(final TUICallback callback) {
        V2TIMManager.getGroupManager().getGroupAttributes(mRoomId, null,
                new V2TIMValueCallback<Map<String, String>>() {
                    @Override
                    public void onError(int code, String msg) {
                        TRTCLogger.e(TAG, "get group attrs error, code:" + code + " msg:" + msg);
                        TUICallback.onError(callback, code, msg);
                    }

                    @Override
                    public void onSuccess(Map<String, String> attrMap) {
                        if (attrMap == null || attrMap.isEmpty()) {
                            if (TextUtils.equals(mSelfUserId, mOwnerUserId)) {
                                // 房主写入群属性
                                initGroupAttributes(new TUICallback() {

                                    @Override
                                    public void onSuccess() {
                                        // 群属性写入成功后，再读一次
                                        getGroupAttrs(callback);
                                    }

                                    @Override
                                    public void onError(int errorCode, String errorMessage) {
                                        TRTCLogger.e(TAG, "init group attrs error, enter room fail."
                                                + " code:" + errorCode + " msg:" + errorMessage);
                                        TUICallback.onError(callback, errorCode, errorMessage);
                                    }
                                });
                            } else {
                                // 观众直接报错
                                TUICallback.onError(callback, -1, "group room info is empty, enter room fail.");
                            }
                            return;
                        }

                        TRTCLogger.i(TAG, "getGroupAttrs attrMap:" + attrMap);
                        mIsEnterRoom = true;
                        TRTCKaraokeRoomDef.RoomInfo roomInfo = IMProtocol.getRoomInfoFromAttr(attrMap);
                        if (roomInfo == null) {
                            TRTCLogger.e(TAG, "group room info is empty");
                            TUICallback.onError(callback, -1, "group room info is empty");
                            return;
                        }
                        mRoomInfo = roomInfo;
                        mRoomInfo.roomId = mRoomId;
                        mOwnerUserId = mRoomInfo.ownerId;
                        if (mRoomInfo.seatSize == null) {
                            mRoomInfo.seatSize = 0;
                        }
                        if (mDelegate != null) {
                            mDelegate.onRoomInfoChange(mRoomInfo);
                        }
                        onSeatAttrMapChanged(attrMap, mRoomInfo.seatSize);
                        TUICallback.onSuccess(callback);
                    }
                });
    }

    private void onSeatAttrMapChanged(Map<String, String> attrMap, int seatSize) {
        List<TRTCKaraokeRoomDef.SeatInfo> txSeatInfoList = IMProtocol.getSeatListFromAttr(attrMap, seatSize);
        if (mSeatInfoList == null) {
            //观众进房时mSeatInfoList为null，这里初始化一下。
            mSeatInfoList = new ArrayList<>(seatSize);
            for (int i = 0; i < seatSize; i++) {
                mSeatInfoList.add(new TRTCKaraokeRoomDef.SeatInfo());
            }
        }
        final List<TRTCKaraokeRoomDef.SeatInfo> oldTXSeatInfoList = mSeatInfoList;
        mSeatInfoList = txSeatInfoList;
        if (mDelegate != null) {
            mDelegate.onSeatInfoListChange(txSeatInfoList);
        }
        try {
            for (int i = 0; i < seatSize; i++) {
                TRTCKaraokeRoomDef.SeatInfo oldInfo = oldTXSeatInfoList.get(i);
                TRTCKaraokeRoomDef.SeatInfo newInfo = txSeatInfoList.get(i);
                if (oldInfo.status == TRTCKaraokeRoomDef.SeatInfo.STATUS_CLOSE
                        && newInfo.status == TRTCKaraokeRoomDef.SeatInfo.STATUS_UNUSED) {
                    onSeatClose(i, false);
                } else if (oldInfo.status != newInfo.status) {
                    switch (newInfo.status) {
                        case TRTCKaraokeRoomDef.SeatInfo.STATUS_UNUSED:
                            onSeatLeave(i, oldInfo.user);
                            break;
                        case TRTCKaraokeRoomDef.SeatInfo.STATUS_USED:
                            onSeatTake(i, newInfo.user);
                            break;
                        case TRTCKaraokeRoomDef.SeatInfo.STATUS_CLOSE:
                            onSeatClose(i, true);
                            break;
                        default:
                            break;
                    }
                }
                if (oldInfo.mute != newInfo.mute) {
                    onSeatMute(i, newInfo.mute);
                }
            }
        } catch (Exception e) {
            TRTCLogger.e(TAG, "group attr changed, seat compare error:" + e.getCause());
        }
    }

    private void modifyGroupAttrs(HashMap<String, String> map, final TUICallback callback) {
        TRTCLogger.d(TAG, "modify group attrs, map:" + map);
        V2TIMManager.getGroupManager().setGroupAttributes(mRoomId, map, new V2TIMCallback() {
            @Override
            public void onError(int code, String message) {
                TRTCLogger.e(TAG, "modify group attrs error, code:" + code + " message" + message);
                TUICallback.onError(callback, code, message);
                //当前群属性修改的版本与后台版本不匹配
                if (code == BaseConstants.ERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT) {
                    getGroupAttrs(callback);
                }
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "modify group attrs success");
                TUICallback.onSuccess(callback);
            }
        });
    }

    public void getUserInfo(List<String> userList, final TUIValueCallback<List<UserInfo>> callback) {
        if (!isEnterRoom()) {
            TRTCLogger.e(TAG, "get user info list fail, not enter room yet.");
            TUIValueCallback.onError(callback, CODE_ERROR, "get user info list fail, not enter room yet.");
            return;
        }
        if (userList == null || userList.size() == 0) {
            TRTCLogger.e(TAG, "get user info list fail, user list is empty.");
            TUIValueCallback.onError(callback, CODE_ERROR, "get user info list fail, user list is empty.");
            return;
        }
        TRTCLogger.i(TAG, "get user info list " + userList);
        V2TIMManager.getInstance().getUsersInfo(userList, new V2TIMValueCallback<List<V2TIMUserFullInfo>>() {
            @Override
            public void onError(int code, String msg) {
                TRTCLogger.e(TAG, "get user info list fail, code:" + code);
                TUIValueCallback.onError(callback, code, msg);
            }

            @Override
            public void onSuccess(List<V2TIMUserFullInfo> v2TIMUserFullInfos) {
                List<TRTCKaraokeRoomDef.UserInfo> list = new ArrayList<>();
                if (v2TIMUserFullInfos != null && v2TIMUserFullInfos.size() != 0) {
                    for (int i = 0; i < v2TIMUserFullInfos.size(); i++) {
                        TRTCKaraokeRoomDef.UserInfo userInfo = new TRTCKaraokeRoomDef.UserInfo();
                        userInfo.userName = v2TIMUserFullInfos.get(i).getNickName();
                        userInfo.userId = v2TIMUserFullInfos.get(i).getUserID();
                        userInfo.avatarURL = v2TIMUserFullInfos.get(i).getFaceUrl();
                        list.add(userInfo);
                    }
                }
                TUIValueCallback.onSuccess(callback, list);
            }
        });
    }

    public void sendRoomTextMsg(final String msg, final TUICallback callback) {
        if (!isEnterRoom()) {
            TRTCLogger.e(TAG, "send room text fail, not enter room yet.");
            TUICallback.onError(callback, -1, "send room text fail, not enter room yet.");
            return;
        }

        V2TIMManager.getInstance().sendGroupTextMessage(msg, mRoomId, V2TIMMessage.V2TIM_PRIORITY_NORMAL,
                new V2TIMValueCallback<V2TIMMessage>() {
                    @Override
                    public void onError(int i, String s) {
                        TRTCLogger.e(TAG, "sendGroupTextMessage error " + i + " msg:" + msg);
                        TUICallback.onError(callback, i, s);
                    }

                    @Override
                    public void onSuccess(V2TIMMessage v2TIMMessage) {
                        TUICallback.onSuccess(callback);
                    }
                });
    }

    public void sendRoomCustomMsg(String cmd, String message, final TUICallback callback) {
        if (!isEnterRoom()) {
            TRTCLogger.e(TAG, "send room custom msg fail, not enter room yet.");
            TUICallback.onError(callback, -1, "send room custom msg fail, not enter room yet.");
            return;
        }
        sendGroupMsg(IMProtocol.getCusMsgJsonStr(cmd, message), callback);
    }

    public void sendGroupMsg(String data, final TUICallback callback) {
        V2TIMManager.getInstance().sendGroupCustomMessage(data.getBytes(), mRoomId,
                V2TIMMessage.V2TIM_PRIORITY_NORMAL, new V2TIMValueCallback<V2TIMMessage>() {
                    @Override
                    public void onError(int i, String s) {
                        TRTCLogger.e(TAG, "sendGroupMsg error " + i + " msg:" + s);
                        TUICallback.onError(callback, i, s);
                    }

                    @Override
                    public void onSuccess(V2TIMMessage v2TIMMessage) {
                        TUICallback.onSuccess(callback);
                    }
                });
    }

    public boolean isLogin() {
        return mIsLogin;
    }

    public boolean isEnterRoom() {
        return mIsLogin && mIsEnterRoom;
    }

    public String getOwnerUserId() {
        return mOwnerUserId;
    }

    public boolean isOwner() {
        return mSelfUserId.equals(mOwnerUserId);
    }

    private void resetStatus() {
        mIsEnterRoom = false;
        mRoomId = "";
        unInitImListener();
    }

    private void onSeatTake(final int index, final String userId) {
        TRTCLogger.i(TAG, "onSeatTake " + index + " userInfo:" + userId);
        List<String> userIdList = new ArrayList<>();
        userIdList.add(userId);
        getUserInfo(userIdList, new TUIValueCallback<List<UserInfo>>() {
            @Override
            public void onSuccess(List<UserInfo> list) {
                if (mDelegate != null) {
                    mDelegate.onSeatTake(index, list.get(0));
                }
            }

            @Override
            public void onError(int errorCode, String errorMessage) {
                TRTCLogger.e(TAG, "onSeatTake get user info error!");
                if (mDelegate != null) {
                    UserInfo userInfo = new UserInfo();
                    userInfo.userId = userId;
                    mDelegate.onSeatTake(index, userInfo);
                }
            }
        });
    }

    private void onSeatClose(int index, boolean isClose) {
        TRTCLogger.i(TAG, "onSeatClose " + index);
        if (mDelegate != null) {
            mDelegate.onSeatClose(index, isClose);
        }
    }

    private void onSeatLeave(final int index, final String userId) {
        TRTCLogger.i(TAG, "onSeatLeave " + index + " userId:" + userId);
        List<String> userIdList = new ArrayList<>();
        userIdList.add(userId);
        getUserInfo(userIdList, new TUIValueCallback<List<UserInfo>>() {
            @Override
            public void onSuccess(List<UserInfo> list) {
                if (mDelegate != null) {
                    mDelegate.onSeatLeave(index, list.get(0));
                }
            }

            @Override
            public void onError(int errorCode, String errorMessage) {
                TRTCLogger.e(TAG, "onSeatLeave get user info error!");
                if (mDelegate != null) {
                    UserInfo userInfo = new UserInfo();
                    userInfo.userId = userId;
                    mDelegate.onSeatLeave(index, userInfo);
                }
            }
        });
    }

    private void onSeatMute(int index, boolean mute) {
        TRTCLogger.i(TAG, "onSeatMute " + index + " mute:" + mute);
        if (mDelegate != null) {
            mDelegate.onSeatMute(index, mute);
        }
    }

    public String sendInvitation(String cmd, String userId, String content, final TUICallback callback) {
        int roomId = 0;
        try {
            roomId = Integer.parseInt(mRoomId);
        } catch (Exception e) {
            TRTCLogger.e(TAG, "room is not right: " + mRoomId);
        }
        SignallingData signallingData = createSignallingData();
        SignallingData.DataInfo dataInfo = signallingData.getData();
        dataInfo.setCmd(cmd);
        dataInfo.setSeatNumber(content);
        dataInfo.setRoomID(roomId);
        String json = new Gson().toJson(signallingData);
        TRTCLogger.i(TAG, "send " + userId + " json:" + json);
        return V2TIMManager.getSignalingManager().invite(userId, json, true, null, 0, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "sendInvitation error " + i);
                TUICallback.onError(callback, i, s);
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "sendInvitation success ");
                TUICallback.onSuccess(callback);
            }
        });
    }

    public void acceptInvitation(String id, final TUICallback callback) {
        TRTCLogger.i(TAG, "acceptInvitation " + id);
        SignallingData signallingData = createSignallingData();
        String json = new Gson().toJson(signallingData);
        V2TIMManager.getSignalingManager().accept(id, json, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "acceptInvitation error " + i);
                TUICallback.onError(callback, i, s);
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "acceptInvitation success ");
                TUICallback.onSuccess(callback);
            }
        });
    }

    public void rejectInvitation(String id, final TUICallback callback) {
        TRTCLogger.i(TAG, "rejectInvitation " + id);
        SignallingData signallingData = createSignallingData();
        String json = new Gson().toJson(signallingData);
        V2TIMManager.getSignalingManager().reject(id, json, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "rejectInvitation error " + i);
                TUICallback.onError(callback, i, s);
            }

            @Override
            public void onSuccess() {
                TUICallback.onSuccess(callback);
            }
        });
    }

    public void cancelInvitation(String id, final TUICallback callback) {
        TRTCLogger.i(TAG, "cancelInvitation " + id);
        SignallingData signallingData = createSignallingData();
        String json = new Gson().toJson(signallingData);
        V2TIMManager.getSignalingManager().cancel(id, json, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "cancelInvitation error " + i);
                TUICallback.onError(callback, i, s);
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "cancelInvitation success ");
                TUICallback.onSuccess(callback);
            }
        });
    }

    public void getAudienceList(final TUIValueCallback<List<UserInfo>> userListCallback) {
        V2TIMManager.getGroupManager().getGroupMemberList(mRoomId,
                V2TIMGroupMemberFullInfo.V2TIM_GROUP_MEMBER_FILTER_COMMON, 0,
                new V2TIMValueCallback<V2TIMGroupMemberInfoResult>() {
                    @Override
                    public void onError(int i, String s) {
                        TUIValueCallback.onError(userListCallback, i, s);
                    }

                    @Override
                    public void onSuccess(V2TIMGroupMemberInfoResult v2TIMGroupMemberInfoResult) {
                        List<UserInfo> userList = new ArrayList<>();
                        if (v2TIMGroupMemberInfoResult.getMemberInfoList() != null) {
                            for (V2TIMGroupMemberFullInfo info : v2TIMGroupMemberInfoResult.getMemberInfoList()) {
                                UserInfo userInfo = new UserInfo();
                                userInfo.userId = info.getUserID();
                                userInfo.userName = info.getNickName();
                                userInfo.avatarURL = info.getFaceUrl();
                                userList.add(userInfo);
                            }
                        }
                        TUIValueCallback.onSuccess(userListCallback, userList);
                    }
                });
    }

    private class KtvRoomSimpleListener extends V2TIMSimpleMsgListener {
        @Override
        public void onRecvGroupTextMessage(String msgID, String groupID, V2TIMGroupMemberInfo sender, String text) {
            TRTCLogger.i(TAG, "im get text msg group:" + groupID + " userid :" + sender.getUserID()
                    + " text:" + text);
            if (!groupID.equals(mRoomId)) {
                return;
            }
            TRTCKaraokeRoomDef.UserInfo userInfo = new TRTCKaraokeRoomDef.UserInfo();
            userInfo.userId = sender.getUserID();
            userInfo.avatarURL = sender.getFaceUrl();
            userInfo.userName = sender.getNickName();
            if (mDelegate != null) {
                mDelegate.onRoomRecvRoomTextMsg(mRoomId, text, userInfo);
            }
        }

        @Override
        public void onRecvGroupCustomMessage(String msgID, String groupID, V2TIMGroupMemberInfo sender,
                                             byte[] customData) {
            if (!groupID.equals(mRoomId)) {
                return;
            }
            String customStr = new String(customData);
            if (!TextUtils.isEmpty(customStr)) {
                // 一定会有自定义消息的头
                try {
                    JSONObject jsonObject = new JSONObject(customStr);
                    String version = jsonObject.getString(IMProtocol.Define.KEY_ATTR_VERSION);
                    if (!version.equals(IMProtocol.Define.VALUE_ATTR_VERSION)) {
                        TRTCLogger.e(TAG, "protocol version is not match, ignore msg.");
                    }
                    int action = jsonObject.getInt(IMProtocol.Define.KEY_CMD_ACTION);

                    switch (action) {
                        case IMProtocol.Define.CODE_UNKNOWN:
                            // ignore
                            break;
                        case IMProtocol.Define.CODE_ROOM_CUSTOM_MSG:
                            TRTCKaraokeRoomDef.UserInfo userInfo = new TRTCKaraokeRoomDef.UserInfo();
                            userInfo.userId = sender.getUserID();
                            userInfo.avatarURL = sender.getFaceUrl();
                            userInfo.userName = sender.getNickName();
                            Pair<String, String> cusPair = IMProtocol.parseCusMsg(jsonObject);
                            if (mDelegate != null && cusPair != null) {
                                mDelegate.onRoomRecvRoomCustomMsg(mRoomId, cusPair.first, cusPair.second, userInfo);
                            }
                            break;
                        case IMProtocol.Define.CODE_ROOM_DESTROY:
                            exitRoom(null);
                            if (mDelegate != null) {
                                mDelegate.onRoomDestroy(mRoomId);
                            }
                            resetStatus();
                            break;
                        default:
                            break;
                    }
                } catch (JSONException e) {
                    // ignore 无需关注的消息
                }
            }
        }
    }


    private class KtvRoomGroupListener extends V2TIMGroupListener {
        @Override
        public void onMemberEnter(String groupID, List<V2TIMGroupMemberInfo> memberList) {
            if (!groupID.equals(mRoomId)) {
                return;
            }
            if (mDelegate != null && memberList != null) {
                for (V2TIMGroupMemberInfo member : memberList) {
                    TRTCKaraokeRoomDef.UserInfo userInfo = new TRTCKaraokeRoomDef.UserInfo();
                    userInfo.userId = member.getUserID();
                    userInfo.userName = member.getNickName();
                    userInfo.avatarURL = member.getFaceUrl();
                    mDelegate.onRoomAudienceEnter(userInfo);
                }
            }
        }

        @Override
        public void onMemberLeave(String groupID, V2TIMGroupMemberInfo member) {
            if (!groupID.equals(mRoomId)) {
                return;
            }
            if (mDelegate != null) {
                TRTCKaraokeRoomDef.UserInfo userInfo = new TRTCKaraokeRoomDef.UserInfo();
                userInfo.userId = member.getUserID();
                userInfo.userName = member.getNickName();
                userInfo.avatarURL = member.getFaceUrl();
                mDelegate.onRoomAudienceLeave(userInfo);
            }
        }

        @Override
        public void onGroupDismissed(String groupID, V2TIMGroupMemberInfo opUser) {
            // 解散逻辑
            if (!groupID.equals(mRoomId)) {
                return;
            }
            if (mDelegate != null) {
                mDelegate.onRoomDestroy(mRoomId);
            }
            resetStatus();
        }

        @Override
        public void onGroupAttributeChanged(String groupID, Map<String, String> groupAttributeMap) {
            TRTCLogger.i(TAG, "onGroupAttributeChanged :" + groupAttributeMap);
            if (!groupID.equals(mRoomId)) {
                return;
            }
            if (mRoomInfo == null) {
                TRTCLogger.e(TAG, "group attr changed, but room info is empty!");
                return;
            }
            onSeatAttrMapChanged(groupAttributeMap, mRoomInfo.seatSize);
        }
    }


    private class KtvRoomSignalListener extends V2TIMSignalingListener {
        @Override
        public void onReceiveNewInvitation(String inviteID, String inviter, String groupId, List<String> inviteeList,
                                           String data) {
            TRTCLogger.i(TAG, "recv new invitation: " + inviteID + " from " + inviter + " data:" + data);
            if (mDelegate != null) {
                SignallingData signallingData = IMProtocol.convert2SignallingData(data);
                if (!isKtvRoomData(signallingData)) {
                    TRTCLogger.d(TAG, "this is not the voice room sense ");
                    return;
                }
                SignallingData.DataInfo dataInfo = signallingData.getData();
                if (dataInfo == null) {
                    TRTCLogger.e(TAG, "parse data error, dataInfo is null");
                    return;
                }
                if (!mRoomId.equals(String.valueOf(dataInfo.getRoomID()))) {
                    TRTCLogger.e(TAG, "roomId is not right");
                    return;
                }
                mDelegate.onReceiveNewInvitation(inviteID, inviter, dataInfo.getCmd(), dataInfo.getSeatNumber());
            }
        }

        @Override
        public void onInviteeAccepted(String inviteID, String invitee, String data) {
            TRTCLogger.i(TAG, "recv accept invitation: " + inviteID + " from " + invitee);
            SignallingData signallingData = IMProtocol.convert2SignallingData(data);
            if (!isKtvRoomData(signallingData)) {
                TRTCLogger.d(TAG, "this is not the voice room sense ");
                return;
            }
            if (mDelegate != null) {
                mDelegate.onInviteeAccepted(inviteID, invitee);
            }
        }

        @Override
        public void onInviteeRejected(String inviteID, String invitee, String data) {
            TRTCLogger.i(TAG, "recv reject invitation: " + inviteID + " from " + invitee);
            SignallingData signallingData = IMProtocol.convert2SignallingData(data);
            if (!isKtvRoomData(signallingData)) {
                TRTCLogger.d(TAG, "this is not the voice room sense ");
                return;
            }
            if (mDelegate != null) {
                mDelegate.onInviteeRejected(inviteID, invitee);
            }
        }

        @Override
        public void onInvitationCancelled(String inviteID, String inviter, String data) {
            TRTCLogger.i(TAG, "recv cancel invitation: " + inviteID + " from " + inviter);
            SignallingData signallingData = IMProtocol.convert2SignallingData(data);
            if (isKtvRoomData(signallingData)) {
                TRTCLogger.d(TAG, "this is not the voice room sense ");
                return;
            }
            if (mDelegate != null) {
                mDelegate.onInvitationCancelled(inviteID, inviter);
            }
        }

        @Override
        public void onInvitationTimeout(String inviteID, List<String> inviteeList) {
        }
    }

    private boolean isKtvRoomData(SignallingData signallingData) {
        if (signallingData == null) {
            return false;
        }
        String businessId = signallingData.getBusinessID();
        return IMProtocol.SignallingDefine.VALUE_BUSINESS_ID.equals(businessId);
    }

    private SignallingData createSignallingData() {
        SignallingData callingData = new SignallingData();
        callingData.setVersion(IMProtocol.SignallingDefine.VALUE_VERSION);
        callingData.setBusinessID(IMProtocol.SignallingDefine.VALUE_BUSINESS_ID);
        callingData.setPlatform(IMProtocol.SignallingDefine.VALUE_PLATFORM);
        SignallingData.DataInfo dataInfo = new SignallingData.DataInfo();
        callingData.setData(dataInfo);
        return callingData;
    }
}

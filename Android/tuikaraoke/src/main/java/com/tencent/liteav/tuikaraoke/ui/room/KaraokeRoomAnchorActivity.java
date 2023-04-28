package com.tencent.liteav.tuikaraoke.ui.room;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.model.impl.server.TRTCKaraokeRoomManager;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;
import com.tencent.liteav.tuikaraoke.ui.base.MemberEntity;
import com.tencent.liteav.tuikaraoke.ui.utils.Constants;
import com.tencent.liteav.tuikaraoke.ui.utils.PermissionHelper;
import com.tencent.liteav.tuikaraoke.ui.utils.Toast;
import com.tencent.liteav.tuikaraoke.ui.widget.CommonBottomDialog;
import com.tencent.liteav.tuikaraoke.ui.widget.ConfirmDialogFragment;
import com.tencent.liteav.tuikaraoke.ui.widget.msg.MsgEntity;
import com.tencent.qcloud.tuicore.TUILogin;
import com.tencent.qcloud.tuicore.interfaces.TUICallback;
import com.tencent.qcloud.tuicore.interfaces.TUILoginListener;
import com.tencent.trtc.TRTCCloudDef;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

public class KaraokeRoomAnchorActivity extends KaraokeRoomBaseActivity {
    public static final int ERROR_ROOM_ID_EXIT = -1301;

    private Map<String, String> mTakeSeatInvitationMap;
    private boolean             mIsEnterRoom;
    private boolean             mIsTakeSeat;

    /**
     * 创建房间
     */
    public static void createKaraokeRoom(Context context, String roomName, String userId,
                                         String userName, String coverUrl, int audioQuality, boolean needRequest) {
        Intent intent = new Intent(context, KaraokeRoomAnchorActivity.class);
        intent.putExtra(KTVROOM_ROOM_NAME, roomName);
        intent.putExtra(KTVROOM_USER_ID, userId);
        intent.putExtra(KTVROOM_USER_NAME, userName);
        intent.putExtra(KTVROOM_ROOM_COVER, coverUrl);
        intent.putExtra(KTVROOM_NEED_REQUEST, needRequest);
        context.startActivity(intent);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestPermission();
    }

    @Override
    protected void checkingBeforeExitRoom() {
        super.checkingBeforeExitRoom();
        if (mIsEnterRoom) {
            showExitRoom();
        } else {
            finish();
        }
    }

    private void showExitRoom() {
        if (mConfirmDialogFragment == null) {
            mConfirmDialogFragment = new ConfirmDialogFragment();
        }

        if (mConfirmDialogFragment.isAdded()) {
            mConfirmDialogFragment.dismiss();
        }
        mConfirmDialogFragment.setMessage(getString(R.string.trtckaraoke_anchor_leave_room));
        mConfirmDialogFragment.setNegativeClickListener(new ConfirmDialogFragment.NegativeClickListener() {
            @Override
            public void onClick() {
                mConfirmDialogFragment.dismiss();
            }
        });
        mConfirmDialogFragment.setPositiveClickListener(new ConfirmDialogFragment.PositiveClickListener() {
            @Override
            public void onClick() {
                mConfirmDialogFragment.dismiss();
                destroyRoom();
            }
        });
        mConfirmDialogFragment.show(getFragmentManager(), "confirm_fragment");
    }

    private void destroyRoom() {
        if (mKaraokeMusicService != null) {
            mKaraokeMusicService.clearPlaylistByUserId(mSelfUserId, null);
            mKaraokeMusicService.destroyService();
        }
        mTRTCKaraokeRoom.exitRoom(new TUICallback() {
            @Override
            public void onSuccess() {
                mTRTCKaraokeRoom.destroyRoom(null);
            }

            @Override
            public void onError(int errorCode, String errorMessage) {
                TRTCLogger.d(TAG, "exit room failed:" + errorMessage);
            }
        });
        TRTCKaraokeRoomManager.getInstance().destroyRoom(mRoomId, new TRTCKaraokeRoomManager.ActionCallback() {
            @Override
            public void onSuccess() {
                TRTCLogger.d(TAG, "destroy room success");
            }

            @Override
            public void onError(int errorCode, String message) {
                TRTCLogger.d(TAG, "destroy room failed:" + message);
            }
        });
        TUILogin.removeLoginListener(mTUILoginListener);
        finish();
    }

    /**
     * 主播的逻辑
     */
    private void requestPermission() {
        PermissionHelper.requestPermission(this, PermissionHelper.PERMISSION_MICROPHONE,
                new PermissionHelper.PermissionCallback() {
                    @Override
                    public void onGranted() {
                        mRoomInfoController.setRoomOwnerId(mSelfUserId);
                        mTakeSeatInvitationMap = new HashMap<>();
                        mKaraokeRoomSeatAdapter.notifyDataSetChanged();
                        mRoomId = getRoomId();
                        createAndEnterRoom();
                        showAlertUserLiveTips();
                    }

                    @Override
                    public void onDenied() {
                        finish();
                    }
                });
    }

    private void createAndEnterRoom() {
        TRTCKaraokeRoomDef.RoomParam roomParam = new TRTCKaraokeRoomDef.RoomParam();
        roomParam.roomName = mRoomName;
        roomParam.needRequest = mNeedRequest;
        roomParam.seatCount = MAX_SEAT_SIZE;
        roomParam.coverUrl = mRoomCover;

        TRTCKaraokeRoomDef.RoomInfo roomInfo = new TRTCKaraokeRoomDef.RoomInfo();
        roomInfo.roomId = String.valueOf(mRoomId);
        roomInfo.ownerId = mSelfUserId;
        roomInfo.roomName = mRoomName;
        createKTVMusicService(roomInfo);

        mTRTCKaraokeRoom.createRoom(mRoomId, roomParam, new TUICallback() {
            @Override
            public void onError(int errorCode, String errorMessage) {
                String info = "create room failed[" + errorCode + "]:" + errorMessage;
                TRTCLogger.e(TAG, info);
            }

            @Override
            public void onSuccess() {
                mTRTCKaraokeRoom.enterRoom(mRoomId, new TUICallback() {
                    @Override
                    public void onError(int errorCode, String errorMessage) {
                        String info = "enter room failed[" + errorCode + "]:" + errorMessage;
                        Toast.show(info, Toast.LENGTH_LONG);
                        TRTCLogger.e(TAG, info);
                        finish();
                    }

                    @Override
                    public void onSuccess() {
                        //房主占座1号麦位
                        enterSeat(0);

                        mTRTCKaraokeRoom.updateNetworkTime();
                        mIsEnterRoom = true;
                        mTvRoomName.setText(mRoomName);
                        mTvRoomId.setText(getString(R.string.trtckaraoke_room_id, String.valueOf(mRoomId)));

                        TRTCKaraokeRoomManager.getInstance().createRoom(mRoomId,
                                new TRTCKaraokeRoomManager.ActionCallback() {
                            @Override
                            public void onSuccess() {
                                TRTCLogger.d(TAG, "create karaoke room success");
                            }

                            @Override
                            public void onError(int errorCode, String message) {
                                if (errorCode == ERROR_ROOM_ID_EXIT) {
                                    onSuccess();
                                } else {
                                    Toast.show(
                                            "create karaoke room failed[" + errorCode + "]:" + message,
                                            Toast.LENGTH_LONG);
                                    finish();
                                }
                            }
                        });
                    }
                });
            }
        });
        // 刷新界面
        refreshView();

        TUILogin.addLoginListener(mTUILoginListener);
    }

    private int getRoomId() {
        // 这里我们用简单的 userId hashcode，然后取余
        // 您的room id应该是您后台生成的唯一值
        return (mSelfUserId + "_karaoke_room").hashCode() & 0x7FFFFFFF;
    }

    /**
     * 房主点击座位列表
     *
     * @param itemPos
     */
    @Override
    public void onItemClick(final int itemPos) {
        // 判断座位有没有人
        KaraokeRoomSeatEntity entity = mKaraokeRoomSeatEntityList.get(itemPos);
        if (entity.isUsed) {
            if (entity.userId.equals(mSelfUserId)) {
                // 房主自己是该位主播,则主动下麦
                leaveSeat();
            } else {
                // 其他主播,弹出禁言/踢人
                final boolean isMute = entity.isSeatMute;
                final CommonBottomDialog dialog = new CommonBottomDialog(this);
                dialog.setButton(new CommonBottomDialog.OnButtonClickListener() {
                    @Override
                    public void onClick(int position, String text) {
                        dialog.dismiss();
                        if (position == 0) {
                            mTRTCKaraokeRoom.muteSeat(changeSeatIndexToModelIndex(itemPos), !isMute, null);
                        } else {
                            mTRTCKaraokeRoom.kickSeat(changeSeatIndexToModelIndex(itemPos), null);
                        }
                    }
                }, isMute ? getString(R.string.trtckaraoke_seat_unmuted) : getString(R.string.trtckaraoke_seat_mute),
                        getString(R.string.trtckaraoke_leave_seat));
                dialog.show();
            }
        } else {
            final CommonBottomDialog dialog = new CommonBottomDialog(this);
            final boolean isClose = entity.isClose;
            String[] textList1 = new String[1];
            String[] textList2 = new String[2];
            if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
                textList1[0] = isClose ? getString(R.string.trtckaraoke_unlock) : getString(R.string.trtckaraoke_lock);
            } else {
                textList2[0] = getString(R.string.trtckaraoke_online);
                textList2[1] = isClose ? getString(R.string.trtckaraoke_unlock) : getString(R.string.trtckaraoke_lock);
            }
            dialog.setButton(new CommonBottomDialog.OnButtonClickListener() {
                @Override
                public void onClick(int position, String text) {
                    dialog.dismiss();
                    if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
                        //锁定座位
                        mTRTCKaraokeRoom.closeSeat(changeSeatIndexToModelIndex(itemPos), !isClose, null);
                    } else {
                        if (position == 0) {
                            if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
                                Toast.show(R.string.trtckaraoke_toast_you_are_already_an_anchor,
                                        Toast.LENGTH_LONG);
                                return;
                            }
                            //断网后多次占座,重新联网后只执行第一次,后续不在执行
                            if (mIsTakeSeat) {
                                return;
                            }
                            mIsTakeSeat = true;
                            enterSeat(itemPos);
                        } else {
                            //锁定座位
                            mTRTCKaraokeRoom.closeSeat(changeSeatIndexToModelIndex(itemPos), !isClose, null);
                        }
                    }

                }
            }, (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) ? textList1 : textList2);
            dialog.show();
        }

    }

    private void enterSeat(final int itemPos) {
        PermissionHelper.requestPermission(this, PermissionHelper.PERMISSION_MICROPHONE,
                new PermissionHelper.PermissionCallback() {
                    @Override
                    public void onGranted() {
                        int seatIndex = changeSeatIndexToModelIndex(itemPos);
                        mTRTCKaraokeRoom.enterSeat(seatIndex, new TUICallback() {
                            @Override
                            public void onSuccess() {
                                //成功上座位，可以展示UI了
                                Toast.show(R.string.trtckaraoke_toast_owner_succeeded_in_occupying_the_seat,
                                        Toast.LENGTH_LONG);
                                mIsTakeSeat = false;
                            }

                            @Override
                            public void onError(int code, String msg) {
                                String info = String.format(getString(
                                        R.string.trtckaraoke_toast_owner_failed_to_occupy_the_seat), code, msg);
                                Toast.show(info, Toast.LENGTH_LONG);
                                mIsTakeSeat = false;
                            }
                        });
                    }

                    @Override
                    public void onDenied() {

                    }
                });
    }

    @Override
    public void onAudienceEnter(TRTCKaraokeRoomDef.UserInfo userInfo) {
        super.onAudienceEnter(userInfo);
        if (userInfo.userId.equals(mSelfUserId)) {
            return;
        }
        MemberEntity memberEntity = new MemberEntity();
        memberEntity.userId = userInfo.userId;
        memberEntity.avatarURL = userInfo.avatarURL;
        memberEntity.userName = userInfo.userName;
        memberEntity.type = MemberEntity.TYPE_IDEL;
        if (!mMemberEntityMap.containsKey(memberEntity.userId)) {
            mMemberEntityMap.put(memberEntity.userId, memberEntity);
        }
    }

    @Override
    public void onAudienceExit(TRTCKaraokeRoomDef.UserInfo userInfo) {
        super.onAudienceExit(userInfo);
        mMemberEntityMap.remove(userInfo.userId);
    }

    @Override
    public void onAnchorEnterSeat(int index, TRTCKaraokeRoomDef.UserInfo user) {
        super.onAnchorEnterSeat(index, user);
        MemberEntity entity = mMemberEntityMap.get(user.userId);
        if (entity != null) {
            entity.type = MemberEntity.TYPE_IN_SEAT;
        }
    }

    @Override
    public void onAnchorLeaveSeat(int index, TRTCKaraokeRoomDef.UserInfo user) {
        super.onAnchorLeaveSeat(index, user);
        MemberEntity entity = mMemberEntityMap.get(user.userId);
        if (entity != null) {
            entity.type = MemberEntity.TYPE_IDEL;
        }
    }

    @Override
    public void onAgreeClick(int position) {
        super.onAgreeClick(position);
        if (mMsgEntityList != null) {
            final MsgEntity entity = mMsgEntityList.get(position);
            String inviteId = entity.invitedId;
            if (inviteId == null) {
                Toast.show(getString(R.string.trtckaraoke_request_expired), Toast.LENGTH_LONG);
                return;
            }
            mTRTCKaraokeRoom.acceptInvitation(inviteId, new TUICallback() {
                @Override
                public void onSuccess() {
                    entity.type = MsgEntity.TYPE_AGREED;
                    mMsgListAdapter.notifyDataSetChanged();
                }

                @Override
                public void onError(int errorCode, String errorMessage) {
                    Toast.show(getString(R.string.trtckaraoke_accept_failed) + errorCode, Toast.LENGTH_LONG);
                }
            });
        }
    }

    @Override
    public void onReceiveNewInvitation(String id, String inviter, String cmd, String content) {
        super.onReceiveNewInvitation(id, inviter, cmd, content);
        if (cmd.equals(Constants.CMD_REQUEST_TAKE_SEAT)) {
            recvTakeSeat(id, inviter, content);
        }
    }

    private void recvTakeSeat(String inviteId, String inviter, String content) {
        //收到了观众的申请上麦消息，显示到通知栏
        MemberEntity memberEntity = mMemberEntityMap.get(inviter);
        MsgEntity msgEntity = new MsgEntity();
        msgEntity.userId = inviter;
        msgEntity.invitedId = inviteId;
        msgEntity.userName = (memberEntity != null ? memberEntity.userName : inviter);
        msgEntity.type = MsgEntity.TYPE_WAIT_AGREE;
        int seatIndex = Integer.parseInt(content);
        msgEntity.content = getString(R.string.trtckaraoke_msg_apply_for_chat, seatIndex + 1);
        if (memberEntity != null) {
            memberEntity.type = MemberEntity.TYPE_WAIT_AGREE;
        }
        mTakeSeatInvitationMap.put(inviter, inviteId);
        showImMsg(msgEntity);
    }

    @Override
    public void onOrderedManagerClick(int position) {
        super.onOrderedManagerClick(position);
        if (mMsgEntityList != null) {
            final MsgEntity entity = mMsgEntityList.get(position);
            String inviteId = entity.invitedId;
            if (inviteId == null) {
                Toast.show(getString(R.string.trtckaraoke_request_expired), Toast.LENGTH_LONG);
                return;
            }
            //主播点歌后,房主在消息中拉起点歌/已点面板
            mKTVMusicView.showMusicDialog(true);
        }
    }

    private void showAlertUserLiveTips() {
        if (!isFinishing()) {
            try {
                Class clz = Class.forName("com.tencent.liteav.privacy.util.RTCubeAppLegalUtils");
                Method method = clz.getDeclaredMethod("showAlertUserLiveTips", Context.class);
                method.invoke(null, this);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void onRoomDestroy(String roomId) {
        Log.e(TAG, "onRoomDestroy");
        destroyRoom();
        if (!isFinishing()) {
            showDestroyDialog();
        }
    }

    private void showDestroyDialog() {
        try {
            Class clz = Class.forName("com.tencent.liteav.privacy.util.RTCubeAppLegalUtils");
            Method method = clz.getDeclaredMethod("showRoomDestroyTips", Context.class);
            method.invoke(null, this);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private TUILoginListener mTUILoginListener = new TUILoginListener() {
        @Override
        public void onKickedOffline() {
            Log.e(TAG, "onKickedOffline");
            destroyRoom();
        }
    };
}

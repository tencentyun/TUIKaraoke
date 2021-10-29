package com.tencent.liteav.tuikaraoke.ui.room;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.blankj.utilcode.constant.PermissionConstants;
import com.blankj.utilcode.util.PermissionUtils;
import com.blankj.utilcode.util.ToastUtils;
import com.tencent.liteav.basic.UserModel;
import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomCallback;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomManager;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;
import com.tencent.liteav.tuikaraoke.ui.base.MemberEntity;
import com.tencent.liteav.tuikaraoke.ui.music.impl.KaraokeMusicView;
import com.tencent.liteav.tuikaraoke.ui.widget.CommonBottomDialog;
import com.tencent.liteav.tuikaraoke.ui.widget.ConfirmDialogFragment;
import com.tencent.liteav.tuikaraoke.ui.widget.msg.MsgEntity;
import com.tencent.trtc.TRTCCloudDef;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class KaraokeRoomAnchorActivity extends KaraokeRoomBaseActivity {
    public static final int ERROR_ROOM_ID_EXIT = -1301;

    // 用户消息的map
    private Map<String, String> mTakeSeatInvitationMap;
    private boolean             mIsEnterRoom;
    private boolean             mIsTakeSeat;

    /**
     * 创建房间
     */
    public static void createRoom(Context context, String roomName, String userId,
                                  String userName, String coverUrl, int audioQuality, boolean needRequest) {
        Intent intent = new Intent(context, KaraokeRoomAnchorActivity.class);
        intent.putExtra(KTVROOM_ROOM_NAME, roomName);
        intent.putExtra(KTVROOM_USER_ID, userId);
        intent.putExtra(KTVROOM_USER_NAME, userName);
        intent.putExtra(KTVROOM_AUDIO_QUALITY, audioQuality);
        intent.putExtra(KTVROOM_ROOM_COVER, coverUrl);
        intent.putExtra(KTVROOM_NEED_REQUEST, needRequest);
        context.startActivity(intent);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initAnchor();
    }

    @Override
    public void onBackPressed() {
        if (mIsEnterRoom) {
            showExitRoom();
        } else {
            finish();
        }
    }

    private void showExitRoom() {
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
                finish();
            }
        });
        mConfirmDialogFragment.show(getFragmentManager(), "confirm_fragment");
    }

    private void destroyRoom() {
        mTRTCKaraokeRoom.destroyRoom(new TRTCKaraokeRoomCallback.ActionCallback() {
            @Override
            public void onCallback(int code, String msg) {
                if (code == 0) {
                    TRTCLogger.d(TAG, "IM destroy room success");
                } else {
                    TRTCLogger.d(TAG, "IM destroy room failed:" + msg);
                }
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
        mTRTCKaraokeRoom.setDelegate(null);
    }

    /**
     * 主播的逻辑
     */
    private void initAnchor() {
        mRoomInfoController.setRoomOwnerId(mSelfUserId);
        mTakeSeatInvitationMap = new HashMap<>();
        mKaraokeRoomSeatAdapter.notifyDataSetChanged();

        mRoomId = getRoomId();
        //设置昵称、头像
        mTRTCKaraokeRoom.setSelfProfile(mUserName, mUserAvatar, null);
        PermissionUtils.permission(PermissionConstants.MICROPHONE).callback(new PermissionUtils.FullCallback() {
            @Override
            public void onGranted(List<String> permissionsGranted) {
                internalCreateRoom();
            }

            @Override
            public void onDenied(List<String> permissionsDeniedForever, List<String> permissionsDenied) {
                ToastUtils.showShort(R.string.trtckaraoke_tips_open_audio);
            }
        }).request();
    }

    private void internalCreateRoom() {
        final TRTCKaraokeRoomDef.RoomParam roomParam = new TRTCKaraokeRoomDef.RoomParam();
        roomParam.roomName = mRoomName;
        roomParam.needRequest = mNeedRequest;
        roomParam.seatCount = MAX_SEAT_SIZE;
        roomParam.coverUrl = mRoomCover;

        TRTCKaraokeRoomDef.RoomInfo roomInfo = new TRTCKaraokeRoomDef.RoomInfo();
        roomInfo.roomId = mRoomId;
        roomInfo.ownerId = mSelfUserId;
        roomInfo.roomName = mRoomName;
        mKaraokeMusicService.setRoomInfo(roomInfo);

        mTRTCKaraokeRoom.createRoom(mRoomId, roomParam, new TRTCKaraokeRoomCallback.ActionCallback() {
            @Override
            public void onCallback(int code, String msg) {
                if (code == 0) {
                    onTRTCRoomCreateSuccess();
                }
            }
        });
        //房间创建完成后
        ktvMusicImplComplete();
        // 刷新界面
        refreshView();
        mKTVMusicView.setMsgListener(new KaraokeMusicView.KTVMusicMsgDelegate() {
            @Override
            public void sendOrderMsg(KaraokeMusicInfo model) {
                updateMsg(model);
            }
        });
    }

    private void onTRTCRoomCreateSuccess() {
        Log.d(TAG, "*********** Congratulations! You have completed Lab Experiment！***********");
        mIsEnterRoom = true;
        mTvRoomName.setText(mRoomName);
        mTvRoomId.setText(getString(R.string.trtckaraoke_room_id, mRoomId));
        mTRTCKaraokeRoom.setAudioQuality(mAudioQuality);

        TRTCKaraokeRoomManager.getInstance().createRoom(mRoomId, new TRTCKaraokeRoomManager.ActionCallback() {
            @Override
            public void onSuccess() {
                TRTCLogger.d(TAG, "create room success");
            }

            @Override
            public void onError(int errorCode, String message) {
                if (errorCode == ERROR_ROOM_ID_EXIT) {
                    onSuccess();
                } else {
                    ToastUtils.showLong("create room failed[" + errorCode + "]:" + message);
                    finish();
                }
            }
        });
    }

    private int getRoomId() {
        // 这里我们用简单的 userId hashcode，然后取余
        // 您的room id应该是您后台生成的唯一值
        return (mSelfUserId + "_voice_room").hashCode() & 0x7FFFFFFF;
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
                final boolean            isMute = entity.isSeatMute;
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
                }, isMute ? getString(R.string.trtckaraoke_seat_unmuted) : getString(R.string.trtckaraoke_seat_mute), getString(R.string.trtckaraoke_leave_seat));
                dialog.show();
            }
        } else {
            final CommonBottomDialog dialog    = new CommonBottomDialog(this);
            final boolean            isClose   = entity.isClose;
            String[]                 textList1 = new String[1];
            String[]                 textList2 = new String[2];
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
                        mTRTCKaraokeRoom.closeSeat(changeSeatIndexToModelIndex(itemPos), !isClose, new TRTCKaraokeRoomCallback.ActionCallback() {
                            @Override
                            public void onCallback(int code, String msg) {
                                if (code == 0) {
                                    TRTCLogger.d(TAG, "");
                                }
                            }
                        });
                    } else {
                        if (position == 0) {
                            if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
                                ToastUtils.showShort(R.string.trtckaraoke_toast_you_are_already_an_anchor);
                                return;
                            }
                            //断网后多次占座,重新联网后只执行第一次,后续不在执行
                            if (mIsTakeSeat) {
                                return;
                            }
                            mIsTakeSeat = true;
                            mTRTCKaraokeRoom.enterSeat(changeSeatIndexToModelIndex(itemPos), new TRTCKaraokeRoomCallback.ActionCallback() {
                                @Override
                                public void onCallback(int code, String msg) {
                                    if (code == 0) {
                                        //成功上座位，可以展示UI了
                                        ToastUtils.showLong(getString(R.string.trtckaraoke_toast_owner_succeeded_in_occupying_the_seat));
                                    } else {
                                        ToastUtils.showLong(getString(R.string.trtckaraoke_toast_owner_failed_to_occupy_the_seat), code, msg);
                                    }
                                    mIsTakeSeat = false;
                                }
                            });
                        } else {
                            //锁定座位
                            mTRTCKaraokeRoom.closeSeat(changeSeatIndexToModelIndex(itemPos), !isClose, new TRTCKaraokeRoomCallback.ActionCallback() {
                                @Override
                                public void onCallback(int code, String msg) {
                                    if (code == 0) {
                                        TRTCLogger.d(TAG, "");
                                    }
                                }
                            });
                        }
                    }

                }
            }, (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) ? textList1 : textList2);
            dialog.show();
        }

    }

    @Override
    public void onAudienceEnter(TRTCKaraokeRoomDef.UserInfo userInfo) {
        super.onAudienceEnter(userInfo);
        if (userInfo.userId.equals(mSelfUserId)) {
            return;
        }
        MemberEntity memberEntity = new MemberEntity();
        memberEntity.userId = userInfo.userId;
        memberEntity.userAvatar = userInfo.userAvatar;
        memberEntity.userName = userInfo.userName;
        memberEntity.type = MemberEntity.TYPE_IDEL;
        if (!mMemberEntityMap.containsKey(memberEntity.userId)) {
            mMemberEntityMap.put(memberEntity.userId, memberEntity);
            mMemberEntityList.add(memberEntity);
        }
    }

    @Override
    public void onAudienceExit(TRTCKaraokeRoomDef.UserInfo userInfo) {
        super.onAudienceExit(userInfo);
        MemberEntity entity = mMemberEntityMap.remove(userInfo.userId);
        if (entity != null) {
            mMemberEntityList.remove(entity);
        }
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
            final MsgEntity entity   = mMsgEntityList.get(position);
            String          inviteId = entity.invitedId;
            if (inviteId == null) {
                ToastUtils.showLong(getString(R.string.trtckaraoke_request_expired));
                return;
            }
            mTRTCKaraokeRoom.acceptInvitation(inviteId, new TRTCKaraokeRoomCallback.ActionCallback() {
                @Override
                public void onCallback(int code, String msg) {
                    if (code == 0) {
                        entity.type = MsgEntity.TYPE_AGREED;
                        mMsgListAdapter.notifyDataSetChanged();
                    } else {
                        ToastUtils.showShort(getString(R.string.trtckaraoke_accept_failed) + code);
                    }
                }
            });
        }
    }

    @Override
    public void onReceiveNewInvitation(String id, String inviter, String cmd, String content) {
        super.onReceiveNewInvitation(id, inviter, cmd, content);
        if (cmd.equals(TCConstants.CMD_REQUEST_TAKE_SEAT)) {
            recvTakeSeat(id, inviter, content);
        }
    }

    private void recvTakeSeat(String inviteId, String inviter, String content) {
        //收到了观众的申请上麦消息，显示到通知栏
        MemberEntity memberEntity = mMemberEntityMap.get(inviter);
        MsgEntity    msgEntity    = new MsgEntity();
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

    private void updateMsg(KaraokeMusicInfo entity) {
        if (entity == null || entity.musicId == null || entity.userId == null) {
            Log.d(TAG, "updateMsg: the entity is not ready");
            return;
        }
        MsgEntity msgEntity = new MsgEntity();
        msgEntity.invitedId = TCConstants.CMD_ORDER_SONG;
        msgEntity.type = MsgEntity.TYPE_ORDERED_SONG;

        int    seatIndex = 0;
        String userName  = null;
        for (int i = 0; i < mKaraokeRoomSeatEntityList.size(); i++) {
            KaraokeRoomSeatEntity temp = mKaraokeRoomSeatEntityList.get(i);
            if (temp == null || temp.userId == null || temp.userName == null) {
                continue;
            }
            if (entity.userId.equals(temp.userId)) {
                seatIndex = i;
                userName = mKaraokeRoomSeatEntityList.get(i).userName;
                break;
            }
        }
        msgEntity.userName = userName;
        msgEntity.content = getString(R.string.trtckaraoke_msg_order_song_seat, seatIndex + 1);
        msgEntity.linkUrl = getString(R.string.trtckaraoke_msg_order_song, entity.musicName);
        showImMsg(msgEntity);
    }

    @Override
    public void onOrderedManagerClick(int position) {
        super.onOrderedManagerClick(position);
        if (mMsgEntityList != null) {
            final MsgEntity entity   = mMsgEntityList.get(position);
            String          inviteId = entity.invitedId;
            if (inviteId == null) {
                ToastUtils.showLong(getString(R.string.trtckaraoke_request_expired));
                return;
            }
            //主播点歌后,房主在消息中拉起点歌/已点面板
            mKTVMusicView.showMusicDialog(true);

        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        UserModelManager.getInstance().getUserModel().userType = UserModel.UserType.NONE;
        if (mTUIKaraokeAudioManager != null) {
            mTUIKaraokeAudioManager.reset();
            mTUIKaraokeAudioManager.unInit();
            mTUIKaraokeAudioManager = null;
        }
        if (mKaraokeMusicService != null) {
            mKaraokeMusicService.onExitRoom();
            mKaraokeMusicService = null;
        }
    }
}

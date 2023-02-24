package com.tencent.liteav.tuikaraoke.ui.room;

import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.provider.Settings;
import android.util.Log;
import android.view.View;

import com.blankj.utilcode.util.ToastUtils;
import com.tencent.liteav.basic.RTCubeUtils;
import com.tencent.liteav.basic.UserModel;
import com.tencent.liteav.basic.UserModelManager;

import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomCallback;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;
import com.tencent.liteav.tuikaraoke.ui.floatwindow.FloatActivity;
import com.tencent.liteav.tuikaraoke.ui.floatwindow.FloatWindow;
import com.tencent.liteav.tuikaraoke.ui.floatwindow.PermissionListener;
import com.tencent.liteav.tuikaraoke.ui.utils.PermissionHelper;
import com.tencent.liteav.tuikaraoke.ui.widget.CommonBottomDialog;
import com.tencent.liteav.tuikaraoke.ui.widget.ConfirmDialogFragment;
import com.tencent.qcloud.tuicore.TUILogin;
import com.tencent.qcloud.tuicore.interfaces.TUILoginListener;
import com.tencent.trtc.TRTCCloudDef;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 听众界面
 */
public class KaraokeRoomAudienceActivity extends KaraokeRoomBaseActivity {
    private static final int MSG_DISMISS_LOADING = 1001;

    private        Map<String, Integer>  mInvitationSeatMap;
    private        String                mOwnerId;
    private        boolean               mIsSeatInitSuccess;
    private        int                   mSelfSeatIndex;
    private        ConfirmDialogFragment mAlertDialog;
    private static AudienceRoomEntity    mCollectEntity;
    private static AudienceRoomEntity    mLastEntity;
    private        boolean               mRoomDestroy;
    private        boolean               mIsTakingSeat; //正在进行上麦


    public static void enterRoom(final Context context, final int roomId, final String userId, final int audioQuality) {
        //保存房间信息
        mCollectEntity = new AudienceRoomEntity();
        mCollectEntity.roomId = roomId;
        mCollectEntity.userId = userId;
        mCollectEntity.audioQuality = audioQuality;

        FloatWindow.getInstance().setRoomInfo(mCollectEntity);
        if (mLastEntity != null && mLastEntity.userId.equals(userId)) {
            FloatWindow.getInstance().hide();
        } else {
            if (FloatWindow.mIsShowing) {
                FloatWindow.getInstance().destroy();
            }
        }

        Intent starter = new Intent(context, KaraokeRoomAudienceActivity.class);
        starter.putExtra(KTVROOM_ROOM_ID, roomId);
        starter.putExtra(KTVROOM_USER_ID, userId);
        starter.putExtra(KTVROOM_AUDIO_QUALITY, audioQuality);
        context.startActivity(starter);
    }

    private void enterRoom() {
        mIsSeatInitSuccess = false;
        mSelfSeatIndex = -1;
        mCurrentRole = TRTCCloudDef.TRTCRoleAudience;
        mTRTCKaraokeRoom.setSelfProfile(mUserName, mUserAvatar, null);
        mTRTCKaraokeRoom.enterRoom(mRoomId, new TRTCKaraokeRoomCallback.ActionCallback() {
            @Override
            public void onCallback(int code, String msg) {
                if (code == 0) {
                    //进房成功
                    ToastUtils.showShort(R.string.trtckaraoke_toast_enter_the_room_successfully);
                    mTRTCKaraokeRoom.setAudioQuality(mAudioQuality);
                } else {
                    ToastUtils.showShort(getString(R.string.trtckaraoke_toast_enter_the_room_failure, code, msg));
                    finish();
                }
            }
        });
    }

    private Handler mHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            if (msg.what == MSG_DISMISS_LOADING) {
                mHandler.removeMessages(MSG_DISMISS_LOADING);
                mProgressBar.setVisibility(View.GONE);
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initAudience();
    }

    @Override
    protected void onStop() {
        super.onStop();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        //申请悬浮窗权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            FloatActivity.request(this, new PermissionListener() {
                @Override
                public void onSuccess() {
                    showFloatWindow();
                }

                @Override
                public void onFail() {
                    //没有悬浮窗权限就直接退房,回到房间列表
                    if (mTRTCKaraokeRoom != null) {
                        mTRTCKaraokeRoom.exitRoom(new TRTCKaraokeRoomCallback.ActionCallback() {
                            @Override
                            public void onCallback(int code, String msg) {
                                ToastUtils.showShort(R.string.trtckaraoke_toast_exit_the_room_successfully);
                            }
                        });
                    }
                }
            });
        } else {
            showFloatWindow();
        }
        TUILogin.removeLoginListener(mTUILoginListener);
    }

    private void showFloatWindow() {
        if (mRoomDestroy) {
            mLastEntity = null;
            FloatWindow.getInstance().destroy();
        } else {
            if (mLastEntity != null && mLastEntity.userId.equals(mCollectEntity.userId)
                    && !FloatWindow.mIsDestroyByself) {
                FloatWindow.getInstance().show();
            } else {
                FloatWindow.mIsDestroyByself = false;
                FloatWindow.getInstance().init(getApplicationContext());
                FloatWindow.getInstance().createView();
            }
            mLastEntity = mCollectEntity;
        }
    }

    @Override
    public void onBackPressed() {
        if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
            leaveSeatAndQuit();
        } else {
            super.onBackPressed();
        }
    }

    private void initAudience() {
        mInvitationSeatMap = new HashMap<>();
        mKaraokeRoomSeatAdapter.notifyDataSetChanged();
        // 开始进房
        enterRoom();
        TUILogin.addLoginListener(mTUILoginListener);
        mBtnReport.setVisibility(RTCubeUtils.isRTCubeApp(this) ? View.VISIBLE : View.GONE);
        mBtnReport.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showReportDialog();
            }
        });
    }

    //下麦
    public void leaveSeatAndQuit() {
        if (mAlertDialog == null) {
            mAlertDialog = new ConfirmDialogFragment();
        }
        if (mAlertDialog.isAdded()) {
            mAlertDialog.dismiss();
        }
        mAlertDialog.setMessage(getString(R.string.trtckaraoke_leave_seat_ask));
        mAlertDialog.setPositiveClickListener(new ConfirmDialogFragment.PositiveClickListener() {
            @Override
            public void onClick() {
                mTRTCKaraokeRoom.leaveSeat(new TRTCKaraokeRoomCallback.ActionCallback() {
                    @Override
                    public void onCallback(int code, String msg) {
                        if (code == 0) {
                            ToastUtils.showShort(R.string.trtckaraoke_toast_offline_successfully);
                        } else {
                            ToastUtils.showShort(getString(R.string.trtckaraoke_toast_offline_failure, msg));
                        }
                    }
                });
                mAlertDialog.dismiss();
                finish();
            }
        });
        mAlertDialog.setNegativeClickListener(new ConfirmDialogFragment.NegativeClickListener() {
            @Override
            public void onClick() {
                mAlertDialog.dismiss();
            }
        });
        mAlertDialog.show(this.getFragmentManager(), "confirm_leave_seat");
    }

    @Override
    public void onSeatListChange(List<TRTCKaraokeRoomDef.SeatInfo> seatInfoList) {
        super.onSeatListChange(seatInfoList);
        mIsSeatInitSuccess = true;
    }

    /**
     * 点击麦位列表听众端的操作
     *
     * @param itemPos
     */
    @Override
    public void onItemClick(final int itemPos) {
        if (!mIsSeatInitSuccess) {
            ToastUtils.showLong(R.string.trtckaraoke_toast_list_has_not_been_initialized);
            return;
        }
        // 判断座位有没有人
        KaraokeRoomSeatEntity entity = mKaraokeRoomSeatEntityList.get(itemPos);
        if (entity.isClose) {
            ToastUtils.showShort(R.string.trtckaraoke_toast_position_is_locked_cannot_enter_seat);
        } else if (!entity.isUsed) {
            if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
                ToastUtils.showShort(R.string.trtckaraoke_toast_you_are_already_an_anchor);
                return;
            }
            final CommonBottomDialog dialog = new CommonBottomDialog(this);
            dialog.setButton(new CommonBottomDialog.OnButtonClickListener() {
                @Override
                public void onClick(int position, String text) {
                    if (position == 0) {
                        // 发送请求之前再次判断一下这个座位有没有人
                        KaraokeRoomSeatEntity seatEntity = mKaraokeRoomSeatEntityList.get(itemPos);
                        if (seatEntity.isUsed) {
                            ToastUtils.showShort(R.string.trtckaraoke_toast_position_is_already_occupied);
                            return;
                        }
                        if (seatEntity.isClose) {
                            ToastUtils.showShort(getString(R.string.trtckaraoke_seat_closed));
                            return;
                        }
                        PermissionHelper.requestPermission(KaraokeRoomAudienceActivity.this,
                                PermissionHelper.PERMISSION_MICROPHONE, new PermissionHelper.PermissionCallback() {
                                    @Override
                                    public void onGranted() {
                                        startTakeSeat(itemPos);
                                    }

                                    @Override
                                    public void onDenied() {

                                    }
                                });

                    }
                    dialog.dismiss();
                }
            }, getString(R.string.trtckaraoke_tv_apply_for_chat));
            dialog.show();
        } else {
            //主播点击自己的头像主动下麦
            if (entity.userId.equals(mSelfUserId)) {
                leaveSeat();
            } else {
                ToastUtils.showShort(R.string.trtckaraoke_toast_position_is_already_occupied);
            }
        }
    }

    //上麦
    public void startTakeSeat(final int itemPos) {
        if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
            ToastUtils.showShort(R.string.trtckaraoke_toast_you_are_already_an_anchor);
            return;
        }

        if (mNeedRequest) {
            //需要申请上麦
            if (mOwnerId == null) {
                ToastUtils.showShort(R.string.trtckaraoke_toast_the_room_is_not_ready);
                return;
            }
            String inviteId = mTRTCKaraokeRoom.sendInvitation(TCConstants.CMD_REQUEST_TAKE_SEAT, mOwnerId,
                    String.valueOf(changeSeatIndexToModelIndex(itemPos)), new TRTCKaraokeRoomCallback.ActionCallback() {
                        @Override
                        public void onCallback(int code, String msg) {
                            if (code == 0) {
                                ToastUtils.showShort(R
                                        .string.trtckaraoke_toast_application_has_been_sent_please_wait_for_processing);
                            } else {
                                ToastUtils.showShort(
                                        getString(R.string.trtckaraoke_toast_failed_to_send_application, msg));
                            }
                        }
                    });
            mInvitationSeatMap.put(inviteId, itemPos);
        } else {
            //听众自动上麦
            if (mAlertDialog == null) {
                mAlertDialog = new ConfirmDialogFragment();
            }
            if (mAlertDialog.isAdded()) {
                mAlertDialog.dismiss();
            }
            mAlertDialog.setMessage(getString(R.string.trtckaraoke_apply_seat_ask));
            mAlertDialog.setPositiveClickListener(new ConfirmDialogFragment.PositiveClickListener() {
                @Override
                public void onClick() {
                    mAlertDialog.dismiss();
                    if (mIsTakingSeat) {
                        return;
                    }
                    showTakingSeatLoading(true);
                    mTRTCKaraokeRoom.enterSeat(changeSeatIndexToModelIndex(itemPos),
                            new TRTCKaraokeRoomCallback.ActionCallback() {
                                @Override
                                public void onCallback(int code, String msg) {
                                    if (code == 0) {
                                        //成功上座位，可以展示UI了
                                        ToastUtils.showLong(getString(R
                                                .string.trtckaraoke_toast_owner_succeeded_in_occupying_the_seat));
                                    } else {
                                        showTakingSeatLoading(false);
                                        ToastUtils.showLong(getString(R
                                                .string.trtckaraoke_toast_owner_failed_to_occupy_the_seat), code, msg);
                                    }
                                }
                            });
                }
            });
            mAlertDialog.setNegativeClickListener(new ConfirmDialogFragment.NegativeClickListener() {
                @Override
                public void onClick() {
                    mAlertDialog.dismiss();
                }
            });
            mAlertDialog.show(this.getFragmentManager(), "confirm_apply_seat");
        }

    }

    @Override
    public void onRoomInfoChange(TRTCKaraokeRoomDef.RoomInfo roomInfo) {
        super.onRoomInfoChange(roomInfo);
        mOwnerId = roomInfo.ownerId;
        mRoomInfoController.setRoomOwnerId(roomInfo.ownerId);
        //进入房间后,将roominfo先传递给KTVMusic实现类,再传递实现类给布局
        mKaraokeMusicService.setRoomInfo(roomInfo);
        ktvMusicImplComplete();
        // 刷新界面
        refreshView();
    }

    @Override
    public void onReceiveNewInvitation(final String id, String inviter, String cmd, final String content) {
        super.onReceiveNewInvitation(id, inviter, cmd, content);
    }

    @Override
    public void onInviteeAccepted(String id, String invitee) {
        super.onInviteeAccepted(id, invitee);
        Integer seatIndex = mInvitationSeatMap.remove(id);
        if (seatIndex != null) {
            KaraokeRoomSeatEntity entity = mKaraokeRoomSeatEntityList.get(seatIndex);
            if (!entity.isUsed) {
                if (mIsTakingSeat) {
                    return;
                }
                showTakingSeatLoading(true);
                mTRTCKaraokeRoom.enterSeat(changeSeatIndexToModelIndex(seatIndex),
                        new TRTCKaraokeRoomCallback.ActionCallback() {
                            @Override
                            public void onCallback(int code, String msg) {
                                if (code == 0) {
                                    TRTCLogger.d(TAG, " enter seat succeed");
                                } else {
                                    showTakingSeatLoading(false);
                                }
                            }
                        });
            }
        }
    }

    private void showTakingSeatLoading(boolean isShow) {
        mIsTakingSeat = isShow;
        mProgressBar.setVisibility(isShow ? View.VISIBLE : View.GONE);
        if (isShow) {
            mHandler.sendEmptyMessageDelayed(MSG_DISMISS_LOADING, 10000);
        } else {
            mHandler.removeMessages(MSG_DISMISS_LOADING);
        }
    }

    @Override
    public void onAnchorEnterSeat(int index, TRTCKaraokeRoomDef.UserInfo user) {
        super.onAnchorEnterSeat(index, user);
        if (user.userId.equals(mSelfUserId)) {
            mCurrentRole = TRTCCloudDef.TRTCRoleAnchor;
            mSelfSeatIndex = index;
            showTakingSeatLoading(false);
        }
    }

    @Override
    public void onAnchorLeaveSeat(int index, TRTCKaraokeRoomDef.UserInfo user) {
        super.onAnchorLeaveSeat(index, user);
        if (user.userId.equals(mSelfUserId)) {
            mCurrentRole = TRTCCloudDef.TRTCRoleAudience;
            mSelfSeatIndex = -1;
        }
    }

    @Override
    public void onRoomDestroy(String roomId) {
        super.onRoomDestroy(roomId);
        ToastUtils.showLong(R.string.trtckaraoke_msg_close_room);
        //房主销毁房间,其他人退出房间,并清除自己的信息
        UserModelManager.getInstance().getUserModel().userType = UserModel.UserType.NONE;
        if (mKaraokeAudioViewModel != null) {
            mKaraokeAudioViewModel.reset();
            mKaraokeAudioViewModel.unInit();
            mKaraokeAudioViewModel = null;
        }
        if (mKaraokeMusicService != null) {
            mKaraokeMusicService.onExitRoom();
            mKaraokeMusicService = null;
        }

        //在房间内,房主解散销毁界面,则退出房间界面,不显示悬浮窗;如果在房间外房主销毁解散房间,直接销毁悬浮窗
        if (FloatWindow.mIsShowing) {
            FloatWindow.getInstance().destroy();
            mLastEntity = null;
        } else {
            mRoomDestroy = true;
        }
        finish();
    }

    private void showReportDialog() {
        try {
            Class clz = Class.forName("com.tencent.liteav.demo.report.ReportDialog");
            Method method = clz.getDeclaredMethod("showReportDialog", Context.class, String.class, String.class);
            method.invoke(null, this, String.valueOf(mRoomId), mOwnerId);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private TUILoginListener mTUILoginListener = new TUILoginListener() {
        @Override
        public void onKickedOffline() {
            Log.e(TAG, "onKickedOffline");
            mTRTCKaraokeRoom.exitRoom(null);
            finish();
        }
    };
}

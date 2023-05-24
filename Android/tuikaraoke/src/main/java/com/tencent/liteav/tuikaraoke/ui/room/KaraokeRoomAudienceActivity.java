package com.tencent.liteav.tuikaraoke.ui.room;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.View;

import com.tencent.liteav.tuikaraoke.ui.utils.Constants;
import com.tencent.liteav.tuikaraoke.ui.utils.Toast;
import com.tencent.liteav.basic.RTCubeUtils;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;
import com.tencent.liteav.tuikaraoke.ui.utils.PermissionHelper;
import com.tencent.liteav.tuikaraoke.ui.widget.CommonBottomDialog;
import com.tencent.liteav.tuikaraoke.ui.widget.ConfirmDialogFragment;
import com.tencent.qcloud.tuicore.TUILogin;
import com.tencent.qcloud.tuicore.interfaces.TUICallback;
import com.tencent.qcloud.tuicore.interfaces.TUILoginListener;
import com.tencent.trtc.TRTCCloudDef;
import com.tencent.trtc.TRTCCloudDef.TRTCQuality;

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
    private        ConfirmDialogFragment mAlertDialog;
    private        boolean               mIsTakingSeat; //正在进行上麦

    private        int                   mLocalNetworkQuality;

    public static void enterKaraokeRoom(final Context context, int roomId, String ownerId, String userId) {
        Intent starter = new Intent(context, KaraokeRoomAudienceActivity.class);
        starter.putExtra(KTVROOM_ROOM_ID, roomId);
        starter.putExtra(KTVROOM_OWNER_ID, ownerId);
        starter.putExtra(KTVROOM_USER_ID, userId);
        context.startActivity(starter);
    }

    private void enterRoom() {
        mIsSeatInitSuccess = false;
        mCurrentRole = TRTCCloudDef.TRTCRoleAudience;
        mTRTCKaraokeRoom.enterRoom(mRoomId, new TUICallback() {
            @Override
            public void onSuccess() {
                mTRTCKaraokeRoom.updateNetworkTime();
                Toast.show(R.string.trtckaraoke_toast_enter_the_room_successfully, Toast.LENGTH_SHORT);
            }

            @Override
            public void onError(int code, String message) {
                Toast.show(getString(R.string.trtckaraoke_toast_enter_the_room_failure, code, message),
                        Toast.LENGTH_SHORT);
                finish();
            }
        });
        TUILogin.addLoginListener(mTUILoginListener);
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

    private void initAudience() {
        mOwnerId = getIntent().getStringExtra(KTVROOM_OWNER_ID);
        mInvitationSeatMap = new HashMap<>();
        mKaraokeRoomSeatAdapter.notifyDataSetChanged();
        enterRoom();
        mBtnReport.setVisibility(RTCubeUtils.isRTCubeApp(this) ? View.VISIBLE : View.GONE);
        mBtnReport.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showReportDialog();
            }
        });

        TRTCKaraokeRoomDef.RoomInfo roomInfo = new TRTCKaraokeRoomDef.RoomInfo();
        roomInfo.roomId = String.valueOf(mRoomId);
        roomInfo.ownerId = mOwnerId;
        createKTVMusicService(roomInfo);
    }

    public void showLeaveSeatAndExitRoomDialog() {
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
                mTRTCKaraokeRoom.leaveSeat(new TUICallback() {
                    @Override
                    public void onSuccess() {
                        Toast.show(R.string.trtckaraoke_toast_offline_successfully, Toast.LENGTH_SHORT);
                        exitRoom();
                    }

                    @Override
                    public void onError(int errorCode, String errorMessage) {
                        Toast.show(getString(R.string.trtckaraoke_toast_offline_failure, errorMessage),
                                Toast.LENGTH_SHORT);
                        exitRoom();
                    }
                });
                mAlertDialog.dismiss();
            }
        });
        mAlertDialog.setNegativeClickListener(new ConfirmDialogFragment.NegativeClickListener() {
            @Override
            public void onClick() {
                mAlertDialog.dismiss();
            }
        });
        mAlertDialog.show(this.getFragmentManager(), "confirm_leave_seat_and_exit_room");
    }

    @Override
    public void onSeatListChange(List<TRTCKaraokeRoomDef.SeatInfo> seatInfoList) {
        super.onSeatListChange(seatInfoList);
        mIsSeatInitSuccess = true;
    }

    @Override
    public void onNetworkQuality(TRTCQuality localQuality, List<TRTCQuality> remoteQuality) {
        super.onNetworkQuality(localQuality, remoteQuality);
        if (localQuality == null) {
            return;
        }
        mLocalNetworkQuality = localQuality.quality;
        doCheckNetworkQuality(mLocalNetworkQuality);
    }

    private boolean doCheckNetworkQuality(int quality) {
        if (quality == 6) {
            // 不可用
            Toast.show(R.string.trtckaraoke_toast_network_not_available, Toast.LENGTH_SHORT);
            return false;
        } else if (quality >= 3) {
            // 一般、很差、差
            Toast.show(R.string.trtckaraoke_toast_not_supported_chorus, Toast.LENGTH_SHORT);
            return false;
        } else {
            return true;
        }
    }

    /**
     * 点击麦位列表听众端的操作
     *
     * @param itemPos
     */
    @Override
    public void onItemClick(final int itemPos) {
        if (!mIsSeatInitSuccess) {
            Toast.show(R.string.trtckaraoke_toast_list_has_not_been_initialized, Toast.LENGTH_SHORT);
            return;
        }
        // 判断座位有没有人
        KaraokeRoomSeatEntity entity = mKaraokeRoomSeatEntityList.get(itemPos);
        if (entity.isClose) {
            Toast.show(R.string.trtckaraoke_toast_position_is_locked_cannot_enter_seat, Toast.LENGTH_SHORT);
        } else if (!entity.isUsed) {
            if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
                Toast.show(R.string.trtckaraoke_toast_you_are_already_an_anchor, Toast.LENGTH_SHORT);
                return;
            }
            if (!doCheckNetworkQuality(mLocalNetworkQuality)) {
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
                            Toast.show(seatEntity.userName, Toast.LENGTH_SHORT);
                            return;
                        }
                        if (seatEntity.isClose) {
                            Toast.show(getString(R.string.trtckaraoke_seat_closed), Toast.LENGTH_SHORT);
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
                Toast.show(entity.userName, Toast.LENGTH_SHORT);
            }
        }
    }

    //上麦
    public void startTakeSeat(final int itemPos) {
        if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
            Toast.show(R.string.trtckaraoke_toast_you_are_already_an_anchor, Toast.LENGTH_SHORT);
            return;
        }

        if (!mUpdateNetworkSuccessed) {
            showNetworkTimeSyncFailDialog();
            return;
        }

        if (mNeedRequest) {
            //需要申请上麦
            if (mOwnerId == null) {
                Toast.show(R.string.trtckaraoke_toast_the_room_is_not_ready, Toast.LENGTH_SHORT);
                return;
            }
            String inviteId = mTRTCKaraokeRoom.sendInvitation(Constants.CMD_REQUEST_TAKE_SEAT, mOwnerId,
                    String.valueOf(changeSeatIndexToModelIndex(itemPos)), new TUICallback() {
                        @Override
                        public void onSuccess() {
                            Toast.show(
                                    R.string.trtckaraoke_toast_application_has_been_sent_please_wait_for_processing,
                                    Toast.LENGTH_SHORT);
                        }

                        @Override
                        public void onError(int errorCode, String errorMessage) {
                            Toast.show(
                                    getString(R.string.trtckaraoke_toast_failed_to_send_application, errorMessage),
                                    Toast.LENGTH_SHORT);
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
                            new TUICallback() {
                                @Override
                                public void onSuccess() {
                                    //成功上座位，可以展示UI了
                                    Toast.show(getString(
                                            R.string.trtckaraoke_toast_owner_succeeded_in_occupying_the_seat),
                                            Toast.LENGTH_LONG);
                                }

                                @Override
                                public void onError(int code, String msg) {
                                    showTakingSeatLoading(false);
                                    String info = String.format(getString(
                                            R.string.trtckaraoke_toast_owner_failed_to_occupy_the_seat),
                                            code, msg);
                                    Toast.show(info, Toast.LENGTH_LONG);
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
        // 刷新界面
        refreshView();
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
                        new TUICallback() {
                            @Override
                            public void onSuccess() {
                                TRTCLogger.i(TAG, " enter seat succeed");
                            }

                            @Override
                            public void onError(int errorCode, String errorMessage) {
                                showTakingSeatLoading(false);
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
            showTakingSeatLoading(false);
        }
    }

    @Override
    public void onAnchorLeaveSeat(int index, TRTCKaraokeRoomDef.UserInfo user) {
        super.onAnchorLeaveSeat(index, user);
        if (user.userId.equals(mSelfUserId)) {
            mCurrentRole = TRTCCloudDef.TRTCRoleAudience;
        }
    }

    @Override
    protected void checkingBeforeExitRoom() {
        if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
            showLeaveSeatAndExitRoomDialog();
            return;
        }
        exitRoom();
    }

    @Override
    public void onOrderedManagerClick(int position) {
        super.onOrderedManagerClick(position);
        Toast.show(R.string.trtckaraoke_toast_room_owner_can_operate_it, Toast.LENGTH_LONG);
    }

    private void exitRoom() {
        if (mKaraokeAudioViewModel != null) {
            mKaraokeAudioViewModel.reset();
        }
        if (mKaraokeMusicService != null) {
            mKaraokeMusicService.destroyService();
        }
        if (mTRTCKaraokeRoom != null) {
            mTRTCKaraokeRoom.exitRoom(null);
        }
        TUILogin.removeLoginListener(mTUILoginListener);
        finish();
    }

    @Override
    public void onRoomDestroy(String roomId) {
        super.onRoomDestroy(roomId);
        exitRoom();
        Toast.show(R.string.trtckaraoke_msg_close_room, Toast.LENGTH_SHORT);
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
            exitRoom();
        }
    };
}

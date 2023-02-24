package com.tencent.liteav.tuikaraoke.ui.room;

import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.util.TypedValue;
import android.view.Display;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.AppCompatImageButton;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.blankj.utilcode.util.ToastUtils;
import com.google.gson.Gson;
import com.tencent.liteav.basic.ImageLoader;
import com.tencent.liteav.basic.UserModel;
import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoom;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomCallback;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDelegate;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.model.impl.base.TXSeatInfo;
import com.tencent.liteav.tuikaraoke.ui.audio.impl.KaraokeAudioViewModel;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;
import com.tencent.liteav.tuikaraoke.ui.base.MemberEntity;
import com.tencent.liteav.tuikaraoke.ui.gift.GiftAdapter;
import com.tencent.liteav.tuikaraoke.ui.gift.GiftPanelDelegate;
import com.tencent.liteav.tuikaraoke.ui.gift.IGiftPanelView;
import com.tencent.liteav.tuikaraoke.ui.gift.imp.DefaultGiftAdapterImp;
import com.tencent.liteav.tuikaraoke.ui.gift.imp.GiftAnimatorLayout;
import com.tencent.liteav.tuikaraoke.ui.gift.imp.GiftInfo;
import com.tencent.liteav.tuikaraoke.ui.gift.imp.GiftInfoDataHandler;
import com.tencent.liteav.tuikaraoke.ui.gift.imp.GiftPanelViewImp;
import com.tencent.liteav.tuikaraoke.ui.lrc.LyricsReader;
import com.tencent.liteav.tuikaraoke.ui.lrc.widget.AbstractLrcView;
import com.tencent.liteav.tuikaraoke.ui.lrc.widget.LyricsView;
import com.tencent.liteav.tuikaraoke.ui.music.IUpdateLrcDelegate;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicCallback;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.ui.music.impl.KaraokeMusicView;
import com.tencent.liteav.tuikaraoke.ui.utils.PermissionHelper;
import com.tencent.liteav.tuikaraoke.ui.widget.ConfirmDialogFragment;
import com.tencent.liteav.tuikaraoke.ui.widget.InputTextMsgDialog;
import com.tencent.liteav.tuikaraoke.ui.widget.msg.AudienceEntity;
import com.tencent.liteav.tuikaraoke.ui.widget.msg.MsgEntity;
import com.tencent.liteav.tuikaraoke.ui.widget.msg.MsgListAdapter;
import com.tencent.trtc.TRTCCloudDef;

import java.io.File;
import java.lang.reflect.Constructor;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import de.hdodenhof.circleimageview.CircleImageView;

public class KaraokeRoomBaseActivity extends AppCompatActivity implements KaraokeRoomSeatAdapter.OnItemClickListener,
        TRTCKaraokeRoomDelegate,
        InputTextMsgDialog.OnTextSendListener,
        MsgListAdapter.OnItemClickListener,
        IUpdateLrcDelegate {
    protected static final String TAG = "KaraokeRoomBaseActivity";

    protected static final int    MAX_SEAT_SIZE         = 8;
    protected static final String KTVROOM_ROOM_ID       = "room_id";
    protected static final String KTVROOM_ROOM_NAME     = "room_name";
    protected static final String KTVROOM_USER_NAME     = "user_name";
    protected static final String KTVROOM_USER_ID       = "user_id";
    protected static final String KTVROOM_NEED_REQUEST  = "need_request";
    protected static final String KTVROOM_AUDIO_QUALITY = "audio_quality";
    protected static final String KTVROOM_USER_AVATAR   = "user_avatar";
    protected static final String KTVROOM_ROOM_COVER    = "room_cover";

    private static final int[] MESSAGE_USERNAME_COLOR_ARR = {
            R.color.trtckaraoke_color_msg_1,
            R.color.trtckaraoke_color_msg_2,
            R.color.trtckaraoke_color_msg_3,
            R.color.trtckaraoke_color_msg_4,
            R.color.trtckaraoke_color_msg_5,
            R.color.trtckaraoke_color_msg_6,
            R.color.trtckaraoke_color_msg_7,
    };

    protected String                      mSelfUserId;     //进房用户ID
    protected int                         mCurrentRole;    //用户当前角色:主播/听众
    public    TRTCKaraokeRoom             mTRTCKaraokeRoom;
    private   boolean                     isInitSeat;
    protected List<KaraokeRoomSeatEntity> mKaraokeRoomSeatEntityList;
    protected Map<String, Boolean>        mSeatUserMuteMap;
    protected KaraokeRoomSeatAdapter      mKaraokeRoomSeatAdapter;
    protected AudienceListAdapter         mAudienceListAdapter;
    protected TextView                    mTvRoomName;
    protected TextView                    mTvRoomId;
    protected RecyclerView                mRvSeat;
    protected RecyclerView                mRvAudience;
    protected RecyclerView                mRvImMsg;
    protected KaraokeMusicView            mKTVMusicView;
    protected AppCompatImageButton        mBtnExitRoom;
    protected AppCompatImageButton        mBtnMsg;
    protected AppCompatImageButton        mBtnMic;
    protected AppCompatImageButton        mBtnGift;
    protected AppCompatImageButton        mBtnReport;
    protected ImageView                   mIvAudienceMove;
    protected View                        mProgressBar;

    protected KaraokeAudioViewModel      mKaraokeAudioViewModel;
    protected InputTextMsgDialog         mInputTextMsgDialog;
    protected int                        mRoomId;
    protected String                     mRoomName;
    protected String                     mUserName;
    protected String                     mRoomCover;
    protected String                     mUserAvatar;
    protected CircleImageView            mImgRoom;
    protected boolean                    mNeedRequest;
    protected int                        mAudioQuality;
    protected List<MsgEntity>            mMsgEntityList;
    protected LinkedList<AudienceEntity> mAudienceEntityList;
    protected MsgListAdapter             mMsgListAdapter;
    protected ConfirmDialogFragment      mConfirmDialogFragment;
    protected List<MemberEntity>         mMemberEntityList;
    protected Map<String, MemberEntity>  mMemberEntityMap;

    private Context mContext;
    private String  mLastMsgUserId = null;
    private int     mMessageColorIndex;
    private int     mRvAudienceScrollPosition;
    private int     mSelfSeatIndex = -1;
    private long    lastClickTime  = -1;

    //礼物
    private GiftInfoDataHandler mGiftInfoDataHandler;
    private GiftAnimatorLayout  mGiftAnimatorLayout;

    private ConfirmDialogFragment mAlertDialog;
    private LyricsView            mLrcView;
    public  KaraokeMusicService   mKaraokeMusicService;
    private String                mRoomDefaultCover =
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover1.png";
    private boolean            mIsDestroyed;
    private String             mPackageName = "com.tencent.liteav.tuikaraoke.model.music.KaraokeMusicServiceImpl";
    public  RoomInfoController mRoomInfoController;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mContext = this;
        UserModelManager.getInstance().getUserModel().userType = UserModel.UserType.KARAOKE;
        // 应用运行时，保持不锁屏、全屏化
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.trtckaraoke_activity_main);
        initStatusBar();
        createKTVMusicImpl();
        initView();
        initData();
        initListener();
        MsgEntity msgEntity = new MsgEntity();
        msgEntity.type = MsgEntity.TYPE_WELCOME;
        msgEntity.content = getString(R.string.trtckaraoke_welcome_visit);
        msgEntity.linkUrl = getString(R.string.trtckaraoke_welcome_visit_link);
        showImMsg(msgEntity);
    }

    // 通过反射创建歌曲管理实现类的实例
    public void createKTVMusicImpl() {
        try {
            Class clz = Class.forName(mPackageName);
            Constructor constructor = clz.getConstructor(Context.class);
            mKaraokeMusicService = (KaraokeMusicService) constructor.newInstance(this);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void initStatusBar() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Window window = getWindow();
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
            window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            window.setStatusBarColor(Color.TRANSPARENT);
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
        }
    }

    protected void initView() {
        mImgRoom = (CircleImageView) findViewById(R.id.iv_anchor_head);
        mTvRoomName = (TextView) findViewById(R.id.tv_room_name);
        mTvRoomId = (TextView) findViewById(R.id.tv_room_id);
        mRvAudience = (RecyclerView) findViewById(R.id.rv_audience);
        mIvAudienceMove = (ImageView) findViewById(R.id.iv_audience_move);
        mBtnExitRoom = (AppCompatImageButton) findViewById(R.id.exit_room);
        mProgressBar = findViewById(R.id.progress_group);

        mRvSeat = (RecyclerView) findViewById(R.id.rv_seat);
        mRvImMsg = (RecyclerView) findViewById(R.id.rv_im_msg);

        mBtnMsg = (AppCompatImageButton) findViewById(R.id.btn_msg);
        mBtnMic = (AppCompatImageButton) findViewById(R.id.btn_mic);
        mBtnGift = (AppCompatImageButton) findViewById(R.id.btn_more_gift);
        mBtnReport = (AppCompatImageButton) findViewById(R.id.btn_report);

        mConfirmDialogFragment = new ConfirmDialogFragment();
        mInputTextMsgDialog = new InputTextMsgDialog(this, R.style.TRTCKTVRoomInputDialog);
        mInputTextMsgDialog.setmOnTextSendListener(this);
        mMsgEntityList = new ArrayList<>();
        mMemberEntityList = new ArrayList<>();
        mMemberEntityMap = new HashMap<>();
        mBtnExitRoom.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onBackPressed();
            }
        });
        mMsgListAdapter = new MsgListAdapter(this, mMsgEntityList, this);
        mRvImMsg.setLayoutManager(new LinearLayoutManager(this));
        mRvImMsg.setAdapter(mMsgListAdapter);
        mSeatUserMuteMap = new HashMap<>();
        mKaraokeRoomSeatEntityList = new ArrayList<>();
        for (int i = 0; i < MAX_SEAT_SIZE; i++) {
            KaraokeRoomSeatEntity seatEntity = new KaraokeRoomSeatEntity();
            seatEntity.index = i;
            mKaraokeRoomSeatEntityList.add(seatEntity);
        }

        //座位表
        mKaraokeRoomSeatAdapter = new KaraokeRoomSeatAdapter(this, mKaraokeRoomSeatEntityList, this);
        GridLayoutManager gridLayoutManager = new GridLayoutManager(this, 4);
        mRvSeat.setLayoutManager(gridLayoutManager);
        mRvSeat.setAdapter(mKaraokeRoomSeatAdapter);

        //听众表
        mAudienceEntityList = new LinkedList<>();
        mAudienceListAdapter = new AudienceListAdapter(this, mAudienceEntityList);
        LinearLayoutManager lm = new LinearLayoutManager(this);
        lm.setOrientation(LinearLayoutManager.HORIZONTAL);
        mRvAudience.setLayoutManager(lm);
        mRvAudience.setAdapter(mAudienceListAdapter);

        //礼物消息显示
        mGiftAnimatorLayout = findViewById(R.id.gift_animator_layout);

        //歌曲管理控件
        mKTVMusicView = (KaraokeMusicView) findViewById(R.id.fl_songtable_container);

        //歌词显示控件
        mLrcView = findViewById(R.id.lrc_view);
    }

    public void ktvMusicImplComplete() {
        mKTVMusicView.setLrcDelegate(this);
        mRoomInfoController.setMusicImpl(mKaraokeMusicService);
        mKTVMusicView.init(mRoomInfoController, mKaraokeAudioViewModel);
    }

    protected void initData() {
        Intent intent = getIntent();
        mRoomId = intent.getIntExtra(KTVROOM_ROOM_ID, 0);
        mRoomName = intent.getStringExtra(KTVROOM_ROOM_NAME);
        mUserName = intent.getStringExtra(KTVROOM_USER_NAME);
        mSelfUserId = intent.getStringExtra(KTVROOM_USER_ID);
        mNeedRequest = intent.getBooleanExtra(KTVROOM_NEED_REQUEST, false);
        mUserAvatar = intent.getStringExtra(KTVROOM_USER_AVATAR);
        mAudioQuality = intent.getIntExtra(KTVROOM_AUDIO_QUALITY, TRTCCloudDef.TRTC_AUDIO_QUALITY_MUSIC);
        mRoomCover = intent.getStringExtra(KTVROOM_ROOM_COVER);
        if (mRoomCover == null) {
            ImageLoader.loadImage(this, mImgRoom, mRoomDefaultCover);
        } else {
            ImageLoader.loadImage(this, mImgRoom, mRoomCover, R.drawable.trtckaraoke_ic_cover);
        }

        mTRTCKaraokeRoom = TRTCKaraokeRoom.sharedInstance(this);
        mTRTCKaraokeRoom.setDelegate(this);
        mKaraokeAudioViewModel = new KaraokeAudioViewModel();
        mKaraokeAudioViewModel.setTRTCKaraokeRoom(mTRTCKaraokeRoom);
        // 礼物
        GiftAdapter giftAdapter = new DefaultGiftAdapterImp();
        mGiftInfoDataHandler = new GiftInfoDataHandler();
        mGiftInfoDataHandler.setGiftAdapter(giftAdapter);

        mRoomInfoController = new RoomInfoController();
    }

    protected void initListener() {
        mBtnMic.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

                PermissionHelper.requestPermission(KaraokeRoomBaseActivity.this,
                        PermissionHelper.PERMISSION_MICROPHONE, new PermissionHelper.PermissionCallback() {
                            @Override
                            public void onGranted() {
                                updateMicButton();
                            }

                            @Override
                            public void onDenied() {

                            }
                        });
            }
        });

        mBtnMsg.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showInputMsgDialog();
            }
        });
        mBtnGift.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showGiftPanel();
            }
        });

        mRvAudience.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(RecyclerView recyclerView, int dx, int dy) {
                super.onScrolled(recyclerView, dx, dy);
                mRvAudienceScrollPosition = dx;
            }
        });
        mIvAudienceMove.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mRvAudienceScrollPosition < 0) {
                    mRvAudienceScrollPosition = 0;
                }
                int position = mRvAudienceScrollPosition + dp2px(mContext, 32);
                mRvAudience.smoothScrollBy(position, 0);
            }
        });
    }

    public int dp2px(Context context, float dpVal) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP,
                dpVal, context.getResources().getDisplayMetrics());
    }

    private void updateMicButton() {
        if (checkButtonPermission()) {
            boolean currentMode = !mBtnMic.isSelected();
            if (currentMode) {
                if (!isSeatMute(mSelfSeatIndex)) {
                    updateMuteStatusView(mSelfUserId, false);
                    mTRTCKaraokeRoom.muteLocalAudio(false);
                    ToastUtils.showLong(getString(R.string.trtckaraoke_toast_you_have_turned_on_the_microphone));
                } else {
                    ToastUtils.showLong(getString(R.string.trtckaraoke_seat_already_mute));
                }
            } else {
                mTRTCKaraokeRoom.muteLocalAudio(true);
                updateMuteStatusView(mSelfUserId, true);
                ToastUtils.showLong(getString(R.string.trtckaraoke_toast_you_have_turned_off_the_microphone));
            }
        }
    }

    private boolean isSeatMute(int seatIndex) {
        KaraokeRoomSeatEntity seatEntity = findSeatEntityFromUserId(seatIndex);
        if (seatEntity != null) {
            return seatEntity.isSeatMute;
        }
        return false;
    }

    /**
     * 判断是否为主播，有操作按钮的权限
     *
     * @return 是否有权限
     */
    protected boolean checkButtonPermission() {
        boolean hasPermission = (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor);
        if (!hasPermission) {
            ToastUtils.showLong(getString(R.string.trtckaraoke_toast_anchor_can_only_operate_it));
        }
        return hasPermission;
    }

    //展示礼物面板
    private void showGiftPanel() {
        IGiftPanelView giftPanelView = new GiftPanelViewImp(this);
        giftPanelView.init(mGiftInfoDataHandler);
        giftPanelView.setGiftPanelDelegate(new GiftPanelDelegate() {
            @Override
            public void onGiftItemClick(GiftInfo giftInfo) {
                sendGift(giftInfo);
            }

            @Override
            public void onChargeClick() {

            }
        });
        giftPanelView.show();
    }

    //发送礼物消息出去同时展示礼物动画和弹幕
    private void sendGift(GiftInfo giftInfo) {
        GiftInfo giftInfoCopy = giftInfo.copy();
        giftInfoCopy.sendUser = mContext.getString(R.string.trtckaraoke_me);
        giftInfoCopy.sendUserHeadIcon = UserModelManager.getInstance().getUserModel().userAvatar;
        mGiftAnimatorLayout.show(giftInfoCopy);

        GiftSendJson jsonData = new GiftSendJson();
        jsonData.setSendUser(UserModelManager.getInstance().getUserModel().userName);
        jsonData.setSendUserHeadIcon(UserModelManager.getInstance().getUserModel().userAvatar);
        jsonData.setGiftId(giftInfo.giftId);
        Gson gson = new Gson();

        mTRTCKaraokeRoom.sendRoomCustomMsg(String.valueOf(TCConstants.IMCMD_GIFT),
                gson.toJson(jsonData), new TRTCKaraokeRoomCallback.ActionCallback() {
                    @Override
                    public void onCallback(int code, String msg) {
                        if (code != 0) {
                            Toast.makeText(mContext, R.string.trtckaraoke_toast_sent_message_failure,
                                    Toast.LENGTH_SHORT).show();
                        }
                    }
                });
    }

    /**
     * 处理礼物弹幕消息
     */
    private void handleGiftMsg(TRTCKaraokeRoomDef.UserInfo userInfo, String data) {
        if (mGiftInfoDataHandler != null) {
            Gson gson = new Gson();
            GiftSendJson jsonData = gson.fromJson(data, GiftSendJson.class);
            String giftId = jsonData.getGiftId();
            GiftInfo giftInfo = mGiftInfoDataHandler.getGiftInfo(giftId);
            if (giftInfo != null) {
                if (userInfo != null) {
                    giftInfo.sendUserHeadIcon = userInfo.userAvatar;
                    if (!TextUtils.isEmpty(userInfo.userName)) {
                        giftInfo.sendUser = userInfo.userName;
                    } else {
                        giftInfo.sendUser = userInfo.userId;
                    }
                }
                mGiftAnimatorLayout.show(giftInfo);
            }
        }
    }

    public void refreshView() {
        if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
            mBtnMic.setVisibility(View.VISIBLE);
            mBtnMic.setActivated(true);
            mBtnMic.setSelected(true);
            mKTVMusicView.updateView(true);
        } else {
            mBtnMic.setVisibility(View.GONE);
            mKTVMusicView.updateView(false);
        }
    }

    /**
     * 网络质量监听
     *
     * @param localQuality  上行网络质量。
     * @param remoteQuality 下行网络质量。
     */

    @Override
    public void onNetworkQuality(TRTCCloudDef.TRTCQuality localQuality, List<TRTCCloudDef.TRTCQuality> remoteQuality) {
        matchQuality(localQuality, findSeatEntityFromUserId(mSelfUserId));
        for (TRTCCloudDef.TRTCQuality quality : remoteQuality) {
            matchQuality(quality, findSeatEntityFromUserId(quality.userId));
        }
    }

    private void matchQuality(TRTCCloudDef.TRTCQuality trtcQuality, KaraokeRoomSeatEntity entity) {
        if (entity == null || entity.isClose || !entity.isUsed) {
            return;
        }
        int oldQulity = entity.getQuality();
        switch (trtcQuality.quality) {
            case TRTCCloudDef.TRTC_QUALITY_Excellent:
            case TRTCCloudDef.TRTC_QUALITY_Good:
                entity.setQuality(KaraokeRoomSeatEntity.QUALITY_GOOD);
                break;
            case TRTCCloudDef.TRTC_QUALITY_Poor:
            case TRTCCloudDef.TRTC_QUALITY_Bad:
                entity.setQuality(KaraokeRoomSeatEntity.QUALITY_NORMAL);
                break;
            case TRTCCloudDef.TRTC_QUALITY_Vbad:
            case TRTCCloudDef.TRTC_QUALITY_Down:
                entity.setQuality(KaraokeRoomSeatEntity.QUALITY_BAD);
                break;
            default:
                entity.setQuality(KaraokeRoomSeatEntity.QUALITY_NORMAL);
                break;
        }
        if (oldQulity != entity.getQuality()) {
            mKaraokeRoomSeatAdapter.notifyItemChanged(mKaraokeRoomSeatEntityList.indexOf(entity),
                    KaraokeRoomSeatAdapter.QUALITY);
        }
    }

    /**
     *     /////////////////////////////////////////////////////////////////////////////////
     *     //
     *     //                      发送文本信息
     *     //
     *     /////////////////////////////////////////////////////////////////////////////////
     */
    /**
     * 发消息弹出框
     */
    private void showInputMsgDialog() {
        WindowManager windowManager = getWindowManager();
        Display display = windowManager.getDefaultDisplay();
        WindowManager.LayoutParams lp = mInputTextMsgDialog.getWindow().getAttributes();
        lp.width = display.getWidth(); //设置宽度
        mInputTextMsgDialog.getWindow().setAttributes(lp);
        mInputTextMsgDialog.setCancelable(true);
        mInputTextMsgDialog.getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE);
        mInputTextMsgDialog.show();
    }

    @Override
    public void onTextSend(String msg) {
        if (msg.length() == 0) {
            return;
        }
        byte[] byteNum = msg.getBytes(StandardCharsets.UTF_8);
        if (byteNum.length > 160) {
            Toast.makeText(this, getString(R.string.trtckaraoke_toast_please_enter_content), Toast.LENGTH_SHORT).show();
            return;
        }

        //消息回显
        MsgEntity entity = new MsgEntity();
        entity.userName = getString(R.string.trtckaraoke_me);
        entity.content = msg;
        entity.isChat = true;
        entity.userId = mSelfUserId;
        entity.type = MsgEntity.TYPE_NORMAL;
        showImMsg(entity);

        mTRTCKaraokeRoom.sendRoomTextMsg(msg, new TRTCKaraokeRoomCallback.ActionCallback() {
            @Override
            public void onCallback(int code, String msg) {
                if (code == 0) {
                    ToastUtils.showShort(getString(R.string.trtckaraoke_toast_sent_successfully));
                } else {
                    ToastUtils.showShort(getString(R.string.trtckaraoke_toast_sent_message_failure));
                }
            }
        });
    }

    /**
     * 座位上点击按钮的反馈
     *
     * @param position
     */
    @Override
    public void onItemClick(int position) {
    }

    @Override
    public void onError(int code, String message) {

    }

    @Override
    public void onWarning(int code, String message) {

    }

    @Override
    public void onDebugLog(String message) {

    }

    @Override
    public void onRoomDestroy(String roomId) {

    }

    @Override
    public void onRoomInfoChange(TRTCKaraokeRoomDef.RoomInfo roomInfo) {
        mNeedRequest = roomInfo.needRequest;
        mRoomName = roomInfo.roomName;
        mTvRoomName.setText(roomInfo.roomName);
        mTvRoomId.setText(getString(R.string.trtckaraoke_room_id, roomInfo.roomId));
    }

    @Override
    public void onSeatListChange(final List<TRTCKaraokeRoomDef.SeatInfo> seatInfoList) {
        //先刷一遍界面
        final List<String> userids = new ArrayList<>();
        for (int i = 0; i < seatInfoList.size(); i++) {
            TRTCKaraokeRoomDef.SeatInfo newSeatInfo = seatInfoList.get(i);
            // 座位区域的列表
            KaraokeRoomSeatEntity oldSeatEntity = mKaraokeRoomSeatEntityList.get(i);
            if (newSeatInfo.userId != null && !newSeatInfo.userId.equals(oldSeatEntity.userId)) {
                //userId相同，可以不用重新获取信息了
                //但是如果有新的userId进来，那么应该去拿一下主播的详细信息
                userids.add(newSeatInfo.userId);
            }
            oldSeatEntity.userId = newSeatInfo.userId;
            // 座位的状态更新一下
            switch (newSeatInfo.status) {
                case TXSeatInfo.STATUS_UNUSED:
                    oldSeatEntity.isUsed = false;
                    oldSeatEntity.isClose = false;
                    break;
                case TXSeatInfo.STATUS_CLOSE:
                    oldSeatEntity.isUsed = false;
                    oldSeatEntity.isClose = true;
                    break;
                case TXSeatInfo.STATUS_USED:
                    oldSeatEntity.isUsed = true;
                    oldSeatEntity.isClose = false;
                    break;
                default:
                    break;
            }
            oldSeatEntity.isSeatMute = newSeatInfo.mute;
        }
        for (String userId : userids) {
            if (!mSeatUserMuteMap.containsKey(userId)) {
                mSeatUserMuteMap.put(userId, true);
            }
        }
        //所有的userId拿到手，开始去搜索详细信息了
        mTRTCKaraokeRoom.getUserInfoList(userids, new TRTCKaraokeRoomCallback.UserListCallback() {
            @Override
            public void onCallback(int code, String msg, List<TRTCKaraokeRoomDef.UserInfo> list) {
                // 解析所有人的userinfo
                Map<String, TRTCKaraokeRoomDef.UserInfo> map = new HashMap<>();
                for (TRTCKaraokeRoomDef.UserInfo userInfo : list) {
                    map.put(userInfo.userId, userInfo);
                }
                for (int i = 0; i < seatInfoList.size(); i++) {
                    TRTCKaraokeRoomDef.SeatInfo newSeatInfo = seatInfoList.get(i);
                    TRTCKaraokeRoomDef.UserInfo userInfo = map.get(newSeatInfo.userId);
                    if (userInfo == null) {
                        continue;
                    }
                    boolean isUserMute = mSeatUserMuteMap.get(userInfo.userId);
                    // 接下来是座位区域的列表
                    KaraokeRoomSeatEntity seatEntity = mKaraokeRoomSeatEntityList.get(i);
                    if (userInfo.userId.equals(seatEntity.userId)) {
                        seatEntity.userName = userInfo.userName;
                        seatEntity.userAvatar = userInfo.userAvatar;
                        seatEntity.isUserMute = isUserMute;
                    }
                }
                mKaraokeRoomSeatAdapter.notifyDataSetChanged();
                if (!isInitSeat) {
                    getAudienceList();
                    isInitSeat = true;
                }
            }
        });
        mRoomInfoController.setRoomSeatEntityList(mKaraokeRoomSeatEntityList);
    }

    @Override
    public void onAnchorEnterSeat(int index, TRTCKaraokeRoomDef.UserInfo user) {
        Log.d(TAG, "onAnchorEnterSeat userInfo:" + user);
        MsgEntity msgEntity = new MsgEntity();
        msgEntity.type = MsgEntity.TYPE_NORMAL;
        msgEntity.userName = user.userName;
        msgEntity.content = getString(R.string.trtckaraoke_tv_online_no_name, index + 1);
        showImMsg(msgEntity);
        mAudienceListAdapter.removeMember(user.userId);
        if (user.userId.equals(mSelfUserId)) {
            mCurrentRole = TRTCCloudDef.TRTCRoleAnchor;
            mSelfSeatIndex = index;
            refreshView();
        }
    }

    @Override
    public void onAnchorLeaveSeat(int index, TRTCKaraokeRoomDef.UserInfo user) {
        Log.d(TAG, "onAnchorLeaveSeat userInfo:" + user);
        MsgEntity msgEntity = new MsgEntity();
        msgEntity.type = MsgEntity.TYPE_NORMAL;
        msgEntity.userName = user.userName;
        msgEntity.content = getString(R.string.trtckaraoke_tv_offline_no_name, index + 1);
        showImMsg(msgEntity);
        AudienceEntity entity = new AudienceEntity();
        entity.userId = user.userId;
        entity.userAvatar = user.userAvatar;
        mAudienceListAdapter.addMember(entity);
        if (user.userId.equals(mSelfUserId)) {
            mCurrentRole = TRTCCloudDef.TRTCRoleAudience;
            mSelfSeatIndex = -1;
            refreshView();
            if (mRoomInfoController.isRoomOwner()) {
                if (mKaraokeMusicService != null) {
                    mKaraokeMusicService.deleteAllMusic(mSelfUserId, new KaraokeMusicCallback.ActionCallback() {
                        @Override
                        public void onCallback(int code, String msg) {

                        }
                    });
                }
            }
            mKaraokeAudioViewModel.stopPlayMusic(null);
            mKaraokeAudioViewModel.setCurrentStatus(KaraokeAudioViewModel.MUSIC_STOP);
        }
    }

    @Override
    public void onSeatMute(int index, boolean isMute) {
        MsgEntity msgEntity = new MsgEntity();
        msgEntity.type = MsgEntity.TYPE_NORMAL;
        if (isMute) {
            msgEntity.content = getString(R.string.trtckaraoke_tv_the_position_has_muted, index + 1);
        } else {
            msgEntity.content = getString(R.string.trtckaraoke_tv_the_position_has_unmuted, index + 1);
        }
        showImMsg(msgEntity);
        KaraokeRoomSeatEntity seatEntity = findSeatEntityFromUserId(index);
        if (seatEntity == null) {
            return;
        }
        if (index == mSelfSeatIndex) {
            if (isMute) {
                mTRTCKaraokeRoom.muteLocalAudio(true);
                updateMuteStatusView(mSelfUserId, true);
            } else if (!seatEntity.isUserMute) {
                mTRTCKaraokeRoom.muteLocalAudio(false);
                updateMuteStatusView(mSelfUserId, false);
            }
        }
    }

    @Override
    public void onSeatClose(int index, boolean isClose) {
        MsgEntity msgEntity = new MsgEntity();
        msgEntity.type = MsgEntity.TYPE_NORMAL;
        msgEntity.content = isClose ? getString(R.string.trtckaraoke_tv_the_owner_ban_this_position, index + 1) :
                getString(R.string.trtckaraoke_tv_the_owner_not_ban_this_position, index + 1);
        showImMsg(msgEntity);
    }

    @Override
    public void onUserMicrophoneMute(String userId, boolean mute) {
        Log.d(TAG, "onUserMicrophoneMute userId:" + userId + " mute:" + mute);
        mSeatUserMuteMap.put(userId, mute);
        updateMuteStatusView(userId, mute);
    }

    private void updateMuteStatusView(String userId, boolean mute) {
        if (userId == null) {
            return;
        }

        KaraokeRoomSeatEntity seatEntity = findSeatEntityFromUserId(userId);
        if (seatEntity != null) {
            if (!seatEntity.isSeatMute && mute != seatEntity.isUserMute) {
                seatEntity.isUserMute = mute;
                mKaraokeRoomSeatAdapter.notifyItemChanged(mKaraokeRoomSeatEntityList.indexOf(seatEntity),
                        KaraokeRoomSeatAdapter.MUTE);
            }
        }

        if (userId.equals(mSelfUserId)) {
            mBtnMic.setSelected(!mute);
        }
    }

    private KaraokeRoomSeatEntity findSeatEntityFromUserId(String userId) {
        if (mKaraokeRoomSeatEntityList != null) {
            for (KaraokeRoomSeatEntity seatEntity : mKaraokeRoomSeatEntityList) {
                if (userId.equals(seatEntity.userId)) {
                    return seatEntity;
                }
            }
        }
        return null;
    }

    private KaraokeRoomSeatEntity findSeatEntityFromUserId(int index) {
        if (index == -1) {
            return null;
        }
        if (mKaraokeRoomSeatEntityList != null) {
            for (KaraokeRoomSeatEntity seatEntity : mKaraokeRoomSeatEntityList) {
                if (index == seatEntity.index) {
                    return seatEntity;
                }
            }
        }
        return null;
    }

    //下麦
    public void leaveSeat() {
        if (mRoomInfoController.isRoomOwner()) {
            return;
        }
        if (mAlertDialog == null) {
            mAlertDialog = new ConfirmDialogFragment();
        }
        if (mAlertDialog.isAdded()) {
            mAlertDialog.dismiss();
        }
        if (lastClickTime > 0) {
            long current = System.currentTimeMillis();
            if (current - lastClickTime < 300) {
                return;
            }
        }
        lastClickTime = System.currentTimeMillis();
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
    public void onAudienceEnter(TRTCKaraokeRoomDef.UserInfo userInfo) {
        Log.d(TAG, "onAudienceEnter userInfo:" + userInfo);
        MsgEntity msgEntity = new MsgEntity();
        msgEntity.type = MsgEntity.TYPE_NORMAL;
        msgEntity.content = getString(R.string.trtckaraoke_tv_enter_room, "");
        msgEntity.userName = userInfo.userName;
        showImMsg(msgEntity);
        if (userInfo.userId.equals(mSelfUserId)) {
            return;
        }
        AudienceEntity entity = new AudienceEntity();
        entity.userId = userInfo.userId;
        entity.userAvatar = userInfo.userAvatar;
        mAudienceListAdapter.addMember(entity);
    }

    @Override
    public void onAudienceExit(TRTCKaraokeRoomDef.UserInfo userInfo) {
        Log.d(TAG, "onAudienceExit userInfo:" + userInfo);
        MsgEntity msgEntity = new MsgEntity();
        msgEntity.type = MsgEntity.TYPE_NORMAL;
        msgEntity.userName = userInfo.userName;
        msgEntity.content = getString(R.string.trtckaraoke_tv_exit_room, "");
        showImMsg(msgEntity);
        mAudienceListAdapter.removeMember(userInfo.userId);
    }

    @Override
    public void onUserVolumeUpdate(List<TRTCCloudDef.TRTCVolumeInfo> userVolumes, int totalVolume) {
        for (TRTCCloudDef.TRTCVolumeInfo info : userVolumes) {
            if (info != null) {
                int volume = info.volume;
                KaraokeRoomSeatEntity entity = findSeatEntityFromUserId(info.userId);
                if (entity != null) {
                    boolean isTalk = volume > 20;
                    if (isTalk != entity.isTalk) {
                        entity.isTalk = isTalk;
                        mKaraokeRoomSeatAdapter.notifyItemChanged(mKaraokeRoomSeatEntityList.indexOf(entity),
                                KaraokeRoomSeatAdapter.VOLUTE);
                    }
                }
            }
        }
    }

    @Override
    public void onRecvRoomTextMsg(String message, TRTCKaraokeRoomDef.UserInfo userInfo) {
        MsgEntity msgEntity = new MsgEntity();
        msgEntity.userId = userInfo.userId;
        msgEntity.userName = userInfo.userName;
        msgEntity.content = message;
        msgEntity.type = MsgEntity.TYPE_NORMAL;
        msgEntity.isChat = true;
        showImMsg(msgEntity);
    }

    @Override
    public void onRecvRoomCustomMsg(String cmd, String message, TRTCKaraokeRoomDef.UserInfo userInfo) {
        int type = Integer.parseInt(cmd);
        switch (type) {
            case TCConstants.IMCMD_GIFT:
                handleGiftMsg(userInfo, message);
                break;
            default:
                break;
        }
    }

    @Override
    public void onReceiveNewInvitation(String id, String inviter, String cmd, String content) {

    }

    @Override
    public void onInviteeAccepted(String id, String invitee) {

    }

    @Override
    public void onInviteeRejected(String id, String invitee) {

    }

    @Override
    public void onInvitationCancelled(String id, String invitee) {

    }

    @Override
    public void onAgreeClick(int position) {

    }

    @Override
    public void onOrderedManagerClick(int position) {

    }

    @Override
    public void onMusicProgressUpdate(String musicID, long progress, long total) {
        KaraokeMusicModel topModel = mRoomInfoController.getTopModel();
        if (topModel == null || musicID == null) {
            return;
        }
        //断网后重新联网,需要获取新的列表,更新歌词信息
        //回调传上来的musicId实际是performId
        if (!musicID.equals(topModel.performId)) {
            mKaraokeMusicService.ktvGetSelectedMusicList(new KaraokeMusicCallback.MusicSelectedListCallback() {
                @Override
                public void onCallback(int code, String msg, List<KaraokeMusicModel> list) {
                    Log.d(TAG, "update list code = " + code + " , msg = " + msg);
                }
            });
        }
        //收到歌曲进度的回调后,更新歌词显示进度
        seekLrcToTime(progress);
    }

    @Override
    public void onMusicPrepareToPlay(String musicID) {
        TRTCLogger.i(TAG, "onMusicPrepareToPlay: musicId = " + musicID);
        mKaraokeAudioViewModel.setCurrentStatus(KaraokeAudioViewModel.MUSIC_PLAYING);
        mKaraokeMusicService.prepareToPlay(musicID);
    }

    @Override
    public void onMusicCompletePlaying(String musicID) {
        TRTCLogger.i(TAG, "onMusicCompletePlaying: musicId = " + musicID);
        mKaraokeAudioViewModel.setCurrentStatus(KaraokeAudioViewModel.MUSIC_STOP);
        if (mRoomInfoController.isRoomOwner()) {
            mKaraokeMusicService.completePlaying(musicID);
        }
        //隐藏倒计时
        mKTVMusicView.hideStartAnim();
    }

    @Override
    public void onReceiveAnchorSendChorusMsg(String perFormId) {
        if (!mRoomInfoController.isAnchor()) {
            return;
        }
        KaraokeMusicModel musicModel = mKaraokeMusicService.getCurrentPlayMusicModel();
        if (musicModel == null) {
            return;
        }
        if (!musicModel.isReady) {
            TRTCLogger.e(TAG, "music info is not ready");
            return;
        }
        if (!TextUtils.isEmpty(perFormId) && perFormId.equals(musicModel.performId)) {
            setLrcPath(musicModel.lrcUrl);
            mKaraokeAudioViewModel.startPlayMusic(musicModel);
        }
    }

    protected void getAudienceList() {
        mTRTCKaraokeRoom.getUserInfoList(null, new TRTCKaraokeRoomCallback.UserListCallback() {
            @Override
            public void onCallback(int code, String msg, List<TRTCKaraokeRoomDef.UserInfo> list) {
                if (code == 0) {
                    Log.d(TAG, "getAudienceList list size:" + list.size());
                    for (TRTCKaraokeRoomDef.UserInfo userInfo : list) {
                        Log.d(TAG, "getAudienceList userInfo:" + userInfo);
                        if (!mSeatUserMuteMap.containsKey(userInfo.userId)) {
                            AudienceEntity audienceEntity = new AudienceEntity();
                            audienceEntity.userAvatar = userInfo.userAvatar;
                            audienceEntity.userId = userInfo.userId;
                            mAudienceListAdapter.addMember(audienceEntity);
                        }
                        if (userInfo.userId.equals(mSelfUserId)) {
                            continue;
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
                }
            }
        });
    }

    protected int changeSeatIndexToModelIndex(int srcSeatIndex) {
        return srcSeatIndex;
    }

    protected void showImMsg(final MsgEntity entity) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mMsgEntityList.size() > 1000) {
                    while (mMsgEntityList.size() > 900) {
                        mMsgEntityList.remove(0);
                    }
                }
                if (!TextUtils.isEmpty(entity.userName)) {
                    if (mMessageColorIndex >= MESSAGE_USERNAME_COLOR_ARR.length) {
                        mMessageColorIndex = 0;
                    }
                    int color = MESSAGE_USERNAME_COLOR_ARR[mMessageColorIndex];
                    entity.color = getResources().getColor(color);
                    mMessageColorIndex++;
                }

                //判断当前消息类型是申请上麦消息
                if (entity != null && entity.type == MsgEntity.TYPE_WAIT_AGREE) {
                    //判断当前消息是同一个用户发出
                    if (mLastMsgUserId != null && mLastMsgUserId.equals(entity.userId)) {
                        for (MsgEntity temp : mMsgEntityList) {
                            if (temp != null && mLastMsgUserId.equals(temp.userId)) {
                                temp.type = MsgEntity.TYPE_AGREED;
                            }
                        }
                    }
                }
                mLastMsgUserId = entity.userId;
                mMsgEntityList.add(entity);
                mMsgListAdapter.notifyDataSetChanged();
                mRvImMsg.smoothScrollToPosition(mMsgListAdapter.getItemCount());
            }
        });
    }

    @Override
    protected void onDestroy() {
        mIsDestroyed = true;
        UserModelManager.getInstance().getUserModel().userType = UserModel.UserType.NONE;
        super.onDestroy();
        mLrcView.release();
    }

    private void initLoadLyricsView(final String path) {
        mLrcView.initLrcData();
        mLrcView.setLrcStatus(AbstractLrcView.LRCSTATUS_LOADING);
        final LyricsReader lyricsReader = new LyricsReader();
        if (path == null) {
            mLrcView.setLyricsReader(null);
        } else {
            new LrcAsyncTask(path, lyricsReader).execute();
        }
    }

    class LrcAsyncTask extends AsyncTask {
        private String       mPath;
        private LyricsReader mLyricsReader;

        public LrcAsyncTask(String path, LyricsReader lyricsReader) {
            mPath = path;
            this.mLyricsReader = lyricsReader;
        }

        @Override
        protected Object doInBackground(Object[] objects) {
            if (mIsDestroyed) {
                return null;
            }
            try {
                File file = new File(mPath);
                mLyricsReader.loadLrc(file);
            } catch (Exception e) {
                e.printStackTrace();
            }
            return null;
        }

        @Override
        protected void onPostExecute(Object o) {
            if (mIsDestroyed) {
                return;
            }
            mLrcView.setLyricsReader(mLyricsReader);
        }
    }

    @Override
    public void setLrcPath(String path) {
        TRTCLogger.i(TAG, "setLrcPath: path = " + path);
        if (mLrcView == null) {
            return;
        }
        initLoadLyricsView(path);
    }

    @Override
    public void seekLrcToTime(long time) {
        mLrcView.play(time);
    }
}
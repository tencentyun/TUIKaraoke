package com.tencent.liteav.tuikaraoke.ui.room;

import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_ADD_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_DELETE_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_LYRICS_PATH_KEY;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_INFO_KEY;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_UPDATE_LYRICS_PATH_EVENT;

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

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.AppCompatImageButton;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.tencent.liteav.basic.ImageLoader;
import com.tencent.liteav.basic.UserModel;
import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicServiceObserver;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoom;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef.UserInfo;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomObserver;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.ui.audio.impl.KaraokeAudioViewModel;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;
import com.tencent.liteav.tuikaraoke.ui.gift.GiftAdapter;
import com.tencent.liteav.tuikaraoke.ui.gift.GiftPanelDelegate;
import com.tencent.liteav.tuikaraoke.ui.gift.IGiftPanelView;
import com.tencent.liteav.tuikaraoke.ui.gift.imp.DefaultGiftAdapterImp;
import com.tencent.liteav.tuikaraoke.ui.gift.imp.GiftAnimatorLayout;
import com.tencent.liteav.tuikaraoke.ui.gift.imp.GiftInfo;
import com.tencent.liteav.tuikaraoke.ui.gift.imp.GiftInfoDataHandler;
import com.tencent.liteav.tuikaraoke.ui.gift.imp.GiftPanelViewImp;
import com.tencent.liteav.tuikaraoke.ui.lyric.LyricView;
import com.tencent.liteav.tuikaraoke.ui.lyric.LyricsFileReader;
import com.tencent.liteav.tuikaraoke.ui.lyric.model.LyricInfo;
import com.tencent.liteav.tuikaraoke.ui.music.impl.KaraokeMusicView;
import com.tencent.liteav.tuikaraoke.ui.utils.Constants;
import com.tencent.liteav.tuikaraoke.ui.utils.PermissionHelper;
import com.tencent.liteav.tuikaraoke.ui.utils.Toast;
import com.tencent.liteav.tuikaraoke.ui.utils.Utils;
import com.tencent.liteav.tuikaraoke.ui.widget.ConfirmDialogFragment;
import com.tencent.liteav.tuikaraoke.ui.widget.InputTextMsgDialog;
import com.tencent.liteav.tuikaraoke.ui.widget.msg.AudienceEntity;
import com.tencent.liteav.tuikaraoke.ui.widget.msg.MessageEntity;
import com.tencent.liteav.tuikaraoke.ui.widget.msg.MessageListAdapter;
import com.tencent.qcloud.tuicore.TUICore;
import com.tencent.qcloud.tuicore.interfaces.ITUINotification;
import com.tencent.qcloud.tuicore.interfaces.TUICallback;
import com.tencent.qcloud.tuicore.interfaces.TUIValueCallback;
import com.tencent.trtc.TRTCCloudDef;
import com.tencent.trtc.TRTCStatistics;

import java.lang.reflect.Constructor;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import de.hdodenhof.circleimageview.CircleImageView;

public class KaraokeRoomBaseActivity extends AppCompatActivity implements KaraokeRoomSeatAdapter.OnItemClickListener,
        TRTCKaraokeRoomObserver,
        InputTextMsgDialog.OnTextSendListener,
        MessageListAdapter.OnItemClickListener {
    protected static final String TAG = "KaraokeRoomBaseActivity";

    protected static final int    MAX_SEAT_SIZE        = 8;
    protected static final String KTVROOM_ROOM_ID      = "room_id";
    protected static final String KTVROOM_ROOM_NAME    = "room_name";
    protected static final String KTVROOM_OWNER_ID     = "owner_id";
    protected static final String KTVROOM_USER_NAME    = "user_name";
    protected static final String KTVROOM_USER_ID      = "user_id";
    protected static final String KTVROOM_NEED_REQUEST = "need_request";
    protected static final String KTVROOM_USER_AVATAR  = "user_avatar";
    protected static final String KTVROOM_ROOM_COVER   = "room_cover";

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
    protected KaraokeDashboardDialog      mKaraokeDashboardDialog;

    protected KaraokeAudioViewModel      mKaraokeAudioViewModel;
    protected InputTextMsgDialog         mInputTextMsgDialog;
    protected int                        mRoomId;
    protected String                     mRoomName;
    protected String                     mUserName;
    protected String                     mRoomCover;
    protected String                     mUserAvatar;
    protected CircleImageView            mImgRoom;
    protected boolean                    mNeedRequest;
    protected List<MessageEntity>        mMsgEntityList;
    protected MessageListAdapter         mMessageListAdapter;
    protected ConfirmDialogFragment      mConfirmDialogFragment;
    protected Map<String, UserInfo>      mMemberInfoMap;
    protected ConfirmDialogFragment      mUpdateNetworkSyncFailDialog;

    private Context mContext;
    private String  mLastMsgUserId = null;
    private int     mMessageColorIndex;
    private int     mRvAudienceScrollPosition;
    private int     mSelfSeatIndex = -1;
    private long    lastClickTime  = -1;

    //礼物
    private GiftInfoDataHandler mGiftInfoDataHandler;
    private GiftAnimatorLayout  mGiftAnimatorLayout;

    private   LyricView           mLrcView;
    public    KaraokeMusicService mKaraokeMusicService;
    private   String              mRoomDefaultCover =
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover1.png";
    private   boolean             mIsDestroyed;
    private   String              mPackageName      = "com.tencent.liteav.tuikaraoke.model.impl.music"
            + ".KaraokeMusicServiceImpl";
    public    RoomInfoController  mRoomInfoController;
    protected boolean             mUpdateNetworkSuccessed;

    private boolean               mHasCheckedHeadset;

    private ITUINotification mUpdateLyricsPathNotification = new ITUINotification() {
        @Override
        public void onNotifyEvent(String key, String subKey, Map<String, Object> param) {
            if (param == null || !param.containsKey(KARAOKE_LYRICS_PATH_KEY)) {
                return;
            }
            String url = (String) param.get(KARAOKE_LYRICS_PATH_KEY);
            setLrcPath(url);
        }
    };

    private final ITUINotification mAddMusicNotification = new ITUINotification() {
        @Override
        public void onNotifyEvent(String key, String subKey, Map<String, Object> param) {
            if (param == null || !param.containsKey(KARAOKE_MUSIC_INFO_KEY)) {
                return;
            }
            KaraokeMusicInfo musicInfo = (KaraokeMusicInfo) param.get(KARAOKE_MUSIC_INFO_KEY);
            // 更新主播自己的消息列表
            updateMessageList(musicInfo);
            // 发自定义点歌消息通知其他人
            sendSelectMusicMessage(musicInfo.userId, musicInfo.musicName);
        }
    };


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mContext = this;
        mHasCheckedHeadset = false;
        UserModelManager.getInstance().getUserModel().userType = UserModel.UserType.KARAOKE;
        // 应用运行时，保持不锁屏、全屏化
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.trtckaraoke_activity_main);
        initStatusBar();
        initView();
        initData();
        initListener();
        MessageEntity msgEntity = new MessageEntity();
        msgEntity.type = MessageEntity.TYPE_WELCOME;
        msgEntity.content = getString(R.string.trtckaraoke_welcome_visit);
        msgEntity.linkUrl = getString(R.string.trtckaraoke_welcome_visit_link);
        showImMsg(msgEntity);
    }

    // 通过反射创建歌曲管理实现类的实例
    public void createKTVMusicService(TRTCKaraokeRoomDef.RoomInfo roomInfo) {
        if (mKaraokeMusicService != null) {
            return;
        }
        try {
            Class clz = Class.forName(mPackageName);
            Constructor constructor = clz.getConstructor(Context.class, TRTCKaraokeRoomDef.RoomInfo.class);
            mKaraokeMusicService = (KaraokeMusicService) constructor.newInstance(this, roomInfo);
        } catch (Exception e) {
            e.printStackTrace();
        }
        initSelectedMusicMap();
    }

    private void initSelectedMusicMap() {
        if (mKaraokeMusicService == null) {
            return;
        }
        //时序问题：KaraokeMusicView需要监听KaraokeMusicService的歌曲列表更新，所以要提前调用
        mRoomInfoController.setMusicImpl(mKaraokeMusicService);
        mKTVMusicView.init(mRoomInfoController, mKaraokeAudioViewModel);
        mKaraokeMusicService.addObserver(new KaraokeMusicServiceObserver() {
            @Override
            public void onMusicListChanged(List<KaraokeMusicInfo> musicInfoList) {
                //刷新歌单
                Map<String, KaraokeMusicInfo> map = mRoomInfoController.getUserSelectMap();
                map.clear();
                for (KaraokeMusicInfo info : musicInfoList) {
                    map.put(info.musicId, info);
                }
            }
        });
        //点歌列表只在首次读一下
        mKaraokeMusicService.getPlaylist(null);
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
        mKaraokeDashboardDialog = new KaraokeDashboardDialog(mContext);

        mRvSeat = (RecyclerView) findViewById(R.id.rv_seat);
        mRvImMsg = (RecyclerView) findViewById(R.id.rv_im_msg);

        mBtnMsg = (AppCompatImageButton) findViewById(R.id.btn_msg);
        mBtnMic = (AppCompatImageButton) findViewById(R.id.btn_mic);
        mBtnGift = (AppCompatImageButton) findViewById(R.id.btn_more_gift);
        mBtnReport = (AppCompatImageButton) findViewById(R.id.btn_report);

        mInputTextMsgDialog = new InputTextMsgDialog(this, R.style.TRTCKTVRoomInputDialog);
        mInputTextMsgDialog.setOnTextSendListener(this);
        mMsgEntityList = new ArrayList<>();
        mMemberInfoMap = new HashMap<>();

        mBtnExitRoom.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                checkingBeforeExitRoom();
            }
        });
        mMessageListAdapter = new MessageListAdapter(this, mMsgEntityList, this);
        mRvImMsg.setLayoutManager(new LinearLayoutManager(this));
        mRvImMsg.setAdapter(mMessageListAdapter);
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
        mAudienceListAdapter = new AudienceListAdapter(this, new LinkedList<>());
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
        // 设置高亮字体大小
        mLrcView.setHighLightTextSizeSp(20);
        // 设置默认字体大小
        mLrcView.setDefaultTextSizeSp(14);
        //（底部）点歌
        findViewById(R.id.container_choose_song).setOnClickListener(v -> {
            // 房主才能点歌
            if (mRoomInfoController.isRoomOwner()) {
                mKTVMusicView.showMusicDialog(true);
            } else {
                Toast.show(R.string.trtckaraoke_toast_room_owner_can_operate_it, Toast.LENGTH_LONG);
            }
        });
    }

    @Override
    public void onBackPressed() {
        checkingBeforeExitRoom();
    }

    protected void checkingBeforeExitRoom() {
    }

    protected void initData() {
        Intent intent = getIntent();
        mRoomId = intent.getIntExtra(KTVROOM_ROOM_ID, 0);
        mRoomName = intent.getStringExtra(KTVROOM_ROOM_NAME);
        mUserName = intent.getStringExtra(KTVROOM_USER_NAME);
        mSelfUserId = intent.getStringExtra(KTVROOM_USER_ID);
        mNeedRequest = intent.getBooleanExtra(KTVROOM_NEED_REQUEST, true);
        mUserAvatar = intent.getStringExtra(KTVROOM_USER_AVATAR);
        mRoomCover = intent.getStringExtra(KTVROOM_ROOM_COVER);
        if (mRoomCover == null) {
            ImageLoader.loadImage(this, mImgRoom, mRoomDefaultCover);
        } else {
            ImageLoader.loadImage(this, mImgRoom, mRoomCover, R.drawable.trtckaraoke_ic_cover);
        }

        findViewById(R.id.ll_anchor_info).setOnLongClickListener(new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View view) {
                if (mKaraokeDashboardDialog.isShowing()) {
                    mKaraokeDashboardDialog.dismiss();
                } else {
                    mKaraokeDashboardDialog.setSelfUserId(mSelfUserId);
                    mKaraokeDashboardDialog.show();
                }
                return false;
            }
        });
        UserModel userModel = UserModelManager.getInstance().getUserModel();

        mTRTCKaraokeRoom = TRTCKaraokeRoom.sharedInstance(this);
        mTRTCKaraokeRoom.login(userModel.appId, userModel.userId, userModel.userSig,
                new TUICallback() {
                    @Override
                    public void onSuccess() {
                        mTRTCKaraokeRoom.setSelfProfile(userModel.userName, userModel.userAvatar, null);
                    }

                    @Override
                    public void onError(int errorCode, String errorMessage) {
                        String info = "login failed[" + errorCode + "]:" + errorMessage;
                        TRTCLogger.e(TAG, info);
                    }
                });

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
        TUICore.registerEvent(KARAOKE_MUSIC_EVENT, KARAOKE_UPDATE_LYRICS_PATH_EVENT, mUpdateLyricsPathNotification);
        TUICore.registerEvent(KARAOKE_MUSIC_EVENT, KARAOKE_ADD_MUSIC_EVENT, mAddMusicNotification);
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
                    Toast.show(getString(R.string.trtckaraoke_toast_you_have_turned_on_the_microphone),
                            Toast.LENGTH_LONG);
                } else {
                    Toast.show(getString(R.string.trtckaraoke_seat_already_mute), Toast.LENGTH_LONG);
                }
            } else {
                mTRTCKaraokeRoom.muteLocalAudio(true);
                updateMuteStatusView(mSelfUserId, true);
                Toast.show(getString(R.string.trtckaraoke_toast_you_have_turned_off_the_microphone), Toast.LENGTH_LONG);
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
            Toast.show(getString(R.string.trtckaraoke_toast_anchor_can_only_operate_it), Toast.LENGTH_LONG);
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
                sendGiftMessage(giftInfo);
            }

            @Override
            public void onChargeClick() {

            }
        });
        giftPanelView.show();
    }

    //发送礼物消息出去同时展示礼物动画和弹幕
    private void sendGiftMessage(GiftInfo giftInfo) {
        GiftInfo giftInfoCopy = giftInfo.copy();
        giftInfoCopy.sendUser = mContext.getString(R.string.trtckaraoke_me);
        giftInfoCopy.sendUserHeadIcon = UserModelManager.getInstance().getUserModel().userAvatar;
        mGiftAnimatorLayout.show(giftInfoCopy);

        GiftSendJson jsonData = new GiftSendJson();
        jsonData.setSendUser(UserModelManager.getInstance().getUserModel().userName);
        jsonData.setSendUserHeadIcon(UserModelManager.getInstance().getUserModel().userAvatar);
        jsonData.setGiftId(giftInfo.giftId);
        Gson gson = new Gson();

        mTRTCKaraokeRoom.sendRoomCustomMsg(Constants.IMCMD_GIFT,
                gson.toJson(jsonData), new TUICallback() {
                    @Override
                    public void onSuccess() {

                    }

                    @Override
                    public void onError(int errorCode, String errorMessage) {
                        Toast.show(R.string.trtckaraoke_toast_sent_message_failure, Toast.LENGTH_SHORT);
                    }
                });
    }

    /**
     * 处理礼物弹幕消息
     */
    private void handleGiftMessage(UserInfo userInfo, String data) {
        if (mGiftInfoDataHandler != null) {
            Gson gson = new Gson();
            GiftSendJson jsonData = gson.fromJson(data, GiftSendJson.class);
            String giftId = jsonData.getGiftId();
            GiftInfo giftInfo = mGiftInfoDataHandler.getGiftInfo(giftId);
            if (giftInfo != null) {
                if (userInfo != null) {
                    giftInfo.sendUserHeadIcon = userInfo.avatarURL;
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

    private void sendSelectMusicMessage(String userId, String musicName) {
        if (TextUtils.isEmpty(userId) || TextUtils.isEmpty(musicName)) {
            return;
        }
        Map<String, String> map = new HashMap<>();
        map.put(Constants.IMMSG_KEY_USER_ID, userId);
        map.put(Constants.IMMSG_KEY_MUSIC_NAME, musicName);
        Gson gson = new Gson();
        mTRTCKaraokeRoom.sendRoomCustomMsg(Constants.IMCMD_SELECTED_MUSIC,
                gson.toJson(map), new TUICallback() {
                    @Override
                    public void onSuccess() {

                    }

                    @Override
                    public void onError(int errorCode, String errorMessage) {
                        Toast.show(R.string.trtckaraoke_toast_sent_message_failure, Toast.LENGTH_SHORT);
                    }
                });
    }

    private void handleSelectMusicMessage(UserInfo userInfo, String data) {
        if (TextUtils.isEmpty(data)) {
            return;
        }
        Gson gson = new Gson();
        Map<String, String> map = gson.fromJson(data, new TypeToken<Map<String, String>>(){}.getType());
        String userId = map.get(Constants.IMMSG_KEY_USER_ID);
        String musicName = map.get(Constants.IMMSG_KEY_MUSIC_NAME);
        if (TextUtils.isEmpty(userId) || TextUtils.isEmpty(musicName)) {
            return;
        }
        KaraokeMusicInfo musicInfo = new KaraokeMusicInfo();
        musicInfo.userId = userId;
        musicInfo.musicName = musicName;
        updateMessageList(musicInfo);
    }

    public void refreshView() {
        if (mCurrentRole == TRTCCloudDef.TRTCRoleAnchor) {
            mBtnMic.setVisibility(View.VISIBLE);
            mBtnMic.setActivated(true);
            mBtnMic.setSelected(true);
        } else {
            mBtnMic.setVisibility(View.GONE);
        }
        mKTVMusicView.updateView();
    }

    /**
     * 网络质量监听
     *
     * @param localQuality  上行网络质量。
     * @param remoteQuality 下行网络质量。
     */

    @Override
    public void onNetworkQuality(TRTCCloudDef.TRTCQuality localQuality, List<TRTCCloudDef.TRTCQuality> remoteQuality) {
        // local
        KaraokeRoomSeatEntity localUserSeatEntity = findSeatEntityFromUserId(mSelfUserId);
        matchQuality(localQuality, localUserSeatEntity);
        if (localUserSeatEntity != null
                && localUserSeatEntity.isUsed
                && localQuality.quality >= TRTCCloudDef.TRTC_QUALITY_Poor) {
            Toast.show(R.string.trtckaraoke_toast_supported_chorus_with_poor_network, Toast.LENGTH_SHORT);
        }

        // remote
        for (TRTCCloudDef.TRTCQuality quality : remoteQuality) {
            matchQuality(quality, findSeatEntityFromUserId(quality.userId));
        }
    }

    private void matchQuality(TRTCCloudDef.TRTCQuality trtcQuality, KaraokeRoomSeatEntity entity) {
        if (entity == null || entity.isClose || !entity.isUsed) {
            return;
        }
        int oldQuality = entity.getQuality();
        switch (trtcQuality.quality) {
            case TRTCCloudDef.TRTC_QUALITY_Excellent:
            case TRTCCloudDef.TRTC_QUALITY_Good:
                entity.setQuality(KaraokeRoomSeatEntity.QUALITY_GOOD);
                break;
            case TRTCCloudDef.TRTC_QUALITY_Bad:
            case TRTCCloudDef.TRTC_QUALITY_Vbad:
                entity.setQuality(KaraokeRoomSeatEntity.QUALITY_BAD);
                break;
            case TRTCCloudDef.TRTC_QUALITY_Down:
                entity.setQuality(KaraokeRoomSeatEntity.QUALITY_NONE);
                break;
            case TRTCCloudDef.TRTC_QUALITY_Poor:
            default:
                entity.setQuality(KaraokeRoomSeatEntity.QUALITY_NORMAL);
                break;
        }
        if (oldQuality != entity.getQuality()) {
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
            Toast.show(R.string.trtckaraoke_toast_please_enter_content, Toast.LENGTH_SHORT);
            return;
        }

        //消息回显
        MessageEntity entity = new MessageEntity();
        entity.userName = getString(R.string.trtckaraoke_me);
        entity.content = msg;
        entity.isChat = true;
        entity.userId = mSelfUserId;
        entity.type = MessageEntity.TYPE_NORMAL;
        showImMsg(entity);

        mTRTCKaraokeRoom.sendRoomTextMsg(msg, new TUICallback() {
            @Override
            public void onSuccess() {
                Toast.show(R.string.trtckaraoke_toast_sent_successfully, Toast.LENGTH_SHORT);
            }

            @Override
            public void onError(int errorCode, String errorMessage) {
                Toast.show(R.string.trtckaraoke_toast_sent_message_failure, Toast.LENGTH_SHORT);
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
        mNeedRequest = roomInfo.needRequest == 1 ? true : false;
        mRoomName = roomInfo.roomName;
        mTvRoomName.setText(roomInfo.roomName);
        mTvRoomId.setText(getString(R.string.trtckaraoke_room_id, roomInfo.roomId));
    }

    @Override
    public void onSeatListChange(List<TRTCKaraokeRoomDef.SeatInfo> seatInfoList) {
        if (seatInfoList == null || seatInfoList.size() != mKaraokeRoomSeatEntityList.size()) {
            return;
        }
        List<String> userIds = new ArrayList<>();
        for (int i = 0; i < seatInfoList.size(); i++) {
            TRTCKaraokeRoomDef.SeatInfo newSeatInfo = seatInfoList.get(i);
            KaraokeRoomSeatEntity oldSeatEntity = mKaraokeRoomSeatEntityList.get(i);
            if (!TextUtils.isEmpty(newSeatInfo.user) && !newSeatInfo.user.equals(oldSeatEntity.userId)) {
                //userId相同，可以不用重新获取信息了
                //但是如果有新的userId进来，那么应该去拿一下主播的详细信息
                userIds.add(newSeatInfo.user);
            }
            oldSeatEntity.userId = newSeatInfo.user;
            switch (newSeatInfo.status) {
                case TRTCKaraokeRoomDef.SeatInfo.STATUS_UNUSED:
                    oldSeatEntity.isUsed = false;
                    oldSeatEntity.isClose = false;
                    break;
                case TRTCKaraokeRoomDef.SeatInfo.STATUS_CLOSE:
                    oldSeatEntity.isUsed = false;
                    oldSeatEntity.isClose = true;
                    break;
                case TRTCKaraokeRoomDef.SeatInfo.STATUS_USED:
                    oldSeatEntity.isUsed = true;
                    oldSeatEntity.isClose = false;
                    break;
                default:
                    break;
            }
            oldSeatEntity.isSeatMute = newSeatInfo.mute;
        }
        for (String userId : userIds) {
            if (!mSeatUserMuteMap.containsKey(userId)) {
                mSeatUserMuteMap.put(userId, true);
            }
        }

        mTRTCKaraokeRoom.getUserInfoList(userIds, new TUIValueCallback<List<UserInfo>>() {
            @Override
            public void onError(int errorCode, String errorMessage) {
                TRTCLogger.e(TAG, "getUserInfoList, code: " + errorCode + " message: " + errorMessage);
            }

            @Override
            public void onSuccess(List<UserInfo> list) {
                Map<String, UserInfo> map = new HashMap<>();
                for (UserInfo userInfo : list) {
                    map.put(userInfo.userId, userInfo);
                }
                for (int i = 0; i < seatInfoList.size(); i++) {
                    TRTCKaraokeRoomDef.SeatInfo newSeatInfo = seatInfoList.get(i);
                    UserInfo userInfo = map.get(newSeatInfo.user);
                    if (userInfo == null) {
                        continue;
                    }
                    boolean isUserMute = mSeatUserMuteMap.get(userInfo.userId);
                    // 接下来是座位区域的列表
                    KaraokeRoomSeatEntity seatEntity = mKaraokeRoomSeatEntityList.get(i);
                    if (userInfo.userId.equals(seatEntity.userId)) {
                        seatEntity.userName = userInfo.userName;
                        seatEntity.userAvatar = userInfo.avatarURL;
                        seatEntity.isUserMute = isUserMute;
                    }
                }
                mKaraokeRoomSeatAdapter.notifyDataSetChanged();
                if (userIds.isEmpty() && !isInitSeat) {
                    //首次回调onSeatListChange时无人上麦，userIds必然是空，此时list就是观众表
                    isInitSeat = true;
                    updateAudienceList(list);
                }
            }
        });
        mRoomInfoController.setRoomSeatEntityList(mKaraokeRoomSeatEntityList);
    }

    private void updateAudienceList(List<UserInfo> list) {
        if (list == null || list.isEmpty()) {
            return;
        }
        for (UserInfo userInfo : list) {
            Log.d(TAG, "updateAudienceList userInfo:" + userInfo);
            if (!mSeatUserMuteMap.containsKey(userInfo.userId)) {
                AudienceEntity audienceEntity = new AudienceEntity();
                audienceEntity.userAvatar = userInfo.avatarURL;
                audienceEntity.userId = userInfo.userId;
                mAudienceListAdapter.addMember(audienceEntity);
            }
            if (userInfo.userId.equals(mSelfUserId)) {
                continue;
            }
            if (!mMemberInfoMap.containsKey(userInfo.userId)) {
                mMemberInfoMap.put(userInfo.userId, userInfo);
            }
        }
    }

    @Override
    public void onAnchorEnterSeat(int index, UserInfo user) {
        Log.d(TAG, "onAnchorEnterSeat userInfo:" + user);
        MessageEntity msgEntity = new MessageEntity();
        msgEntity.type = MessageEntity.TYPE_NORMAL;
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
    public void onAnchorLeaveSeat(int index, UserInfo user) {
        Log.d(TAG, "onAnchorLeaveSeat userInfo:" + user);
        MessageEntity msgEntity = new MessageEntity();
        msgEntity.type = MessageEntity.TYPE_NORMAL;
        msgEntity.userName = user.userName;
        msgEntity.content = getString(R.string.trtckaraoke_tv_offline_no_name, index + 1);
        showImMsg(msgEntity);
        AudienceEntity entity = new AudienceEntity();
        entity.userId = user.userId;
        entity.userAvatar = user.avatarURL;
        mAudienceListAdapter.addMember(entity);
        if (user.userId.equals(mSelfUserId)) {
            mCurrentRole = TRTCCloudDef.TRTCRoleAudience;
            mSelfSeatIndex = -1;
            refreshView();
            if (mRoomInfoController.isRoomOwner()) {
                if (mKaraokeMusicService != null) {
                    mKaraokeMusicService.clearPlaylistByUserId(mSelfUserId, null);
                }
            }
            mKaraokeAudioViewModel.stopPlayMusic(null);
            mKaraokeAudioViewModel.setCurrentStatus(KaraokeAudioViewModel.MUSIC_STOP);
        }
    }

    @Override
    public void onSeatMute(int index, boolean isMute) {
        MessageEntity msgEntity = new MessageEntity();
        msgEntity.type = MessageEntity.TYPE_NORMAL;
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
        MessageEntity msgEntity = new MessageEntity();
        msgEntity.type = MessageEntity.TYPE_NORMAL;
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

        ConfirmDialogFragment dialogFragment = new ConfirmDialogFragment();
        if (dialogFragment.isAdded()) {
            dialogFragment.dismiss();
        }
        if (lastClickTime > 0) {
            long current = System.currentTimeMillis();
            if (current - lastClickTime < 300) {
                return;
            }
        }
        lastClickTime = System.currentTimeMillis();
        dialogFragment.setMessage(getString(R.string.trtckaraoke_leave_seat_ask));
        dialogFragment.setPositiveClickListener(new ConfirmDialogFragment.PositiveClickListener() {
            @Override
            public void onClick() {
                mTRTCKaraokeRoom.leaveSeat(new TUICallback() {
                    @Override
                    public void onSuccess() {
                        Toast.show(R.string.trtckaraoke_toast_offline_successfully, Toast.LENGTH_SHORT);
                    }

                    @Override
                    public void onError(int errorCode, String errorMessage) {
                        Toast.show(getString(R.string.trtckaraoke_toast_offline_failure, errorMessage),
                                Toast.LENGTH_SHORT);
                    }
                });
                dialogFragment.dismiss();
            }
        });
        dialogFragment.setNegativeClickListener(new ConfirmDialogFragment.NegativeClickListener() {
            @Override
            public void onClick() {
                dialogFragment.dismiss();
            }
        });
        dialogFragment.show(this.getFragmentManager(), "confirm_leave_seat");
    }

    @Override
    public void onAudienceEnter(UserInfo userInfo) {
        Log.d(TAG, "onAudienceEnter userInfo:" + userInfo);
        MessageEntity msgEntity = new MessageEntity();
        msgEntity.type = MessageEntity.TYPE_NORMAL;
        msgEntity.content = getString(R.string.trtckaraoke_tv_enter_room, "");
        msgEntity.userName = userInfo.userName;
        showImMsg(msgEntity);
        if (userInfo.userId.equals(mSelfUserId)) {
            return;
        }
        AudienceEntity entity = new AudienceEntity();
        entity.userId = userInfo.userId;
        entity.userAvatar = userInfo.avatarURL;
        mAudienceListAdapter.addMember(entity);
    }

    @Override
    public void onAudienceExit(UserInfo userInfo) {
        Log.d(TAG, "onAudienceExit userInfo:" + userInfo);
        MessageEntity msgEntity = new MessageEntity();
        msgEntity.type = MessageEntity.TYPE_NORMAL;
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
        mKaraokeDashboardDialog.updateUserVolume(userVolumes);
    }

    @Override
    public void onStatistics(TRTCStatistics statistics) {
        mKaraokeDashboardDialog.update(statistics);
    }

    @Override
    public void onRecvRoomTextMsg(String message, UserInfo userInfo) {
        MessageEntity msgEntity = new MessageEntity();
        msgEntity.userId = userInfo.userId;
        msgEntity.userName = userInfo.userName;
        msgEntity.content = message;
        msgEntity.type = MessageEntity.TYPE_NORMAL;
        msgEntity.isChat = true;
        showImMsg(msgEntity);
    }

    @Override
    public void onRecvRoomCustomMsg(String cmd, String message, UserInfo userInfo) {
        switch (cmd) {
            case Constants.IMCMD_GIFT:
                handleGiftMessage(userInfo, message);
                break;
            case Constants.IMCMD_SELECTED_MUSIC:
                handleSelectMusicMessage(userInfo, message);
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
        KaraokeMusicInfo topModel = mRoomInfoController.getTopModel();
        if (topModel == null || musicID == null) {
            return;
        }
        //断网后重新联网,需要获取新的列表,更新歌词信息
        //回调传上来的musicId实际是performId
        if (!musicID.equals(topModel.performId)) {
            mKaraokeMusicService.getPlaylist(null);
        }
        //收到歌曲进度的回调后,更新歌词显示进度
        mLrcView.updateLyricsPlayProgress(progress);
        mKTVMusicView.updateMusicPlayingProgress(progress, total);
        if (!mHasCheckedHeadset && !Utils.checkHasHeadset(mContext)) {
            mHasCheckedHeadset = true;
            Toast.show(R.string.trtckaraoke_audio_headset_check_tip, Toast.LENGTH_LONG);
        }
    }

    @Override
    public void onMusicPlayCompleted(String musicID) {
        //警告：这个musicID实际是performId！
        TRTCLogger.i(TAG, "onMusicPlayCompleted: musicId = " + musicID);
        mKaraokeAudioViewModel.setCurrentStatus(KaraokeAudioViewModel.MUSIC_STOP);
        if (mRoomInfoController.isRoomOwner()) {
            for (KaraokeMusicInfo musicInfo : mRoomInfoController.getUserSelectMap().values()) {
                if (TextUtils.equals(musicInfo.performId, musicID)) {
                    Map<String, Object> params = new HashMap<>();
                    params.put(KARAOKE_MUSIC_INFO_KEY, musicInfo);
                    TUICore.notifyEvent(KARAOKE_MUSIC_EVENT, KARAOKE_DELETE_MUSIC_EVENT, params);
                    mKaraokeMusicService.completePlaying(musicInfo);
                    break;
                }
            }
        }
    }

    @Override
    public void onReceiveAnchorSendChorusMsg(String performId) {
        if (!mRoomInfoController.isAnchor()) {
            return;
        }
        KaraokeMusicInfo musicModel = mRoomInfoController.getTopModel();
        if (musicModel == null) {
            return;
        }
        TRTCLogger.e(TAG, "onReceiveAnchorSendChorusMsg music info: " + musicModel
                + " performId: " + performId);
        if (!musicModel.isPreloaded()) {
            return;
        }

        if (!TextUtils.isEmpty(performId) && performId.equals(musicModel.performId)) {
            setLrcPath(musicModel.lrcUrl);
            mKaraokeAudioViewModel.startPlayMusic(musicModel);
        }
    }

    @Override
    public void onMusicAccompanimentModeChanged(int musicId, boolean isOriginal) {
        if (mKTVMusicView != null) {
            mKTVMusicView.updateMusicAccompanimentModeView(isOriginal);
        }
    }

    @Override
    public void onUpdateNetworkTime(int code, String message) {
        if (code == 0) {
            mUpdateNetworkSuccessed = true;
        } else {
            mUpdateNetworkSuccessed = false;
            showNetworkTimeSyncFailDialog();
        }
    }

    public void showNetworkTimeSyncFailDialog() {
        if (mUpdateNetworkSyncFailDialog == null) {
            mUpdateNetworkSyncFailDialog = new ConfirmDialogFragment();
        }
        if (mUpdateNetworkSyncFailDialog.isAdded()) {
            mUpdateNetworkSyncFailDialog.dismiss();
        }
        mUpdateNetworkSyncFailDialog.setMessage(getString(R.string.trtckaraoke_upate_network_time_fail_tips));
        mUpdateNetworkSyncFailDialog.setPositiveButtonText(getString(R.string.trtckaraoke_retry));
        mUpdateNetworkSyncFailDialog.setPositiveClickListener(new ConfirmDialogFragment.PositiveClickListener() {
            @Override
            public void onClick() {
                mTRTCKaraokeRoom.updateNetworkTime();
                mUpdateNetworkSyncFailDialog.dismiss();
            }
        });
        mUpdateNetworkSyncFailDialog.setNegativeClickListener(new ConfirmDialogFragment.NegativeClickListener() {
            @Override
            public void onClick() {
                mUpdateNetworkSyncFailDialog.dismiss();
            }
        });
        mUpdateNetworkSyncFailDialog.show(this.getFragmentManager(), "confirm_try_network_time");
    }

    protected int changeSeatIndexToModelIndex(int srcSeatIndex) {
        return srcSeatIndex;
    }

    private void updateMessageList(KaraokeMusicInfo entity) {
        if (entity == null) {
            Log.d(TAG, "updateMessageList: the entity is not ready");
            return;
        }
        MessageEntity msgEntity = new MessageEntity();
        msgEntity.invitedId = Constants.CMD_ORDER_SONG;
        msgEntity.type = MessageEntity.TYPE_ORDERED_SONG;

        int seatIndex = 0;
        String userName = "";
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
        if (TextUtils.isEmpty(userName)) {
            //还没有收到麦位表回调，获取不到userName
            return;
        }
        msgEntity.userName = userName;
        msgEntity.content = getString(R.string.trtckaraoke_msg_order_song_seat, seatIndex + 1);
        msgEntity.linkUrl = getString(R.string.trtckaraoke_msg_order_song, entity.musicName);
        showImMsg(msgEntity);
    }

    protected void showImMsg(final MessageEntity entity) {
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
                if (entity != null && entity.type == MessageEntity.TYPE_WAIT_AGREE) {
                    //判断当前消息是同一个用户发出
                    if (mLastMsgUserId != null && mLastMsgUserId.equals(entity.userId)) {
                        for (MessageEntity temp : mMsgEntityList) {
                            if (temp != null && mLastMsgUserId.equals(temp.userId)) {
                                temp.type = MessageEntity.TYPE_AGREED;
                            }
                        }
                    }
                }
                mLastMsgUserId = entity.userId;
                mMsgEntityList.add(entity);
                mMessageListAdapter.notifyDataSetChanged();
                mRvImMsg.smoothScrollToPosition(mMessageListAdapter.getItemCount());
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mIsDestroyed = true;
        UserModelManager.getInstance().getUserModel().userType = UserModel.UserType.NONE;
        mLrcView.reset("");
        mTRTCKaraokeRoom.setDelegate(null);
        TRTCKaraokeRoom.destroySharedInstance();
        TUICore.unRegisterEvent(KARAOKE_MUSIC_EVENT, KARAOKE_UPDATE_LYRICS_PATH_EVENT, mUpdateLyricsPathNotification);
        TUICore.unRegisterEvent(KARAOKE_MUSIC_EVENT, KARAOKE_ADD_MUSIC_EVENT, mAddMusicNotification);
    }

    private void setLrcPath(final String path) {
        TRTCLogger.i(TAG, "setLrcPath: path = " + path);
        if (mLrcView == null) {
            return;
        }
        if (TextUtils.isEmpty(path)) {
            mLrcView.reset("");
            return;
        }
        new LrcAsyncTask(path).execute();
    }

    class LrcAsyncTask extends AsyncTask {
        private String    mPath;
        private LyricInfo mLyricInfo;

        public LrcAsyncTask(String path) {
            mPath = path;
        }

        @Override
        protected Object doInBackground(Object[] objects) {
            if (mIsDestroyed) {
                return null;
            }
            try {
                LyricsFileReader lyricsReader = new LyricsFileReader();
                mLyricInfo = lyricsReader.parseLyricInfo(mPath);
            } catch (Exception e) {
                e.printStackTrace();
                TRTCLogger.e(TAG, "lyrics file parse error, " + e);
            }
            return null;
        }

        @Override
        protected void onPostExecute(Object o) {
            if (mIsDestroyed) {
                return;
            }
            mLrcView.setupLyric(mLyricInfo);
        }
    }
}
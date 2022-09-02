package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;

import androidx.coordinatorlayout.widget.CoordinatorLayout;

import android.util.AttributeSet;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.blankj.utilcode.util.ToastUtils;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoom;
import com.tencent.liteav.tuikaraoke.ui.audio.AudioEffectPanel;
import com.tencent.liteav.tuikaraoke.ui.audio.impl.TUIKaraokeAudioManager;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;
import com.tencent.liteav.tuikaraoke.ui.music.IUpdateLrcDelegate;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicCallback;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicServiceDelegate;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;

import java.util.ArrayList;
import java.util.List;

public class KaraokeMusicView extends CoordinatorLayout implements KaraokeMusicServiceDelegate {
    private static String          TAG = "KaraokeMusicView";
    private final  Context         mContext;
    private final  TRTCKaraokeRoom mTRTCKaraokeRoom;

    private LinearLayout mLayoutInfo;
    private LinearLayout mLayoutSongInfo;
    private LinearLayout mLayoutEmpty;
    private TextView     mTvSeatName;
    private TextView     mTvUserName;
    private TextView     mTvSongName;
    private Button       mBtnChooseSong;
    private Button       mBtnEffect;
    private Button       mBtnChangeVoice;
    private Button       mBtnSwitchMusic;
    private Button       mBtnEmptyChoose;

    private KaraokeMusicService         mMusicManagerImpl;
    private List<KaraokeMusicModel>     mSelectedList;
    private AudioEffectPanel            mAudioEffectPanel;
    private TUIKaraokeAudioManager      mTUIKaraokeAudioManager;
    private KaraokeMusicDialog          mDialog;
    private IUpdateLrcDelegate          mLrcDelegate;
    private List<KaraokeRoomSeatEntity> mRoomSeatEntityList;
    private KTVMusicMsgDelegate         mMsgDelegate;
    private RoomInfoController          mRoomInfoController;
    private boolean                     mIsOrigin; //是否是原唱
    private String                      mCurrentLrcPath;

    public KaraokeMusicView(Context context) {
        this(context, null);
    }

    public KaraokeMusicView(Context context, AttributeSet attrs) {
        this(context, attrs, 0);
    }

    public KaraokeMusicView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        mContext = context;
        View rootView = LayoutInflater.from(context).inflate(R.layout.trtckaraoke_layout_songtable, this);
        mTRTCKaraokeRoom = TRTCKaraokeRoom.sharedInstance(mContext);
        initView(rootView);
        initListener();
    }

    public void init(RoomInfoController roomInfoController) {
        mRoomInfoController = roomInfoController;
        mMusicManagerImpl = roomInfoController.getMusicServiceImpl();
        initData(mContext);
    }

    public void setLrcDelegate(IUpdateLrcDelegate delegate) {
        mLrcDelegate = delegate;
    }

    public void updateView(boolean isShow) {
        if (isShow) {
            mBtnEffect.setVisibility(View.VISIBLE);
            mBtnChangeVoice.setVisibility(View.VISIBLE);
        } else {
            mBtnEffect.setVisibility(View.GONE);
            mBtnChangeVoice.setVisibility(View.GONE);
        }
        updateSongTableView(mSelectedList.size());
    }

    public void showMusicDialog(boolean show) {
        if (show) {
            showChooseSongDialog();
        }
    }

    private void initData(Context context) {
        mTUIKaraokeAudioManager = TUIKaraokeAudioManager.getInstance();
        //音效面板
        mAudioEffectPanel = new AudioEffectPanel(context);
        mAudioEffectPanel.setTRTCKaraokeRoom(mTRTCKaraokeRoom);
        mAudioEffectPanel.setDelegate(mTUIKaraokeAudioManager);

        mSelectedList = new ArrayList<>();
        if (mMusicManagerImpl != null) {
            mMusicManagerImpl.setServiceDelegate(this);
            mMusicManagerImpl.ktvGetSelectedMusicList(new KaraokeMusicCallback.MusicSelectedListCallback() {
                @Override
                public void onCallback(int code, String msg, List<KaraokeMusicModel> list) {
                    mSelectedList.clear();
                    mSelectedList.addAll(list);
                }
            });
        }

        //初始化Dialog
        if (mDialog == null) {
            mDialog = new KaraokeMusicDialog(mContext, mRoomInfoController);
        }

        //已点列表为空时,显示空界面
        updateSongTableView(mSelectedList.size());
    }

    private void initView(View view) {
        mLayoutInfo = view.findViewById(R.id.ll_info);
        mLayoutSongInfo = view.findViewById(R.id.ll_song_info);
        mLayoutEmpty = view.findViewById(R.id.ll_empty);

        //默认显示空界面
        mLayoutSongInfo.setVisibility(View.GONE);
        mLayoutInfo.setVisibility(View.GONE);
        mLayoutEmpty.setVisibility(View.VISIBLE);

        mBtnEmptyChoose = (Button) view.findViewById(R.id.btn_empty_choose_song);
        mTvSeatName = (TextView) view.findViewById(R.id.tv_seat_name);
        mTvUserName = (TextView) view.findViewById(R.id.tv_user_name);
        mTvSongName = (TextView) view.findViewById(R.id.tv_song_name);
        mBtnChooseSong = (Button) view.findViewById(R.id.btn_choose_song);
        mBtnSwitchMusic = (Button) view.findViewById(R.id.btn_switch_music);
        mBtnEffect = (Button) view.findViewById(R.id.btn_effect);
        mBtnChangeVoice = (Button) view.findViewById(R.id.btn_change_voice);
    }

    private void updateSongTableView(int size) {
        if (size == 0) {
            mLayoutSongInfo.setVisibility(View.GONE);
            mLayoutInfo.setVisibility(View.GONE);
            mLayoutEmpty.setVisibility(View.VISIBLE);
            //空界面清空歌词
            mLrcDelegate.setLrcPath(null);
        } else if (size > 0) {
            mLayoutSongInfo.setVisibility(View.VISIBLE);
            mLayoutInfo.setVisibility(View.VISIBLE);
            mLayoutEmpty.setVisibility(View.GONE);

            KaraokeMusicModel songEntity = mSelectedList.get(0);
            mTvSongName.setText(songEntity.musicName);

            //根据用户Id,从麦位表获取当前歌曲的用户名和座位Id
            if (mRoomInfoController != null) {
                mRoomSeatEntityList = mRoomInfoController.getRoomSeatEntityList();
            }
            if (mRoomSeatEntityList == null) {
                return;
            }
            KaraokeRoomSeatEntity seatEntity = null;
            for (KaraokeRoomSeatEntity entity : mRoomSeatEntityList) {
                if (entity.userId != null && entity.userId.equals(songEntity.userId)) {
                    seatEntity = entity;
                    break;
                }
            }

            if (seatEntity != null) {
                mTvUserName.setText(seatEntity.userName);
                mTvSeatName.setText(getResources().getString(R.string.trtckaraoke_tv_seat_id,
                        String.valueOf(seatEntity.index + 1)));
            }
        }
    }

    private void initListener() {
        mBtnChooseSong.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                showChooseSongDialog();
            }
        });
        mBtnEffect.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (checkButtonPermission()) {
                    if (mAudioEffectPanel != null) {
                        mAudioEffectPanel.setType(AudioEffectPanel.CHANGE_VOICE);
                        mAudioEffectPanel.show();
                    }
                }
            }
        });
        mBtnChangeVoice.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (checkButtonPermission()) {
                    if (mAudioEffectPanel != null) {
                        mAudioEffectPanel.setType(AudioEffectPanel.MUSIC_TYPE);
                        mAudioEffectPanel.show();
                    }
                }
            }
        });
        mBtnEmptyChoose.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                showChooseSongDialog();
            }
        });
        mBtnSwitchMusic.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                //如果是原唱,切到伴奏
                if (mIsOrigin) {
                    mTUIKaraokeAudioManager.switchToOriginalVolume(false);
                    mBtnSwitchMusic.setBackgroundResource(R.drawable.trtckaraoke_ic_accompany_music);
                    mIsOrigin = false;
                } else {
                    mTUIKaraokeAudioManager.switchToOriginalVolume(true);
                    mBtnSwitchMusic.setBackgroundResource(R.drawable.trtckaraoke_ic_origin_music);
                    mIsOrigin = true;
                }
            }
        });
    }

    //打开点歌/已点面板
    private void showChooseSongDialog() {
        if (mDialog != null) {
            mDialog.show();
        } else {
            if (mRoomInfoController == null) {
                return;
            }
            mDialog = new KaraokeMusicDialog(mContext, mRoomInfoController);
            mDialog.show();
        }
    }

    protected boolean checkButtonPermission() {
        if (!mRoomInfoController.isAnchor()) {
            ToastUtils.showLong(getResources().getString(R.string.trtckaraoke_toast_anchor_can_only_operate_it));
        }
        return mRoomInfoController.isAnchor();
    }

    @Override
    public void onMusicListChange(List<KaraokeMusicModel> musicInfoList) {
        mSelectedList.clear();
        mSelectedList.addAll(musicInfoList);

        //更新歌曲播放界面的信息
        updateSongTableView(mSelectedList.size());
        KaraokeMusicModel topModel = null;
        //获取到已点列表后,将第一首歌保存
        if (mSelectedList.size() > 0) {
            topModel = mSelectedList.get(0);
            mRoomInfoController.setTopModel(topModel);
        }

        //不是当前主播在播放,不能切换原唱/伴奏
        String userId = mRoomInfoController.getSelfUserId();
        if (topModel == null || userId == null || !userId.equals(topModel.userId)) {
            mBtnSwitchMusic.setVisibility(GONE);
        } else {
            mBtnSwitchMusic.setVisibility(VISIBLE);
        }
    }

    @Override
    public void onShouldSetLyric(final KaraokeMusicModel model) {
        Log.d(TAG, "onShouldSetLyric: model = " + model);
        if (model == null) {
            mLrcDelegate.setLrcPath(null);
            return;
        }
        if (model.lrcUrl == null) {
            //如果歌词为空,则请求下载
            mMusicManagerImpl.downLoadMusic(model, new KaraokeMusicCallback.MusicLoadingCallback() {
                @Override
                public void onStart(KaraokeMusicInfo musicInfo) {

                }

                @Override
                public void onProgress(KaraokeMusicInfo musicInfo, float progress) {

                }

                @Override
                public void onFinish(KaraokeMusicInfo musicInfo, int errorCode, String errorMessage) {
                    if (musicInfo == null) {
                        mLrcDelegate.setLrcPath(null);
                        return;
                    }
                    //下载是异步的,下载完列表已经被清空或歌曲已经被删除的情况下,不需要显示歌词
                    KaraokeMusicModel topModel = mRoomInfoController.getTopModel();
                    if (topModel == null || !musicInfo.musicId.equals(topModel.musicId)) {
                        mLrcDelegate.setLrcPath(null);
                        return;
                    }

                    model.lrcUrl = musicInfo.lrcUrl;
                    mLrcDelegate.setLrcPath(model.lrcUrl);
                }
            });
        } else if (!model.lrcUrl.equals(mCurrentLrcPath)) {
            mLrcDelegate.setLrcPath(model.lrcUrl);
            mCurrentLrcPath = model.lrcUrl;
        }
    }

    @Override
    public void onShouldPlay(KaraokeMusicModel model) {
        // 收到播放歌曲的通知后,如果是主播才播放,听众不能播放
        Log.d(TAG, "onShouldPlay: model = " + model);
        if ((mRoomInfoController.isAnchor())) {
            mIsOrigin = true;
            mLrcDelegate.setLrcPath(model.lrcUrl);
            mTUIKaraokeAudioManager.startPlayMusic(model);
            mTUIKaraokeAudioManager.setCurrentStatus(TUIKaraokeAudioManager.MUSIC_PLAYING);
        }
    }

    @Override
    public void onShouldStopPlay(KaraokeMusicModel model) {
        Log.d(TAG, "onShouldStopPlay: model = " + model);
        if ((mRoomInfoController.isAnchor())) {
            mIsOrigin = false;
            mTUIKaraokeAudioManager.stopPlayMusic(model);
            mTUIKaraokeAudioManager.setCurrentStatus(TUIKaraokeAudioManager.MUSIC_STOP);
        }
    }

    @Override
    public void onShouldShowMessage(KaraokeMusicModel model) {
        if (mMsgDelegate != null) {
            mMsgDelegate.sendOrderMsg(model);
        }
    }

    //点歌消息回调
    public void setMsgListener(KTVMusicMsgDelegate delegate) {
        mMsgDelegate = delegate;
    }

    public interface KTVMusicMsgDelegate {
        void sendOrderMsg(KaraokeMusicInfo model);
    }
}

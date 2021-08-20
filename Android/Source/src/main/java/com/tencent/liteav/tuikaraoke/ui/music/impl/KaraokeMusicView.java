package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;
import android.support.design.widget.CoordinatorLayout;
import android.util.AttributeSet;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.blankj.utilcode.util.ToastUtils;
import com.tencent.liteav.basic.UserModelManager;
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
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicUtils;

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
    private Button       mBtnEmptyChoose;
    private int          mPage         = 1;
    private int          mLoadPageSize = 10;

    private KaraokeMusicService         mMusicManagerImpl;
    private List<KaraokeMusicModel>     mSelectedList;
    private List<KaraokeMusicModel>     mLibraryList;
    private AudioEffectPanel            mAudioEffectPanel;
    private TUIKaraokeAudioManager      mTUIKaraokeAudioManager;
    private KaraokeMusicDialog          mDialog;
    private IUpdateLrcDelegate          mLrcDelegate;
    private List<KaraokeRoomSeatEntity> mKaraokeRoomSeatEntityList;
    private KTVMusicMsgDelegate         mMsgDelegate;

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


    public void setMusicManagerImpl(KaraokeMusicService delegate) {
        mMusicManagerImpl = delegate;
        initData(mContext);
    }

    private void initData(Context context) {
        mTUIKaraokeAudioManager = TUIKaraokeAudioManager.getInstance();
        //音效面板
        mAudioEffectPanel = new AudioEffectPanel(context);
        mAudioEffectPanel.setTRTCKaraokeRoom(mTRTCKaraokeRoom);
        mAudioEffectPanel.setDelegate(mTUIKaraokeAudioManager);

        mSelectedList = new ArrayList<>();
        mLibraryList = new ArrayList<>();
        if (mMusicManagerImpl != null) {
            mMusicManagerImpl.setServiceDelegate(this);
            mMusicManagerImpl.ktvGetSelectedMusicList(new KaraokeMusicCallback.MusicSelectedListCallback() {
                @Override
                public void onCallback(int code, String msg, List<KaraokeMusicModel> list) {
                    mSelectedList.clear();
                    mSelectedList.addAll(list);
                }
            });
            mMusicManagerImpl.ktvGetMusicPage(mPage, mLoadPageSize, new KaraokeMusicCallback.MusicListCallback() {
                @Override
                public void onCallback(int code, String msg, List<KaraokeMusicInfo> list) {
                    mLibraryList.clear();
                    for (KaraokeMusicInfo info : list) {
                        KaraokeMusicModel model = new KaraokeMusicModel();
                        model.musicId = info.musicId;
                        model.musicName = info.musicName;
                        model.singer = info.singer;
                        model.contentUrl = info.contentUrl;
                        model.coverUrl = info.coverUrl;
                        model.lrcUrl = info.lrcUrl;
                        model.isSelected = false;
                        mLibraryList.add(model);
                    }
                }
            });
        }

        //初始化Dialog
        if (mDialog == null) {
            mDialog = new KaraokeMusicDialog(mContext, mMusicManagerImpl);
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
        mBtnEffect = (Button) view.findViewById(R.id.btn_effect);
        mBtnChangeVoice = (Button) view.findViewById(R.id.btn_change_voice);
    }

    public void updateSongTableView(int size) {
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
            KaraokeRoomSeatEntity seatEntity = null;
            if (mKaraokeRoomSeatEntityList != null) {
                for (KaraokeRoomSeatEntity entity : mKaraokeRoomSeatEntityList) {
                    if (entity.userId != null && entity.userId.equals(songEntity.bookUser)) {
                        seatEntity = entity;
                        break;
                    }
                }
            }

            if (seatEntity != null) {
                mTvUserName.setText(seatEntity.userName);
                mTvSeatName.setText(getResources().getString(R.string.trtckaraoke_tv_seat_id, String.valueOf(seatEntity.index + 1)));
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
    }

    //打开点歌/已点面板
    public void showChooseSongDialog() {
        if (mDialog != null) {
            mDialog.show();
        } else {
            mDialog = new KaraokeMusicDialog(mContext, mMusicManagerImpl);
            mDialog.show();
        }
    }

    protected boolean checkButtonPermission() {
        if (!KaraokeMusicUtils.mIsAnchor) {
            ToastUtils.showLong(getResources().getString(R.string.trtckaraoke_toast_anchor_can_only_operate_it));
        }
        return KaraokeMusicUtils.mIsAnchor;
    }


    @Override
    public void OnMusicListChange(List<KaraokeMusicModel> musicInfoList) {
        mSelectedList.clear();
        mSelectedList.addAll(musicInfoList);

        //更新歌曲播放界面的信息
        updateSongTableView(mSelectedList.size());
    }

    @Override
    public void onShouldSetLyric(String musicID) {
        Log.d(TAG, "onShouldSetLyric: musicId = " + musicID);
        if (musicID == null || musicID.equals("0")) {
            mLrcDelegate.setLrcPath(null);
            return;
        }

        KaraokeMusicModel entity = findFromList(musicID, mSelectedList);
        if (entity == null) {
            entity = findFromList(musicID, mLibraryList);
        }

        if (entity != null) {
            mLrcDelegate.setLrcPath(entity.lrcUrl);
        }
    }

    public KaraokeMusicModel findFromList(String musicId, List<KaraokeMusicModel> list) {
        if (musicId == null || list.size() == 0) {
            return null;
        }
        KaraokeMusicModel entity = null;
        for (KaraokeMusicModel temp : list) {
            if (temp != null && musicId.equals(temp.musicId)) {
                entity = temp;
                break;
            }
        }
        return entity;
    }

    @Override
    public void onShouldPlay(KaraokeMusicModel model) {
        // 收到播放歌曲的通知后,如果是主播才播放,听众不能播放
        Log.d(TAG, "onShouldPlay: model = " + model);
        if ((KaraokeMusicUtils.mIsAnchor)) {
            mLrcDelegate.setLrcPath(model.lrcUrl);
            mTUIKaraokeAudioManager.startPlayMusic(model);
            mTUIKaraokeAudioManager.setCurrentStatus(TUIKaraokeAudioManager.MUSIC_PLAYING);
        }
    }

    @Override
    public void onShouldStopPlay(KaraokeMusicModel model) {
        if ((KaraokeMusicUtils.mIsAnchor)) {
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

    public void updateListChange(List<KaraokeRoomSeatEntity> KaraokeRoomSeatEntityList) {
        mKaraokeRoomSeatEntityList = KaraokeRoomSeatEntityList;
        String userId = null;
        for (KaraokeRoomSeatEntity entity : mKaraokeRoomSeatEntityList) {
            if (entity.userId != null && entity.userId.equals(UserModelManager.getInstance().getUserModel().userId)) {
                userId = entity.userId;
                break;
            }
        }

        KaraokeMusicUtils.isAnchor(userId != null);
        KaraokeMusicUtils.setSeatEntityList(KaraokeRoomSeatEntityList);
    }

    //点歌消息回调
    public void setMsgListener(KTVMusicMsgDelegate delegate) {
        mMsgDelegate = delegate;
    }

    public interface KTVMusicMsgDelegate {
        void sendOrderMsg(KaraokeMusicModel model);
    }
}

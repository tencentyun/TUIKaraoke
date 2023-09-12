package com.tencent.liteav.tuikaraoke.ui.music.impl;

import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_INFO_KEY;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_SHOW_MUSIC_LYRIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_SHOW_MUSIC_LYRIC_KEY;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_STOP_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_UPDATE_CURRENT_MUSIC_EVENT;

import android.content.Context;
import android.text.TextUtils;
import android.util.AttributeSet;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.LinearLayout;
import android.widget.Switch;
import android.widget.TextView;

import androidx.coordinatorlayout.widget.CoordinatorLayout;

import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicServiceObserver;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoom;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.MusicPitchModel;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.ui.audio.AudioEffectPanel;
import com.tencent.liteav.tuikaraoke.ui.audio.impl.KaraokeAudioViewModel;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;
import com.tencent.liteav.tuikaraoke.ui.utils.Toast;
import com.tencent.qcloud.tuicore.TUICore;
import com.tencent.qcloud.tuicore.interfaces.ITUINotification;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class KaraokeMusicView extends CoordinatorLayout {
    private static String TAG = "KaraokeMusicView";

    private final Context         mContext;
    private final TRTCKaraokeRoom mTRTCKaraokeRoom;

    private LinearLayout   mLayoutInfo;
    private TextView       mTextMusicPlayingProgress;
    private TextView       mTextMusicName;
    private TextView       mTextMusicComing;
    private LinearLayout   mLayoutAudioEffect;
    private Button         mBtnEmptyChoose;
    private Button         mBtnStartChorus;
    private Switch         mSwitchMusicAccompanimentMode;

    private KaraokeMusicService         mMusicManagerImpl;
    private List<KaraokeMusicInfo>      mSelectedList;
    private AudioEffectPanel            mAudioEffectPanel;
    private KaraokeAudioViewModel       mKaraokeAudioViewModel;
    private KaraokeMusicDialog          mKaraokeMusicDialog;
    private RoomInfoController          mRoomInfoController;
    private KaraokeMusicInfo            mCurrentMusicInfo;
    private boolean                     mIsStartChorus;

    private final ITUINotification mStopMusicNotification = new ITUINotification() {
        @Override
        public void onNotifyEvent(String key, String subKey, Map<String, Object> param) {
            if (param == null || !param.containsKey(KARAOKE_MUSIC_INFO_KEY)) {
                return;
            }
            KaraokeMusicInfo musicInfo = (KaraokeMusicInfo) param.get(KARAOKE_MUSIC_INFO_KEY);
            stopPlay(musicInfo);
        }
    };

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

    public void init(RoomInfoController roomInfoController, KaraokeAudioViewModel karaokeAudioViewModel) {
        mRoomInfoController = roomInfoController;
        mMusicManagerImpl = roomInfoController.getMusicServiceImpl();
        mKaraokeAudioViewModel = karaokeAudioViewModel;
        initData(mContext);
    }

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        TUICore.registerEvent(KARAOKE_MUSIC_EVENT, KARAOKE_STOP_MUSIC_EVENT, mStopMusicNotification);
    }

    @Override
    public void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        TUICore.unRegisterEvent(KARAOKE_MUSIC_EVENT, KARAOKE_STOP_MUSIC_EVENT, mStopMusicNotification);
    }

    public void updateView() {
        updateSongTableView(mSelectedList.size());
    }

    public void updateMusicAccompanimentModeView(boolean isOriginal) {
        if (mSwitchMusicAccompanimentMode != null) {
            mSwitchMusicAccompanimentMode.setChecked(isOriginal);
        }
    }

    public void showMusicDialog(boolean show) {
        if (show) {
            showChooseSongDialog(0);
        }
    }

    private void initData(Context context) {
        mAudioEffectPanel = new AudioEffectPanel(context);

        mSelectedList = new ArrayList<>();
        if (mMusicManagerImpl != null) {
            mMusicManagerImpl.addObserver(observer);
        }
        for (KaraokeMusicInfo info : mRoomInfoController.getUserSelectMap().values()) {
            mSelectedList.add(info);
        }
        //初始化Dialog
        if (mKaraokeMusicDialog == null) {
            mKaraokeMusicDialog = new KaraokeMusicDialog(mContext, mRoomInfoController);
        }

        //已点列表为空时,显示空界面
        updateSongTableView(mSelectedList.size());
    }

    private void initView(View view) {
        mLayoutInfo = view.findViewById(R.id.ll_info);
        mBtnEmptyChoose = (Button) view.findViewById(R.id.btn_empty_choose_song);
        mTextMusicPlayingProgress = (TextView) view.findViewById(R.id.tv_music_playing_progress);
        mTextMusicName = (TextView) view.findViewById(R.id.tv_music_name);
        mTextMusicComing = (TextView) view.findViewById(R.id.tv_music_coming);
        mSwitchMusicAccompanimentMode = view.findViewById(R.id.switch_music);
        mLayoutAudioEffect = view.findViewById(R.id.ll_change_voice);
        mBtnStartChorus = (Button) view.findViewById(R.id.btn_start_chorus);

        //默认显示空界面
        mLayoutInfo.setVisibility(View.GONE);
        mBtnEmptyChoose.setVisibility(View.VISIBLE);
    }

    private void updateSongTableView(int size) {
        Log.d(TAG, "updateSongTableView, size = " + size);
        if (size == 0) {
            mBtnStartChorus.setVisibility(GONE);
            mLayoutInfo.setVisibility(View.GONE);
            mBtnEmptyChoose.setVisibility(View.VISIBLE);
            mTextMusicComing.setVisibility(GONE);
            mIsStartChorus = false;
            showLyric(false);
        } else if (size > 0) {
            mLayoutInfo.setVisibility(View.VISIBLE);
            mBtnEmptyChoose.setVisibility(View.GONE);
            if (mRoomInfoController.isRoomOwner() && !mIsStartChorus) {
                mBtnStartChorus.setVisibility(VISIBLE);
            }

            KaraokeMusicInfo songEntity = mSelectedList.get(0);
            mTextMusicName.setText(songEntity.musicName);
        }
    }

    private void initListener() {
        mLayoutAudioEffect.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (checkButtonPermission()) {
                    if (mAudioEffectPanel != null) {
                        mAudioEffectPanel.show();
                    }
                }
            }
        });
        mBtnEmptyChoose.setOnClickListener(v -> clickToShowSongDialog(0));

        mSwitchMusicAccompanimentMode.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (buttonView.isPressed() && !mRoomInfoController.isRoomOwner()) {
                    Toast.show(KaraokeMusicView.this, R.string.trtckaraoke_toast_anchor_can_only_operate_it,
                            Toast.LENGTH_SHORT);
                    mSwitchMusicAccompanimentMode.setChecked(!isChecked);
                    return;
                }
                if (!isChecked && mCurrentMusicInfo != null && TextUtils.isEmpty(mCurrentMusicInfo.accompanyUrl)) {
                    Toast.show(KaraokeMusicView.this, R.string.trtckaraoke_toast_muisc_no_accompaniment,
                            Toast.LENGTH_SHORT);
                    mSwitchMusicAccompanimentMode.setChecked(true);
                    return;
                }
                //如果是原唱,切到伴奏
                mTRTCKaraokeRoom.switchMusicAccompanimentMode(isChecked);
            }
        });

        mBtnStartChorus.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View view) {
                TRTCLogger.i(TAG, "click start chorus: mCurrentMusicInfo = " + mCurrentMusicInfo);
                if (mCurrentMusicInfo == null) {
                    return;
                }
                if (!mCurrentMusicInfo.isPreloaded()) {
                    return;
                }
                //开始合唱
                mBtnStartChorus.setVisibility(GONE);
                mSwitchMusicAccompanimentMode.setVisibility(VISIBLE);
                //开始倒计时
                mIsStartChorus = true;
                startPlay(mCurrentMusicInfo);
            }
        });

        findViewById(R.id.ll_music_info).setOnClickListener(v -> clickToShowSongDialog(1));
    }

    private void clickToShowSongDialog(int currentItem) {
        if (mRoomInfoController.isRoomOwner()) {
            showChooseSongDialog(currentItem);
        } else {
            Toast.show(this, R.string.trtckaraoke_toast_room_owner_can_operate_it, Toast.LENGTH_LONG);
        }
    }

    private void startPlay(final KaraokeMusicInfo model) {
        showLyric(true);
        mKaraokeAudioViewModel.startPlayMusic(model);
        mMusicManagerImpl.prepareMusicScore(model);
    }

    //打开点歌/已点面板
    private void showChooseSongDialog(int currentItem) {
        if (mKaraokeMusicDialog == null) {
            if (mRoomInfoController == null) {
                return;
            }
            mKaraokeMusicDialog = new KaraokeMusicDialog(mContext, mRoomInfoController);
        }
        mKaraokeMusicDialog.setCurrentItem(currentItem);
        mKaraokeMusicDialog.show();
    }

    protected boolean checkButtonPermission() {
        if (!mRoomInfoController.isAnchor()) {
            Toast.show(this, R.string.trtckaraoke_toast_anchor_can_only_operate_it, Toast.LENGTH_LONG);
        }
        return mRoomInfoController.isAnchor();
    }

    private void playMusic(final KaraokeMusicInfo musicInfo) {
        // 收到播放歌曲的通知后,如果是主播才播放,听众不能播放
        TRTCLogger.i(TAG, "playMusic, mIsStartChorus:" + mIsStartChorus + " model: " + musicInfo);
        mCurrentMusicInfo = musicInfo;
        mBtnStartChorus.setEnabled(true);
        onPlayStart();
        if (mRoomInfoController.isRoomOwner()) {
            if (mIsStartChorus) {
                startPlay(musicInfo);
            }
        } else {
            showLyric(true);
        }
    }

    private void stopPlay(KaraokeMusicInfo model) {
        TRTCLogger.i(TAG, "stopPlay: model = " + model);
        mCurrentMusicInfo = null;
        if ((mRoomInfoController.isAnchor())) {
            mKaraokeAudioViewModel.stopPlayMusic(model);
            mMusicManagerImpl.finishMusicScore();
        }
        onPlayStop();
    }

    private void showLyric(boolean show) {
        mTextMusicComing.setVisibility(show ? VISIBLE : GONE);
        Map<String, Object> params = new HashMap<>();
        params.put(KARAOKE_SHOW_MUSIC_LYRIC_KEY, show);
        TUICore.notifyEvent(KARAOKE_MUSIC_EVENT, KARAOKE_SHOW_MUSIC_LYRIC_EVENT, params);
    }

    private void notifyCurrentMusic(KaraokeMusicInfo musicInfo) {
        Map<String, Object> params = new HashMap<>();
        params.put(KARAOKE_MUSIC_INFO_KEY, musicInfo);
        TUICore.notifyEvent(KARAOKE_MUSIC_EVENT, KARAOKE_UPDATE_CURRENT_MUSIC_EVENT, params);
    }

    private void onPlayStart() {
        notifyCurrentMusic(mCurrentMusicInfo);
        mSwitchMusicAccompanimentMode.setVisibility(GONE);
        mTextMusicPlayingProgress.setVisibility(VISIBLE);
        mTextMusicComing.setText(R.string.trtckaraoke_music_coming);
    }

    private void onPlayStop() {
        notifyCurrentMusic(null);
        mSwitchMusicAccompanimentMode.setVisibility(GONE);
        mTextMusicPlayingProgress.setVisibility(GONE);
        mTextMusicComing.setVisibility(GONE);
        //结束时清空显示，避免播放下一首时闪现上次歌曲的数据
        mTextMusicPlayingProgress.setText("");
        if (mCurrentMusicInfo != null) {
            mTextMusicComing.setText(R.string.trtckaraoke_lyric_empty_hint);
            mTextMusicComing.setVisibility(VISIBLE);
        }
    }

    public void updateMusicPlayingProgress(long progress, long total) {
        boolean isEmptyUrl = mCurrentMusicInfo != null && TextUtils.isEmpty(mCurrentMusicInfo.lrcUrl);
        if (mTextMusicComing.getVisibility() == VISIBLE && !isEmptyUrl) {
            mTextMusicComing.setVisibility(GONE);
        }
        int newVisibility = mRoomInfoController.isAnchor() ? VISIBLE : GONE;
        if (mSwitchMusicAccompanimentMode.getVisibility() != newVisibility) {
            mSwitchMusicAccompanimentMode.setVisibility(newVisibility);
        }
        String info = String.format("%02d:%02d/%02d:%02d",
                progress / 1000 / 60, progress / 1000 % 60,
                total / 1000 / 60, total / 1000 % 60);
        mTextMusicPlayingProgress.setText(info);
        if (mTextMusicPlayingProgress.getVisibility() != VISIBLE) {
            mTextMusicPlayingProgress.setVisibility(VISIBLE);
        }
    }

    private final KaraokeMusicServiceObserver observer = new KaraokeMusicServiceObserver() {
        @Override
        public void onMusicListChanged(List<KaraokeMusicInfo> musicInfoList) {
            mSelectedList.clear();
            mSelectedList.addAll(musicInfoList);

            //更新歌曲播放界面的信息
            updateSongTableView(mSelectedList.size());

            //获取到已点列表后,将第一首歌保存
            if (mSelectedList.size() > 0) {
                KaraokeMusicInfo topModel = mSelectedList.get(0);
                if (mCurrentMusicInfo != null && topModel != null
                        && TextUtils.equals(topModel.performId, mCurrentMusicInfo.performId)) {
                    TRTCLogger.i(TAG, "this music is playing");
                } else {
                    stopPlay(mCurrentMusicInfo);
                    mRoomInfoController.setTopModel(topModel);
                    playMusic(topModel);
                }
            } else {
                stopPlay(mCurrentMusicInfo);
            }
            mKaraokeMusicDialog.updateMusicListChanged(musicInfoList);
        }

        @Override
        public void onMusicSingleScore(int currentScore) {

        }

        @Override
        public void onMusicRealTimePitch(int pitch, float timeStamp) {

        }

        @Override
        public void onMusicScoreFinished(int totalScore) {

        }

        @Override
        public void onMusicScorePrepared(List<MusicPitchModel> pitchModels) {

        }
    };
}

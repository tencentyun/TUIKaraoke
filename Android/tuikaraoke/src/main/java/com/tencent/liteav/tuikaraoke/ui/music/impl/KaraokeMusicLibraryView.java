package com.tencent.liteav.tuikaraoke.ui.music.impl;

import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_ADD_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_DELETE_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_INFO_KEY;

import android.content.Context;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ProgressBar;

import androidx.coordinatorlayout.widget.CoordinatorLayout;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.tencent.liteav.tuikaraoke.model.KaraokeAddMusicCallback;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicPageInfo;
import com.tencent.liteav.tuikaraoke.ui.utils.Toast;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicTag;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;
import com.tencent.qcloud.tuicore.TUICore;
import com.tencent.qcloud.tuicore.interfaces.ITUINotification;
import com.tencent.qcloud.tuicore.interfaces.TUIValueCallback;
import com.tencent.liteav.tuikaraoke.ui.music.impl.KaraokeMusicLibraryAdapter.ViewHolder;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 *
 * 曲库列表刷新条件：
 * 1、首次刷新，根据最新已选歌单刷新--getSelectedMusicList结果存入RoomInfoController的mUserSelectMap
 * 2、已选歌单中某个歌曲播放完毕--onMusicComplete
 * 3、已选歌单中切歌--nextMusic
 * 4、已选歌单中删歌--deleteMusic
 */
public class KaraokeMusicLibraryView extends CoordinatorLayout {
    private static final String TAG = "KaraokeMusicLibraryView";

    private ProgressBar                mProgressbarRequest;
    private RecyclerView               mRecyclerMusic;
    private RecyclerView               mRecyclerMusicTags;
    private KaraokeMusicLibraryAdapter mLibraryListAdapter;
    private KaraokeMusicTagsAdapter    mMusicTagsAdapter;
    private RoomInfoController         mRoomInfoController;

    private Context                    mContext;
    private List<KaraokeMusicInfo>     mLibraryLists  = new ArrayList<>();
    private List<KaraokeMusicTag>      mMusicTagList  = new ArrayList<>();
    private KaraokeMusicService        mKaraokeMusicService;

    private int                        mCurrentMusicTagIndex = 0;

    private final ITUINotification mDeleteMusicNotification = new ITUINotification() {
        @Override
        public void onNotifyEvent(String key, String subKey, Map<String, Object> param) {
            if (param == null || !param.containsKey(KARAOKE_MUSIC_INFO_KEY)) {
                return;
            }
            KaraokeMusicInfo musicInfo = (KaraokeMusicInfo) param.get(KARAOKE_MUSIC_INFO_KEY);
            deleteMusicInfo(musicInfo);
        }
    };

    public KaraokeMusicLibraryView(Context context, RoomInfoController roomInfoController) {
        super(context);
        mContext = context;
        mRoomInfoController = roomInfoController;
        mKaraokeMusicService = roomInfoController.getMusicServiceImpl();
        LayoutInflater.from(context).inflate(R.layout.trtckaraoke_fragment_library_view, this);
    }

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        initView(mContext);
        initData();
        TUICore.registerEvent(KARAOKE_MUSIC_EVENT, KARAOKE_DELETE_MUSIC_EVENT, mDeleteMusicNotification);
    }

    @Override
    public void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        TUICore.unRegisterEvent(KARAOKE_MUSIC_EVENT, KARAOKE_DELETE_MUSIC_EVENT, mDeleteMusicNotification);
    }

    private void initView(Context context) {
        mProgressbarRequest = findViewById(R.id.progress_request);
        mRecyclerMusic = findViewById(R.id.recycle_music_list);
        mRecyclerMusic.setLayoutManager(new LinearLayoutManager(mContext, LinearLayoutManager.VERTICAL, false));
        mLibraryListAdapter = new KaraokeMusicLibraryAdapter(mContext, mRoomInfoController, mLibraryLists,
                new KaraokeMusicLibraryAdapter.OnPickItemClickListener() {
                    @Override
                    public void onPickSongItemClick(KaraokeMusicInfo info, int position) {
                        addMusicToPlaylist(info, position);
                    }
                });
        mRecyclerMusic.setAdapter(mLibraryListAdapter);

        mRecyclerMusicTags = findViewById(R.id.recycle_music_tags);
        mRecyclerMusicTags.setLayoutManager(new LinearLayoutManager(mContext, LinearLayoutManager.HORIZONTAL, false));
        mMusicTagsAdapter = new KaraokeMusicTagsAdapter(mContext, mMusicTagList,
                new KaraokeMusicTagsAdapter.OnMusicTagClickListener() {
                    @Override
                    public void onMusicTagClick(KaraokeMusicTag musicTag, int position) {
                        mCurrentMusicTagIndex = position;
                        getMusicLibraryList(musicTag.id);
                    }
                });
        mRecyclerMusicTags.setAdapter(mMusicTagsAdapter);

        findViewById(R.id.img_search).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                KaraokeSearchMusicActivity.createSearchMusicActivity(mContext, mRoomInfoController);
            }
        });
        findViewById(R.id.btn_search_music).setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                KaraokeSearchMusicActivity.createSearchMusicActivity(mContext, mRoomInfoController);
            }
        });
    }

    private void initData() {
        mKaraokeMusicService.getMusicTagList(new TUIValueCallback<List<KaraokeMusicTag>>() {
            @Override
            public void onSuccess(List<KaraokeMusicTag> list) {
                mMusicTagList.clear();
                mMusicTagList.addAll(list);
                mMusicTagsAdapter.notifyDataSetChanged();
                getMusicLibraryList(mMusicTagList.get(0).id);
            }

            @Override
            public void onError(int code, String msg) {
                TRTCLogger.e(TAG, String.format("getMusicTagList: code=%s, msg=%s", code, msg));
            }
        });
    }

    private void getMusicLibraryList(String musicTagId) {
        mProgressbarRequest.setVisibility(VISIBLE);
        mKaraokeMusicService.getMusicsByTagId(musicTagId, "",
                new TUIValueCallback<KaraokeMusicPageInfo>() {

                    @Override
                    public void onError(int code, String msg) {
                        TRTCLogger.e(TAG, String.format("getMusicLibraryList: code=%s, msg=%s", code, msg));
                        mProgressbarRequest.setVisibility(GONE);
                    }

                    @Override
                    public void onSuccess(KaraokeMusicPageInfo object) {
                        mLibraryLists.clear();
                        for (KaraokeMusicInfo info : object.musicInfoList) {
                            KaraokeMusicInfo musicInfo = mRoomInfoController.getUserSelectMap().get(info.musicId);
                            info.isSelected = musicInfo != null;
                            if (musicInfo != null) {
                                info.originUrl = musicInfo.originUrl;
                                info.lrcUrl = musicInfo.lrcUrl;
                                info.accompanyUrl = musicInfo.accompanyUrl;
                            }
                            mLibraryLists.add(info);
                        }
                        mLibraryListAdapter.notifyDataSetChanged();
                        mProgressbarRequest.setVisibility(GONE);
                    }
                });
    }

    private void addMusicToPlaylist(final KaraokeMusicInfo info, int position) {
        int musicTagId = mCurrentMusicTagIndex;
        info.isSelected = true;
        ViewHolder holder = (ViewHolder) mRecyclerMusic.findViewHolderForAdapterPosition(position);
        ProgressBar progressBar = holder.itemView.findViewById(R.id.progress_bar_choose_song);
        holder.updateChooseButton(info.isSelected);
        mKaraokeMusicService.addMusicToPlaylist(info, new KaraokeAddMusicCallback() {
            private boolean checkMusicInfoFromCallback(KaraokeMusicInfo musicInfo) {
                if (position >= mLibraryLists.size()) {
                    return false;
                }
                // 切换MusicTag会导致mLibraryLists更新，需要重新获取当前position的歌曲
                KaraokeMusicInfo realInfo = mLibraryLists.get(position);
                if (musicTagId != mCurrentMusicTagIndex || !TextUtils.equals(musicInfo.musicId, realInfo.musicId)) {
                    // MusicTag发生变化 或者 回调来的歌曲与当前position的歌曲不一致，就不要刷新了
                    return false;
                }
                return true;
            }

            @Override
            public void onStart(KaraokeMusicInfo musicInfo) {}

            @Override
            public void onProgress(KaraokeMusicInfo musicInfo, float progress) {
                if (!checkMusicInfoFromCallback(musicInfo)) {
                    return;
                }
                int curProgress = (int) (progress * 100);
                curProgress = Math.max(curProgress, 0);
                curProgress = Math.min(curProgress, 100);
                if (progressBar.getProgress() < curProgress) {
                    progressBar.setProgress(curProgress);
                }
            }

            @Override
            public void onFinish(KaraokeMusicInfo musicInfo, int errorCode, String errorMessage) {
                if (!checkMusicInfoFromCallback(musicInfo)) {
                    return;
                }
                KaraokeMusicInfo realInfo = mLibraryLists.get(position);
                if (errorCode != 0) {
                    TRTCLogger.e(TAG, "downloadMusic failed errorCode = "
                            + errorCode + ",errorMessage = " + errorMessage);
                    realInfo.isSelected = false;
                    String tip = getResources().getString(R.string.trtckaraoke_toast_music_download_failed,
                            info.musicName);
                    Toast.show(KaraokeMusicLibraryView.this, tip, Toast.LENGTH_SHORT);
                    holder.updateChooseButton(info.isSelected);
                    mKaraokeMusicService.deleteMusicFromPlaylist(info, null);
                } else {
                    realInfo.isSelected = true;
                    Map<String, Object> params = new HashMap<>();
                    params.put(KARAOKE_MUSIC_INFO_KEY, info);
                    TUICore.notifyEvent(KARAOKE_MUSIC_EVENT, KARAOKE_ADD_MUSIC_EVENT, params);
                }
            }
        });
    }

    private void deleteMusicInfo(KaraokeMusicInfo musicInfo) {
        if (musicInfo == null) {
            return;
        }
        for (int i = 0; i < mLibraryLists.size(); i++) {
            KaraokeMusicInfo info = mLibraryLists.get(i);
            if (info != null
                    && TextUtils.equals(info.musicId, musicInfo.musicId)
                    && TextUtils.equals(musicInfo.userId, mRoomInfoController.getSelfUserId())) {
                info.isSelected = false;
                if (mLibraryListAdapter != null) {
                    mLibraryListAdapter.notifyItemChanged(i);
                }
                return;
            }
        }
    }
}

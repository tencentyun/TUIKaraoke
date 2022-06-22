package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import androidx.coordinatorlayout.widget.CoordinatorLayout;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ProgressBar;

import com.blankj.utilcode.util.ToastUtils;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokePopularInfo;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicCallback;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicServiceDelegate;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;


import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class KaraokeMusicLibraryView extends CoordinatorLayout implements KaraokeMusicServiceDelegate {
    private static final String  TAG = "KaraokeMusicLibraryView";
    private              Handler mMainHandler;

    private Context                        mContext;
    private RoomInfoController             mRoomInfoController;
    private KaraokeMusicLibraryAdapter     mLibraryListAdapter;
    private List<KaraokeMusicModel>        mLibraryLists;
    private List<KaraokePopularInfo>       mPopularList;        //热门歌曲分类列表
    private KaraokeMusicService            mKtvMusicImpl;
    private int                            mPage         = 0;
    private int                            mLoadPageSize = 50;
    private Map<String, KaraokeMusicModel> mUserSelectMap;
    private long                           lastClickTime = -1;
    private View                           mProgressBar;
    private RecyclerView                   mRvList;

    public KaraokeMusicLibraryView(Context context, RoomInfoController roomInfoController) {
        super(context);
        mContext = context;
        mRoomInfoController = roomInfoController;
        mKtvMusicImpl = roomInfoController.getMusicServiceImpl();
        mKtvMusicImpl.setServiceDelegate(this);
        initView(context);
        initData();
        initLisenter();
    }

    private void initData() {
        mLibraryLists = new ArrayList<>();
        mPopularList = new ArrayList<>();
        mUserSelectMap = new HashMap<>();
        mMainHandler = new Handler(Looper.getMainLooper());
        mLibraryListAdapter = new KaraokeMusicLibraryAdapter(mContext, mRoomInfoController, mLibraryLists,
                new KaraokeMusicLibraryAdapter.OnPickItemClickListener() {
                    @Override
                    public void onPickSongItemClick(KaraokeMusicInfo info, int layoutPosition) {
                        if (lastClickTime > 0) {
                            long current = System.currentTimeMillis();
                            if (current - lastClickTime < 300) {
                                return;
                            }
                        }
                        lastClickTime = System.currentTimeMillis();
                        RecyclerView.ViewHolder holder = mRvList.findViewHolderForAdapterPosition(layoutPosition);
                        ProgressBar             bar    = null;
                        if (holder != null) {
                            bar = holder.itemView.findViewById(R.id.progress_bar_choose_song);
                        }
                        updateSelectedList(bar, info);
                    }
                });
        mRvList.setLayoutManager(new LinearLayoutManager(mContext, LinearLayoutManager.VERTICAL, false));
        mLibraryListAdapter.setHasStableIds(true);
        mRvList.setAdapter(mLibraryListAdapter);
        mLibraryListAdapter.notifyDataSetChanged();

        //先获取热门歌曲分类列表
        mKtvMusicImpl.ktvGetPopularMusic(new KaraokeMusicCallback.PopularMusicListCallback() {
            @Override
            public void onCallBack(List<KaraokePopularInfo> list) {
                mPopularList.clear();
                mPopularList.addAll(list);
                if (mPopularList.size() > 0) {
                    KaraokePopularInfo info = mPopularList.get(0);
                    getMusicLibraryList(info.playlistId);
                }
            }
        });
    }

    //获取到分类列表后去加载详细的歌曲列表信息
    private void getMusicLibraryList(String playlistId) {
        mKtvMusicImpl.ktvGetMusicPage(playlistId, mPage, mLoadPageSize, new KaraokeMusicCallback.MusicListCallback() {
            @Override
            public void onCallback(int code, String msg, List<KaraokeMusicInfo> list) {
                mLibraryLists.clear();
                for (KaraokeMusicInfo info : list) {
                    KaraokeMusicModel model = new KaraokeMusicModel();
                    model.userId = info.userId;
                    model.musicId = info.musicId;
                    model.musicName = info.musicName;
                    model.singers = info.singers;
                    model.originUrl = info.originUrl;
                    model.accompanyUrl = info.accompanyUrl;
                    model.coverUrl = info.coverUrl;
                    model.lrcUrl = info.lrcUrl;
                    model.isSelected = false;
                    mLibraryLists.add(model);
                }
                if (mLibraryListAdapter != null) {
                    mLibraryListAdapter.notifyDataSetChanged();
                }
                if (mProgressBar != null) {
                    mProgressBar.setVisibility(GONE);
                }
            }
        });
    }

    private void initView(Context context) {
        View rootView = LayoutInflater.from(context).inflate(R.layout.trtckaraoke_fragment_library_view, this);
        mRvList = (RecyclerView) rootView.findViewById(R.id.rl_library);
        mProgressBar = findViewById(R.id.progress_group_library);
        mProgressBar.setVisibility(VISIBLE);
    }

    private void initLisenter() {
        //增加搜索框
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

    private void updateSelectedList(final ProgressBar bar, final KaraokeMusicInfo info) {
        mKtvMusicImpl.downLoadMusic(info, new KaraokeMusicCallback.MusicLoadingCallback() {
            @Override
            public void onStart(KaraokeMusicInfo musicInfo) {
            }

            @Override
            public void onProgress(KaraokeMusicInfo musicInfo, float progress) {
                publishProgress(bar, musicInfo.musicId, progress);
            }

            @Override
            public void onFinish(KaraokeMusicInfo musicInfo, int errorCode, String errorMessage) {
                if (errorCode != 0 || musicInfo == null) {
                    Log.d(TAG, "downloadMusic failed errorCode = " + errorCode + " , errorMessage = " + errorMessage);
                    ToastUtils.showShort(errorMessage);
                    return;
                }
                info.lrcUrl = musicInfo.lrcUrl;
                publishProgress(bar, musicInfo.musicId, 100);
                //歌词下载完后,更新已点map的lrcUrl
                KaraokeMusicModel model = mUserSelectMap.get(musicInfo.musicId);
                if (model != null) {
                    model.lrcUrl = musicInfo.lrcUrl;
                }
                mMainHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        mLibraryListAdapter.notifyDataSetChanged();
                    }
                });
            }
        });

        mKtvMusicImpl.pickMusic(info, new KaraokeMusicCallback.ActionCallback() {
            @Override
            public void onCallback(int code, String msg) {
                Log.d(TAG, "updateSelectedList : code = " + code + " , msg = " + msg);
            }
        });
    }

    private void publishProgress(final ProgressBar progressBar, String id, final float progress) {
        if (progressBar == null || id == null) {
            return;
        }

        int curProgress = (int) (progress * 100);
        if (curProgress < 0) {
            curProgress = 0;
        }
        if (curProgress > 100) {
            curProgress = 100;
        }
        final int finalCurProgress = curProgress;
        progressBar.post(new Runnable() {
            @Override
            public void run() {
                progressBar.setProgress(finalCurProgress);
            }
        });
    }

    @Override
    public void OnMusicListChange(List<KaraokeMusicModel> musicInfoList) {
        if (mLibraryLists == null || musicInfoList == null) {
            Log.d(TAG, "OnMusicListChange: list is error");
            return;
        }
        String userId = mRoomInfoController.getSelfUserId();

        //先清空
        mUserSelectMap.clear();
        //将当前用户点过的歌保存,其他人的不保存,这样musicId就是唯一的
        for (KaraokeMusicModel temp : musicInfoList) {
            if (temp == null || userId == null) {
                continue;
            }
            if (userId.equals(temp.userId)) {
                mUserSelectMap.put(temp.musicId, temp);
            }
        }
        //列表更新后,将当前用户点的歌态置为已点
        for (KaraokeMusicModel model : mLibraryLists) {
            if (model == null || model.musicId == null) {
                continue;
            }
            KaraokeMusicModel selectModel = mUserSelectMap.get(model.musicId);
            model.isSelected = (selectModel != null);
        }
        mRoomInfoController.setUserSelectMap(mUserSelectMap);
        mLibraryListAdapter.notifyDataSetChanged();
    }

    @Override
    public void onShouldSetLyric(KaraokeMusicModel model) {

    }

    @Override
    public void onShouldPlay(KaraokeMusicModel model) {

    }

    @Override
    public void onShouldStopPlay(KaraokeMusicModel model) {

    }

    @Override
    public void onShouldShowMessage(KaraokeMusicModel model) {

    }
}

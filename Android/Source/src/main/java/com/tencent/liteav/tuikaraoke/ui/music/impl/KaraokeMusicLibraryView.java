package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;
import android.support.design.widget.CoordinatorLayout;
import android.support.v7.widget.GridLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.view.LayoutInflater;
import android.view.View;

import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicCallback;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicServiceDelegate;


import java.util.ArrayList;
import java.util.List;

public class KaraokeMusicLibraryView extends CoordinatorLayout implements KaraokeMusicServiceDelegate {
    private final Context                    mContext;
    private       KaraokeMusicLibraryAdapter mLibraryListAdapter;
    private       List<KaraokeMusicModel>    mLibraryLists;
    private final KaraokeMusicService        mKtvMusicImpl;
    private       int                        mPage         = 1;
    private       int                        mLoadPageSize = 10;

    public KaraokeMusicLibraryView(Context context, KaraokeMusicService musicService) {
        super(context);
        mContext = context;
        mKtvMusicImpl = musicService;
        mKtvMusicImpl.setServiceDelegate(this);
        mLibraryLists = new ArrayList<>();
        mKtvMusicImpl.ktvGetMusicPage(mPage, mLoadPageSize, new KaraokeMusicCallback.MusicListCallback() {
            @Override
            public void onCallback(int code, String msg, List<KaraokeMusicInfo> list) {
                mLibraryLists.clear();
                for (KaraokeMusicInfo info : list) {
                    KaraokeMusicModel model = new KaraokeMusicModel();
                    model.musicId = info.musicId;
                    model.musicName = info.musicName;
                    model.singer = info.singer;
                    model.contentUrl = info.contentUrl;
                    model.coverUrl = info.coverUrl;
                    model.lrcUrl = info.lrcUrl;
                    model.isSelected = false;
                    mLibraryLists.add(model);
                }
            }
        });
        View rootView = LayoutInflater.from(context).inflate(R.layout.trtckaraoke_fragment_library_view, this);
        initView(rootView);
    }

    private void initView(View rootView) {
        RecyclerView rvList = (RecyclerView) rootView.findViewById(R.id.rl_library);
        mLibraryListAdapter = new KaraokeMusicLibraryAdapter(mContext, mLibraryLists,
                new KaraokeMusicLibraryAdapter.OnPickItemClickListener() {
                    @Override
                    public void onPickSongItemClick(String musicId, int layoutPosition) {
                        updateSelectedList(musicId);
                    }
                });
        rvList.setLayoutManager(new GridLayoutManager(mContext, 1));
        rvList.setAdapter(mLibraryListAdapter);
        mLibraryListAdapter.notifyDataSetChanged();
    }

    private void updateSelectedList(String musicId) {
        mKtvMusicImpl.pickMusic(musicId, new KaraokeMusicCallback.ActionCallback() {
            @Override
            public void onCallback(int code, String msg) {

            }
        });
    }

    @Override
    public void OnMusicListChange(List<KaraokeMusicModel> musicInfoList) {
        for (int i = 0; i < mLibraryLists.size(); i++) {
            boolean flag = false;
            for (int j = 0; j < musicInfoList.size(); j++) {
                if (mLibraryLists.get(i).musicId.equals(musicInfoList.get(j).musicId)) {
                    flag = true;
                }
            }
            mLibraryLists.get(i).isSelected = flag;
        }
        mLibraryListAdapter.notifyDataSetChanged();
    }

    @Override
    public void onShouldSetLyric(String musicID) {

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

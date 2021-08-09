package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;
import android.support.design.widget.CoordinatorLayout;
import android.support.v7.widget.LinearLayoutManager;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;

import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicCallback;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicServiceDelegate;
import com.tencent.liteav.tuikaraoke.ui.widget.SlideRecyclerView;

import java.util.ArrayList;
import java.util.List;

public class KaraokeMusicSelectView extends CoordinatorLayout implements KaraokeMusicServiceDelegate {
    private final String                      TAG = "KaraokeMusicSelectView";
    private final Context                     mContext;
    private       SlideRecyclerView           mRvList;
    private       KaraokeMusicSelectedAdapter mSelectedAdapter;
    private       List<KaraokeMusicModel>     mSelectedList;
    private final KaraokeMusicService         mKtvMusicImpl;

    private long lastCLickTime = -1;

    public KaraokeMusicSelectView(Context context, KaraokeMusicService musicService) {
        super(context);
        mContext = context;
        mKtvMusicImpl = musicService;
        mKtvMusicImpl.setServiceDelegate(this);
        mSelectedList = new ArrayList<>();
        mKtvMusicImpl.ktvGetSelectedMusicList(new KaraokeMusicCallback.MusicSelectedListCallback() {
            @Override
            public void onCallback(int code, String msg, List<KaraokeMusicModel> list) {
                mSelectedList.clear();
                mSelectedList.addAll(list);
            }
        });
        View rootView = LayoutInflater.from(context).inflate(R.layout.trtckaraoke_fragment_selected_view, this);
        initView(rootView);
    }

    private void initView(View rootView) {
        mRvList = (SlideRecyclerView) rootView.findViewById(R.id.rl_select);
        mSelectedAdapter = new KaraokeMusicSelectedAdapter(mContext, mSelectedList, new KaraokeMusicSelectedAdapter.OnUpdateItemClickListener() {
            @Override
            public void onNextSongClick(String id) {
                if (lastCLickTime > 0) {
                    long current = System.currentTimeMillis();
                    if (current - lastCLickTime < 300) {
                        return;
                    }
                }
                lastCLickTime = System.currentTimeMillis();
                mKtvMusicImpl.nextMusic(new KaraokeMusicCallback.ActionCallback() {
                    @Override
                    public void onCallback(int code, String msg) {
                        Log.d(TAG, "nextMusic: code = " + code);
                    }
                });
            }

            @Override
            public void onSetTopClick(String musicId) {
                mKtvMusicImpl.topMusic(musicId, new KaraokeMusicCallback.ActionCallback() {
                    @Override
                    public void onCallback(int code, String msg) {
                        Log.d(TAG, "topMusic: code = " + code);
                    }
                });
            }
        });
        mSelectedAdapter.setOnDeleteClickListener(new KaraokeMusicSelectedAdapter.OnDeleteClickLister() {
            @Override
            public void onDeleteClick(View view, int position) {
                if (mSelectedList.size() > 1) {
                    mKtvMusicImpl.deleteMusic(mSelectedList.get(position).musicId, new KaraokeMusicCallback.ActionCallback() {
                        @Override
                        public void onCallback(int code, String msg) {
                            Log.d(TAG, "deleteMusic: code = " + code);
                        }
                    });
                    mRvList.closeMenu();
                }
            }
        });
        mRvList.setLayoutManager(new LinearLayoutManager(mContext, LinearLayoutManager.VERTICAL, false));
        mRvList.setAdapter(mSelectedAdapter);
    }

    @Override
    public void OnMusicListChange(List<KaraokeMusicModel> musicInfoList) {
        mSelectedList.clear();
        mSelectedList.addAll(musicInfoList);
        mSelectedAdapter.notifyDataSetChanged();
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

package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;
import androidx.coordinatorlayout.widget.CoordinatorLayout;
import androidx.recyclerview.widget.LinearLayoutManager;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;

import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicCallback;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicServiceDelegate;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;
import com.tencent.liteav.tuikaraoke.ui.widget.SlideRecyclerView;

import java.util.ArrayList;
import java.util.List;

public class KaraokeMusicSelectView extends CoordinatorLayout implements KaraokeMusicServiceDelegate {
    private final String  TAG = "KaraokeMusicSelectView";
    private final Context mContext;

    private KaraokeMusicSelectedAdapter mSelectedAdapter;
    private List<KaraokeMusicModel>     mSelectedList;
    private KaraokeMusicService         mKtvMusicImpl;
    private RoomInfoController          mRoomInfoController;
    private SlideRecyclerView           mRvList;
    private long                        lastClickTime = -1;

    public KaraokeMusicSelectView(Context context, RoomInfoController roomInfoController) {
        super(context);
        mContext = context;
        mRoomInfoController = roomInfoController;
        mKtvMusicImpl = roomInfoController.getMusicServiceImpl();
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
        mSelectedAdapter = new KaraokeMusicSelectedAdapter(mContext, mRoomInfoController, mSelectedList, new KaraokeMusicSelectedAdapter.OnUpdateItemClickListener() {
            @Override
            public void onNextSongClick(KaraokeMusicInfo musicInfo) {
                if (lastClickTime > 0) {
                    long current = System.currentTimeMillis();
                    if (current - lastClickTime < 300) {
                        return;
                    }
                }
                lastClickTime = System.currentTimeMillis();
                mKtvMusicImpl.nextMusic(musicInfo, new KaraokeMusicCallback.ActionCallback() {
                    @Override
                    public void onCallback(int code, String msg) {
                        Log.d(TAG, "nextMusic onProgress: code = " + code);
                    }
                });
            }

            @Override
            public void onSetTopClick(KaraokeMusicInfo musicInfo) {
                mKtvMusicImpl.topMusic(musicInfo, new KaraokeMusicCallback.ActionCallback() {
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
                    mKtvMusicImpl.deleteMusic(mSelectedList.get(position), new KaraokeMusicCallback.ActionCallback() {
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

package com.tencent.liteav.tuikaraoke.ui.music.impl;

import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_DELETE_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_INFO_KEY;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_STOP_MUSIC_EVENT;

import android.content.Context;

import androidx.coordinatorlayout.widget.CoordinatorLayout;
import androidx.fragment.app.FragmentActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.view.LayoutInflater;
import android.view.View;

import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicServiceObserver;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;
import com.tencent.liteav.tuikaraoke.ui.widget.ConfirmDialogFragment;
import com.tencent.liteav.tuikaraoke.ui.widget.SlideRecyclerView;
import com.tencent.qcloud.tuicore.TUICore;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class KaraokeMusicSelectView extends CoordinatorLayout implements KaraokeMusicServiceObserver {
    private static final String TAG = "KaraokeMusicSelectView";

    private final Context mContext;

    private KaraokeMusicSelectedAdapter mSelectedAdapter;
    private List<KaraokeMusicInfo>      mSelectedList;
    private KaraokeMusicService         mKtvMusicImpl;
    private RoomInfoController          mRoomInfoController;
    private SlideRecyclerView           mRvList;
    private long                        lastClickTime = -1;

    private ConfirmDialogFragment       mDeleteConfirmFragment;

    public KaraokeMusicSelectView(Context context, RoomInfoController roomInfoController) {
        super(context);
        mContext = context;
        mRoomInfoController = roomInfoController;
        mKtvMusicImpl = roomInfoController.getMusicServiceImpl();
        mKtvMusicImpl.addObserver(this);
        mSelectedList = new ArrayList<>();
        for (KaraokeMusicInfo info : mRoomInfoController.getUserSelectMap().values()) {
            mSelectedList.add(info);
        }
        View rootView = LayoutInflater.from(context).inflate(R.layout.trtckaraoke_fragment_selected_view, this);
        initView(rootView);
    }

    private void initView(View rootView) {
        mRvList = (SlideRecyclerView) rootView.findViewById(R.id.rl_select);
        mSelectedAdapter = new KaraokeMusicSelectedAdapter(mContext,
                mRoomInfoController,
                mSelectedList,
                new KaraokeMusicSelectedAdapter.OnUpdateItemClickListener() {
                    @Override
                    public void onNextSongClick(KaraokeMusicInfo musicInfo) {
                        if (lastClickTime > 0) {
                            long current = System.currentTimeMillis();
                            if (current - lastClickTime < 300) {
                                return;
                            }
                        }
                        lastClickTime = System.currentTimeMillis();
                        if (mRvList.isMenuShowing()) {
                            mRvList.closeMenu();
                        }
                        Map<String, Object> params = new HashMap<>();
                        params.put(KARAOKE_MUSIC_INFO_KEY, musicInfo);
                        TUICore.notifyEvent(KARAOKE_MUSIC_EVENT, KARAOKE_STOP_MUSIC_EVENT, params);
                        TUICore.notifyEvent(KARAOKE_MUSIC_EVENT, KARAOKE_DELETE_MUSIC_EVENT, params);
                        mKtvMusicImpl.switchMusicFromPlaylist(musicInfo, null);
                    }

                    @Override
                    public void onSetTopClick(KaraokeMusicInfo musicInfo) {
                        if (mRvList.isMenuShowing()) {
                            mRvList.closeMenu();
                            return;
                        }
                        mKtvMusicImpl.topMusic(musicInfo, null);
                    }
                });
        mSelectedAdapter.setOnDeleteClickListener(new KaraokeMusicSelectedAdapter.OnDeleteClickLister() {
            @Override
            public void onDeleteClick(View view, int position) {
                if (mSelectedList.size() <= 1) {
                    return;
                }
                KaraokeMusicInfo musicInfo = mSelectedList.get(position);
                showDeleteConfirmDialog(musicInfo);
            }
        });
        mSelectedAdapter.setOnItemClickListener(new KaraokeMusicSelectedAdapter.OnItemClickListener() {
            @Override
            public void onItemClick(RecyclerView.Adapter adapter, View v, int position) {
                if (mRvList.isMenuShowing()) {
                    mRvList.closeMenu();
                }
            }
        });
        mRvList.setLayoutManager(new LinearLayoutManager(mContext, LinearLayoutManager.VERTICAL, false));
        mRvList.setAdapter(mSelectedAdapter);
    }

    private void showDeleteConfirmDialog(KaraokeMusicInfo musicInfo) {
        if (musicInfo == null) {
            return;
        }
        if (mDeleteConfirmFragment == null) {
            mDeleteConfirmFragment = new ConfirmDialogFragment();
            ConfirmDialogFragment fragment = mDeleteConfirmFragment;
            fragment.setPositiveButtonText(mContext.getString(R.string.trtckaraoke_delete));
            fragment.setNegativeButtonText(mContext.getString(R.string.trtckaraoke_dialog_cancel));
            int buttonColor = mContext.getResources().getColor(R.color.trtckaraoke_color_bg_text_bottom);
            fragment.setNegativeTextColor(buttonColor);
            fragment.setPositiveTextColor(buttonColor);
            fragment.setMessageUseBoldStyle(false);
        }
        mDeleteConfirmFragment.setPositiveClickListener(() -> {
            deleteKaraokeMusicInfo(musicInfo);
            mRvList.closeMenu();
            mDeleteConfirmFragment.dismiss();
        });
        mDeleteConfirmFragment.setNegativeClickListener(() -> {
            mRvList.closeMenu();
            mDeleteConfirmFragment.dismiss();
        });
        String message = mContext.getString(R.string.trtckaraoke_confirm_to_delete_music, musicInfo.musicName);
        mDeleteConfirmFragment.setMessage(message);
        mDeleteConfirmFragment.show(
                ((FragmentActivity) mContext).getFragmentManager(),
                "confirm_delete_music_from_list");
    }

    private void deleteKaraokeMusicInfo(KaraokeMusicInfo musicInfo) {
        mKtvMusicImpl.deleteMusicFromPlaylist(musicInfo, null);
        Map<String, Object> params = new HashMap<>();
        params.put(KARAOKE_MUSIC_INFO_KEY, musicInfo);
        TUICore.notifyEvent(KARAOKE_MUSIC_EVENT, KARAOKE_DELETE_MUSIC_EVENT, params);
    }

    @Override
    public void onMusicListChanged(List<KaraokeMusicInfo> musicInfoList) {
        mSelectedList.clear();
        mSelectedList.addAll(musicInfoList);
        mSelectedAdapter.notifyDataSetChanged();
    }
}

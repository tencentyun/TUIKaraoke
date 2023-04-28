package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.tencent.liteav.tuikaraoke.ui.utils.Toast;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;
import com.tencent.liteav.tuikaraoke.ui.widget.RoundCornerImageView;
import com.tencent.liteav.tuikaraoke.ui.widget.TextProgressBar;

import java.util.List;

public class KaraokeMusicSearchAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    protected Context                 mContext;
    protected List<KaraokeMusicInfo>  mSearchList;
    protected OnPickItemClickListener onPickItemClickListener;
    private   RoomInfoController      mRoomInfoController;

    //点歌列表歌曲封面
    private static final int[] MUSIC_ICON_ARRAY = {
            R.drawable.trtckaraoke_changetype_child_normal,
            R.drawable.trtckaraoke_changetype_dashu_normal,
            R.drawable.trtckaraoke_changetype_luoli_normal
    };
    private static final int   NORMAL_TYPE      = 0;    //列表布局
    private static final int   FOOT_TYPE        = 1111; //底部布局
    private              int   mFootStatus      = KaraokeSearchMusicActivity.STATE_NONE; //底部布局状态

    public KaraokeMusicSearchAdapter(Context context,
                                     RoomInfoController roomInfoController,
                                     List<KaraokeMusicInfo> searchList,
                                     OnPickItemClickListener onPickItemClickListener) {
        this.mContext = context;
        this.mSearchList = searchList;
        this.mRoomInfoController = roomInfoController;
        this.onPickItemClickListener = onPickItemClickListener;
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        Context context = parent.getContext();
        LayoutInflater inflater = LayoutInflater.from(context);
        if (NORMAL_TYPE == viewType) {
            View view = inflater.inflate(R.layout.trtckaraoke_fragment_library_itemview, parent, false);
            return new ViewHolder(view);
        } else if (FOOT_TYPE == viewType) {
            View footView = inflater.inflate(R.layout.trtckaraoke_fragment_load_more_item, parent, false);
            return new FootViewHolder(footView);
        }
        return null;
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        if (holder instanceof ViewHolder) {
            KaraokeMusicInfo item = mSearchList.get(position);
            ((ViewHolder) holder).bind(item, onPickItemClickListener);
        } else if (holder instanceof FootViewHolder) {
            ((FootViewHolder) holder).updateLoadMoreView(position);
        }
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public int getItemCount() {
        if (mSearchList == null) {
            return 0;
        }
        return mSearchList.size() + 1;
    }

    @Override
    public int getItemViewType(int position) {
        if (position == (getItemCount() - 1)) {
            return FOOT_TYPE;
        } else {
            return NORMAL_TYPE;
        }
    }

    public void setFooterViewState(int status) {
        mFootStatus = status;
    }

    public class ViewHolder extends RecyclerView.ViewHolder {
        private RoundCornerImageView mImageCover;
        private TextView             mTvSongName;
        private TextView             mTvSinger;
        private TextProgressBar      mProgressBarChoose;

        public ViewHolder(View itemView) {
            super(itemView);
            initView(itemView);
        }

        private void initView(final View itemView) {
            mImageCover = (RoundCornerImageView) itemView.findViewById(R.id.img_cover);
            mTvSongName = (TextView) itemView.findViewById(R.id.tv_song_name);
            mTvSinger = (TextView) itemView.findViewById(R.id.tv_singer);
            mProgressBarChoose = (TextProgressBar) itemView.findViewById(R.id.progress_bar_choose_song);
        }

        public void bind(final KaraokeMusicInfo model, final OnPickItemClickListener listener) {

            mProgressBarChoose.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (!mRoomInfoController.isRoomOwner()) {
                        Toast.show(R.string.trtckaraoke_toast_room_owner_can_operate_it, Toast.LENGTH_LONG);
                        return;
                    }
                    if (!mRoomInfoController.isAnchor()) {
                        Toast.show(R.string.trtckaraoke_toast_anchor_can_only_operate_it, Toast.LENGTH_LONG);
                        return;
                    }
                    mProgressBarChoose.setEnabled(false);
                    listener.onPickSongItemClick(model, getLayoutPosition());
                }
            });
            updateChooseButton(model.isSelected);
            mTvSongName.setText(model.musicName);
            StringBuffer buffer = new StringBuffer();
            for (String str : model.singers) {
                buffer.append(str);
            }
            mTvSinger.setText(buffer);
            if (model.isSelected && model.isPreloaded() && mProgressBarChoose.getProgress() != 100) {
                //首次加载时遇到已经下载过的歌曲，也要主动设置成下载完成的状态（因为无法靠下载回调来更新）
                mProgressBarChoose.setEnabled(false);
                mProgressBarChoose.setProgress(100);
            }
            int index = getAdapterPosition() % 3;
            mImageCover.setImageResource(MUSIC_ICON_ARRAY[index]);
        }

        public void updateChooseButton(boolean isSelect) {
            if (isSelect) {
                mProgressBarChoose.setText(mContext.getText(R.string.trtckaraoke_btn_choosed_song));
                mProgressBarChoose.setEnabled(false);
            } else {
                mProgressBarChoose.setText(mContext.getText(R.string.trtckaraoke_btn_choose_song));
                mProgressBarChoose.setEnabled(true);
                mProgressBarChoose.setProgress(0);
            }
        }
    }

    public interface OnPickItemClickListener {
        void onPickSongItemClick(KaraokeMusicInfo info, int layoutPosition);
    }

    public class FootViewHolder extends RecyclerView.ViewHolder {

        private final TextView mTextLoadMore;

        public FootViewHolder(View itemView) {
            super(itemView);
            mTextLoadMore = itemView.findViewById(R.id.tv_loadmore);
        }

        public void updateLoadMoreView(int postion) {
            //没有数据时会隐藏
            mTextLoadMore.setVisibility(View.VISIBLE);
            if (postion == 0) {
                if (mFootStatus == KaraokeSearchMusicActivity.STATE_NONE) {
                    mTextLoadMore.setText("");
                } else if (mFootStatus == KaraokeSearchMusicActivity.STATE_LASTED) {
                    mTextLoadMore.setText(R.string.trtckaraoke_loading_no_data);
                }
            } else {
                if (mFootStatus == KaraokeSearchMusicActivity.STATE_LOADING) {
                    mTextLoadMore.setText(R.string.trtckaraoke_loading_more_music);
                } else if (mFootStatus == KaraokeSearchMusicActivity.STATE_LASTED) {
                    mTextLoadMore.setText(R.string.trtckaraoke_loading_no_more_data);
                } else if (mFootStatus == KaraokeSearchMusicActivity.STATE_ERROR) {
                    mTextLoadMore.setText(R.string.trtckaraoke_loading_error);
                } else {
                    mTextLoadMore.setText("");
                }
            }
        }
    }
}

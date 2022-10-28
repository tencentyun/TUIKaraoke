package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.blankj.utilcode.util.ToastUtils;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;
import com.tencent.liteav.tuikaraoke.ui.widget.RoundCornerImageView;

import java.util.List;

public class KaraokeMusicSearchAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    protected Context                 mContext;
    protected List<KaraokeMusicModel> mSearchList;
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
                                     List<KaraokeMusicModel> searchList,
                                     OnPickItemClickListener onPickItemClickListener) {
        this.mContext = context;
        this.mSearchList = searchList;
        this.mRoomInfoController = roomInfoController;
        this.onPickItemClickListener = onPickItemClickListener;
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
            holder.setIsRecyclable(false);
            KaraokeMusicModel item = mSearchList.get(position);
            ((ViewHolder) holder).bind(mContext, item, onPickItemClickListener);
        } else if (holder instanceof FootViewHolder) {
            ((FootViewHolder) holder).updateLoadMoreView(position);
        }
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
        private Button               mBtnChoose;
        private ProgressBar          mProgressBarChoose;
        private boolean              mSelect = false;

        public ViewHolder(View itemView) {
            super(itemView);
            initView(itemView);
        }

        private void initView(final View itemView) {
            mImageCover = (RoundCornerImageView) itemView.findViewById(R.id.img_cover);
            mTvSongName = (TextView) itemView.findViewById(R.id.tv_song_name);
            mTvSinger = (TextView) itemView.findViewById(R.id.tv_singer);
            mBtnChoose = (Button) itemView.findViewById(R.id.btn_choose_song);
            mProgressBarChoose = (ProgressBar) itemView.findViewById(R.id.progress_bar_choose_song);
        }

        public void bind(Context context, final KaraokeMusicModel model,
                         final OnPickItemClickListener listener) {

            mBtnChoose.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (!mRoomInfoController.isRoomOwner()) {
                        ToastUtils.showLong(R.string.trtckaraoke_toast_room_owner_can_operate_it);
                        return;
                    }
                    if (!mRoomInfoController.isAnchor()) {
                        ToastUtils.showLong(R.string.trtckaraoke_toast_anchor_can_only_operate_it);
                        return;
                    }
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
            int index = getAdapterPosition() % 3;
            mImageCover.setImageResource(MUSIC_ICON_ARRAY[index]);
            if (model.isSelected && model.lrcUrl != null && mProgressBarChoose.getProgress() != 100) {
                mProgressBarChoose.setProgress(100);
            }
        }

        public void updateChooseButton(boolean isSelect) {
            if (isSelect) {
                mBtnChoose.setText(mContext.getText(R.string.trtckaraoke_btn_choosed_song));
                mBtnChoose.setBackgroundResource(R.drawable.trtckaraoke_button_choose_song);
                mBtnChoose.setTextColor(mContext.getResources().getColor(R.color.trtckaraoke_text_color_second));
                mBtnChoose.setEnabled(false);
                mSelect = true;
            } else {
                mBtnChoose.setText(mContext.getText(R.string.trtckaraoke_btn_choose_song));
                mBtnChoose.setBackgroundResource(R.drawable.trtckaraoke_button_border);
                mBtnChoose.setEnabled(true);
                mSelect = false;
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

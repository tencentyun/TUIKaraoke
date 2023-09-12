package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.tencent.liteav.basic.ImageLoader;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;
import com.tencent.liteav.tuikaraoke.ui.utils.Toast;
import com.tencent.liteav.tuikaraoke.ui.widget.RoundCornerImageView;
import com.tencent.liteav.tuikaraoke.ui.widget.TextProgressBar;

import java.util.List;

public class KaraokeMusicLibraryAdapter extends RecyclerView.Adapter<KaraokeMusicLibraryAdapter.ViewHolder> {
    protected Context                 mContext;
    protected List<KaraokeMusicInfo>  mLibraryList;
    protected OnPickItemClickListener onPickItemClickListener;
    private   RoomInfoController      mRoomInfoController;

    public KaraokeMusicLibraryAdapter(Context context, RoomInfoController roomInfoController,
                                      List<KaraokeMusicInfo> libraryList,
                                      OnPickItemClickListener onPickItemClickListener) {
        this.mContext = context;
        this.mLibraryList = libraryList;
        this.mRoomInfoController = roomInfoController;
        this.onPickItemClickListener = onPickItemClickListener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        Context context = parent.getContext();
        LayoutInflater inflater = LayoutInflater.from(context);
        View view = inflater.inflate(R.layout.trtckaraoke_fragment_library_itemview, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        KaraokeMusicInfo item = mLibraryList.get(position);
        holder.bind(item, onPickItemClickListener);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public int getItemCount() {
        if (mLibraryList == null) {
            return 0;
        }
        return mLibraryList.size();
    }

    @Override
    public int getItemViewType(int position) {
        return position;
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
                        Toast.show(v, R.string.trtckaraoke_toast_room_owner_can_operate_it, Toast.LENGTH_LONG);
                        return;
                    }
                    if (!mRoomInfoController.isAnchor()) {
                        Toast.show(v, R.string.trtckaraoke_toast_anchor_can_only_operate_it, Toast.LENGTH_LONG);
                        return;
                    }
                    mProgressBarChoose.setEnabled(false);
                    listener.onPickSongItemClick(model, getAdapterPosition());
                }
            });
            updateChooseButton(model.isSelected);
            mTvSongName.setText(model.musicName);
            StringBuffer buffer = new StringBuffer();
            for (String str : model.singers) {
                buffer.append(str);
            }
            mTvSinger.setText(buffer);
            if (model.isSelected && mProgressBarChoose.getProgress() != 100) {
                //首次加载时遇到已经下载过的歌曲，也要主动设置成下载完成的状态（因为无法靠下载回调来更新）
                mProgressBarChoose.setEnabled(false);
                mProgressBarChoose.setProgress(100);
            }
            ImageLoader.loadImage(mContext, mImageCover, model.coverUrl);
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

}

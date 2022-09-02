package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;

import androidx.recyclerview.widget.RecyclerView;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.TextView;

import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;
import com.tencent.liteav.tuikaraoke.ui.widget.RoundCornerImageView;
import com.tencent.liteav.basic.ImageLoader;

import java.util.List;

public class KaraokeMusicSelectedAdapter extends RecyclerView.Adapter<KaraokeMusicSelectedAdapter.ViewHolder>
        implements View.OnClickListener {
    protected Context                   mContext;
    protected List<KaraokeMusicModel>   mSelectedList;
    protected OnUpdateItemClickListener mOnUpdateItemClickListener;
    private   OnDeleteClickLister       mDeleteClickListener;
    private   OnItemClickListener       mListener;
    private   RoomInfoController        mRoomInfoController;

    public KaraokeMusicSelectedAdapter(Context context,
                                       RoomInfoController roomInfoController,
                                       List<KaraokeMusicModel> selectedList,
                                       OnUpdateItemClickListener listener) {
        this.mContext = context;
        this.mRoomInfoController = roomInfoController;
        this.mSelectedList = selectedList;
        this.mOnUpdateItemClickListener = listener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        Context context = parent.getContext();
        LayoutInflater inflater = LayoutInflater.from(context);
        View view = inflater.inflate(R.layout.trtckaraoke_fragment_selected_itemview, parent, false);
        view.setOnClickListener(this);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        KaraokeMusicInfo item = mSelectedList.get(holder.getAdapterPosition());
        holder.bind(mContext, position, item, mOnUpdateItemClickListener);
    }

    @Override
    public int getItemCount() {
        return mSelectedList.size();
    }

    public class ViewHolder extends RecyclerView.ViewHolder {
        private RoundCornerImageView mImageCover;
        private TextView             mTvSongID;
        private ImageView            mImgIcon;
        private TextView             mTvSongName;
        private TextView             mTvSinger;
        private ImageButton          mBtnNext;
        private ImageButton          mBtnSetTop;
        private TextView             mTvDelete;
        private TextView             mTvUserName;
        private TextView             mTvSeatName;

        public ViewHolder(View itemView) {
            super(itemView);
            initView(itemView);
        }

        private void initView(final View itemView) {
            mTvSongID = itemView.findViewById(R.id.tv_song_id);
            mImgIcon = itemView.findViewById(R.id.img_song_id);
            mImageCover = (RoundCornerImageView) itemView.findViewById(R.id.img_cover);
            mTvSongName = itemView.findViewById(R.id.tv_song_name);
            mTvSinger = itemView.findViewById(R.id.tv_singer);
            mBtnNext = itemView.findViewById(R.id.btn_nextsong);
            mBtnSetTop = itemView.findViewById(R.id.btn_set_top);
            mTvDelete = (TextView) itemView.findViewById(R.id.tv_delete);
            mTvUserName = (TextView) itemView.findViewById(R.id.tv_user_name);
            mTvSeatName = (TextView) itemView.findViewById(R.id.tv_seat_name);
        }

        public void bind(Context context, final int position, final KaraokeMusicInfo model,
                         final OnUpdateItemClickListener listener) {

            //共有信息
            mTvSongName.setText(model.musicName);
            mTvSinger.setText(mContext.getString(R.string.trtckaraoke_singer, model.singers));
            //根据用户Id,从麦位表获取当前歌曲的用户名和座位Id
            if (mRoomInfoController != null) {
                KaraokeRoomSeatEntity seatEntity = mRoomInfoController.getCurrentSeatEntity(model.userId);
                if (seatEntity != null) {
                    mTvUserName.setText(seatEntity.userName);
                    mTvSeatName.setText(context.getString(R.string.trtckaraoke_tv_seat_id,
                            String.valueOf(seatEntity.index + 1)));
                    ImageLoader.loadImage(context, mImageCover, seatEntity.userAvatar, R.drawable.trtckaraoke_ic_cover);
                }
            }

            //如果当前不是房主,只能查看已点列表
            if (mRoomInfoController != null && !mRoomInfoController.isRoomOwner()) {
                mBtnNext.setVisibility(View.GONE);
                mBtnSetTop.setVisibility(View.GONE);

                if (getAdapterPosition() == 0) {
                    mTvSongID.setVisibility(View.GONE);
                    mImgIcon.setVisibility(View.VISIBLE);
                    ImageLoader.loadGifImage(mContext, mImgIcon, R.drawable.trtckaraoke_bg_music);
                } else {
                    mImgIcon.setVisibility(View.GONE);
                    mTvSongID.setVisibility(View.VISIBLE);
                    mTvSongID.setText(String.valueOf(getAdapterPosition() + 1));
                }

                //判断是当前用户,可以删除自己的歌
                String mSelfUserID = UserModelManager.getInstance().getUserModel().userId;
                if (model.userId != null && model.userId.equals(mSelfUserID)) {
                    mTvDelete.setVisibility(View.VISIBLE);
                    if (!mTvDelete.hasOnClickListeners()) {
                        mTvDelete.setOnClickListener(new View.OnClickListener() {
                            @Override
                            public void onClick(View v) {
                                if (mDeleteClickListener != null) {
                                    mDeleteClickListener.onDeleteClick(v, getAdapterPosition());
                                }
                            }
                        });
                    }
                } else {
                    mTvDelete.setVisibility(View.GONE);
                }
            } else {
                //实现左滑删除
                if (!mTvDelete.hasOnClickListeners()) {
                    mTvDelete.setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View v) {
                            if (mDeleteClickListener != null) {
                                if (getLayoutPosition() != 0) {
                                    mDeleteClickListener.onDeleteClick(v, getAdapterPosition());
                                }
                            }
                        }
                    });
                }

                //处理第一首已点歌曲
                if (getAdapterPosition() == 0) {
                    mBtnNext.setVisibility(View.VISIBLE);
                    mBtnSetTop.setVisibility(View.GONE);
                    mTvSongID.setVisibility(View.GONE);
                    mImgIcon.setVisibility(View.VISIBLE);
                    ImageLoader.loadGifImage(mContext, mImgIcon, R.drawable.trtckaraoke_bg_music);
                } else if (getAdapterPosition() == 1) {
                    mBtnNext.setVisibility(View.GONE);
                    mBtnSetTop.setVisibility(View.VISIBLE);
                    mBtnSetTop.setBackgroundResource(R.drawable.trtckaraoke_ic_settop_normal);
                    mImgIcon.setVisibility(View.GONE);
                    mTvSongID.setVisibility(View.VISIBLE);
                    mTvSongID.setText(String.valueOf(getAdapterPosition() + 1));
                } else {
                    mBtnNext.setVisibility(View.GONE);
                    mBtnSetTop.setVisibility(View.VISIBLE);
                    mBtnSetTop.setBackgroundResource(R.drawable.trtckaraoke_ic_settop_hover);
                    mImgIcon.setVisibility(View.GONE);
                    mTvSongID.setVisibility(View.VISIBLE);
                    mTvSongID.setText(String.valueOf(getAdapterPosition() + 1));
                }

                mBtnNext.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        listener.onNextSongClick(model);
                    }
                });
                mBtnSetTop.setOnClickListener(new View.OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        if (position != 1) {
                            listener.onSetTopClick(model);
                        }
                    }
                });
            }
        }
    }

    public interface OnUpdateItemClickListener {
        void onNextSongClick(KaraokeMusicInfo musicInfo);

        void onSetTopClick(KaraokeMusicInfo musicInfo);
    }

    //左滑删除监听接口
    public void setOnDeleteClickListener(OnDeleteClickLister listener) {
        this.mDeleteClickListener = listener;
    }

    public interface OnDeleteClickLister {
        void onDeleteClick(View view, int position);
    }

    @Override
    public void onClick(View v) {
        if (mListener != null) {
            mListener.onItemClick(this, v, (Integer) v.getTag());
        }
    }

    public interface OnItemClickListener {
        void onItemClick(RecyclerView.Adapter adapter, View v, int position);
    }

    public void setOnItemClickListener(OnItemClickListener onItemClickListener) {
        this.mListener = onItemClickListener;
    }
}

package com.tencent.liteav.tuikaraoke.ui.room;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import com.tencent.liteav.basic.ImageLoader;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;

import java.util.List;

import de.hdodenhof.circleimageview.CircleImageView;

public class KaraokeRoomSeatAdapter extends
        RecyclerView.Adapter<KaraokeRoomSeatAdapter.ViewHolder> {
    private static String TAG     = KaraokeRoomSeatAdapter.class.getSimpleName();
    public static  String QUALITY = "quality";

    private Context context;

    private List<KaraokeRoomSeatEntity> list;
    private OnItemClickListener         onItemClickListener;

    private String mBaseHeadIcon = "https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar1.png";

    public KaraokeRoomSeatAdapter(Context context, List<KaraokeRoomSeatEntity> list,
                                  OnItemClickListener onItemClickListener) {
        this.context = context;
        this.list = list;
        this.onItemClickListener = onItemClickListener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        Context context = parent.getContext();
        LayoutInflater inflater = LayoutInflater.from(context);

        View view = inflater.inflate(R.layout.trtckaraoke_item_seat_layout, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        KaraokeRoomSeatEntity item = list.get(position);
        holder.bind(context, position, item, onItemClickListener);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position, List<Object> payloads) {
        if (payloads == null || payloads.size() == 0) {
            onBindViewHolder(holder, position);
        } else {
            if (QUALITY.equals(payloads.get(0))) {
                KaraokeRoomSeatEntity item = list.get(position);
                holder.setQuality(item);
            }
        }
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    public interface OnItemClickListener {
        void onItemClick(int position);
    }

    public class ViewHolder extends RecyclerView.ViewHolder {
        public CircleImageView mImgSeatHead;
        public CircleImageView mImgNetwork;
        public TextView        mTvName;
        public ImageView       mIvMute;
        public ImageView       mIvTalkBorder;

        public ViewHolder(View itemView) {
            super(itemView);
            initView(itemView);
        }

        public void bind(final Context context, int position,
                         final KaraokeRoomSeatEntity model,
                         final OnItemClickListener listener) {
            itemView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    listener.onItemClick(getLayoutPosition());

                }
            });
            if (model.isClose) {
                mImgSeatHead.setImageResource(R.drawable.trtckaraoke_ic_lock);
                mTvName.setText("");
                mIvMute.setVisibility(View.GONE);
                mIvTalkBorder.setVisibility(View.GONE);
                return;
            }
            if (!model.isUsed) {
                // 占位图片
                mImgSeatHead.setImageResource(R.drawable.trtckaraoke_add_seat);
                mTvName.setText(context.getResources().getString(R.string.trtckaraoke_tv_seat_id,
                        String.valueOf(position + 1)));
                mIvMute.setVisibility(View.GONE);
                mIvTalkBorder.setVisibility(View.GONE);
            } else {
                if (TextUtils.isEmpty(model.userAvatar) || !isUrl(model.userAvatar)) {
                    ImageLoader.loadImage(context, mImgSeatHead, mBaseHeadIcon, R.drawable.trtckaraoke_ic_cover);
                } else {
                    ImageLoader.loadImage(context.getApplicationContext(), mImgSeatHead,
                            model.userAvatar, R.drawable.trtckaraoke_ic_cover);
                }
                if (!TextUtils.isEmpty(model.userName)) {
                    mTvName.setText(model.userName);
                } else {
                    mTvName.setText(R.string.trtckaraoke_tv_the_anchor_name_is_still_looking_up);
                }
                boolean mute = model.isUserMute || model.isSeatMute;
                mIvMute.setVisibility(mute ? View.VISIBLE : View.GONE);
                if (mute) {
                    mIvTalkBorder.setVisibility(View.GONE);
                } else {
                    mIvTalkBorder.setVisibility(model.isTalk ? View.VISIBLE : View.GONE);
                }
            }
        }

        private void initView(@NonNull final View itemView) {
            mImgSeatHead = (CircleImageView) itemView.findViewById(R.id.img_seat_head);
            mTvName = (TextView) itemView.findViewById(R.id.tv_name);
            mIvMute = (ImageView) itemView.findViewById(R.id.iv_mute);
            mIvTalkBorder = (ImageView) itemView.findViewById(R.id.iv_talk_border);
            mImgNetwork = (CircleImageView) itemView.findViewById(R.id.img_network);
        }

        public void setQuality(KaraokeRoomSeatEntity entity) {
            if (entity.getQuality() == KaraokeRoomSeatEntity.QUALITY_BAD) {
                //显示网络差的图片
                if (entity.isUsed) {
                    mImgNetwork.setVisibility(View.VISIBLE);
                }
            } else {
                //信号质量可以,显示用户头像或默认头像
                if (entity.isUsed) {
                    mImgNetwork.setVisibility(View.GONE);
                }
            }
        }

        private boolean isUrl(String url) {
            return url.startsWith("http://") || url.startsWith("https://");
        }
    }
}
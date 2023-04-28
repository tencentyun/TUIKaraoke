package com.tencent.liteav.tuikaraoke.ui.audio;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import com.tencent.liteav.tuikaraoke.R;

import java.util.List;

import de.hdodenhof.circleimageview.CircleImageView;

public class RecyclerViewAdapter extends RecyclerView.Adapter<RecyclerViewAdapter.ViewHolder> {

    private Context             mContext;
    private List<Entity>        list;
    private OnItemClickListener onItemClickListener;

    public RecyclerViewAdapter(Context context, List<Entity> list,
                               OnItemClickListener onItemClickListener) {
        this.mContext = context;
        this.list = list;
        this.onItemClickListener = onItemClickListener;
    }

    public class ViewHolder extends RecyclerView.ViewHolder {
        private CircleImageView mItemImg;
        private TextView        mTitleTv;

        public ViewHolder(View itemView) {
            super(itemView);
            initView(itemView);
        }

        public void bind(final Entity model, final int position,
                         final OnItemClickListener listener) {
            mItemImg.setImageResource(model.mIconId);
            mTitleTv.setText(model.mTitle);
            if (model.mIsSelected) {
                mItemImg.setImageResource(model.mSelectIconId);
                mTitleTv.setTextColor(mContext.getResources().getColor(R.color.trtckaraoke_color_blue));
            } else {
                mItemImg.setImageResource(model.mIconId);
                mTitleTv.setTextColor(mContext.getResources().getColor(R.color.trtckaraoke_white));
            }
            itemView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    listener.onItemClick(position);
                }
            });
        }

        private void initView(final View itemView) {
            mItemImg = itemView.findViewById(R.id.img_item);
            mTitleTv = itemView.findViewById(R.id.tv_title);
        }
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        Context context = parent.getContext();
        LayoutInflater inflater = LayoutInflater.from(context);
        View view = inflater.inflate(R.layout.trtckaraoke_audio_main_entry_item, parent, false);
        ViewHolder viewHolder = new ViewHolder(view);
        return viewHolder;
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, final int position) {
        Entity item = list.get(position);
        holder.bind(item, position, onItemClickListener);
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    public interface OnItemClickListener {
        void onItemClick(int position);
    }
}
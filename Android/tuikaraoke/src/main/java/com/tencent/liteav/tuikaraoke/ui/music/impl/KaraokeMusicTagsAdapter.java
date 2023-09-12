package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;

import androidx.recyclerview.widget.RecyclerView;

import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicTag;

import java.util.List;

public class KaraokeMusicTagsAdapter extends RecyclerView.Adapter<KaraokeMusicTagsAdapter.ViewHolder> {
    private Context                 mContext;
    private List<KaraokeMusicTag>   mMusicTagList;
    private OnMusicTagClickListener mMusicTagClickListener;
    private int                     mSelectedPosition = 0;

    public KaraokeMusicTagsAdapter(Context context, List<KaraokeMusicTag> libraryList,
                                   OnMusicTagClickListener musicTagClickListener) {
        this.mContext = context;
        this.mMusicTagList = libraryList;
        this.mMusicTagClickListener = musicTagClickListener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        Context context = parent.getContext();
        LayoutInflater inflater = LayoutInflater.from(context);
        View view = inflater.inflate(R.layout.trtckaraoke_music_tags_recycle_item, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        KaraokeMusicTag item = mMusicTagList.get(position);
        holder.bind(item, position, mMusicTagClickListener);
    }

    @Override
    public int getItemCount() {
        if (mMusicTagList == null) {
            return 0;
        }
        return mMusicTagList.size();
    }

    @Override
    public int getItemViewType(int position) {
        return position;
    }

    public class ViewHolder extends RecyclerView.ViewHolder {
        private Button mButtonMusicTag;

        public ViewHolder(View itemView) {
            super(itemView);
            mButtonMusicTag = itemView.findViewById(R.id.button_music_tag);
        }

        public void bind(KaraokeMusicTag musicTag, int position, OnMusicTagClickListener listener) {
            boolean isSelected = (mSelectedPosition == position);
            mButtonMusicTag.setSelected(isSelected);
            mButtonMusicTag.setText(musicTag.name);
            mButtonMusicTag.setOnClickListener((View button) -> {
                if (mSelectedPosition == position) {
                    return;
                }
                mSelectedPosition = position;
                notifyDataSetChanged();
                listener.onMusicTagClick(musicTag, mSelectedPosition);
            });
        }

    }


    public interface OnMusicTagClickListener {
        void onMusicTagClick(KaraokeMusicTag musicTag, int position);
    }

}

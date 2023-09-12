package com.tencent.liteav.tuikaraoke.ui.pitch;

import android.app.Dialog;
import android.content.Context;
import android.graphics.LinearGradient;
import android.graphics.Shader;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.tencent.liteav.basic.ResourceUtils;
import com.tencent.liteav.tuikaraoke.R;

public class MusicScoreResultDialog extends Dialog {

    private TextView mMusicInfoView;
    private TextView mScoreView;

    private String mMusicInfo;
    private int    mScore;

    public MusicScoreResultDialog(@NonNull Context context) {
        super(context, R.style.TRTCKTVRoomDialogTheme);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.trtckaraoke_dialog_score);
        setCancelable(false);

        GradientDrawable backDrawable = new GradientDrawable();
        backDrawable.setColors(new int[]{0xFF271A25, 0xFF0B0023});
        backDrawable.setGradientType(GradientDrawable.LINEAR_GRADIENT);
        backDrawable.setOrientation(GradientDrawable.Orientation.TOP_BOTTOM);
        findViewById(R.id.rl_root).setBackground(backDrawable);

        // 设置关闭按钮圆角背景
        GradientDrawable closeBackDrawable = new GradientDrawable();
        closeBackDrawable.setColor(0x33FFFFFF);
        closeBackDrawable.setCornerRadius(ResourceUtils.dip2px(20));
        Button closeView = findViewById(R.id.tv_close);
        closeView.setBackground(closeBackDrawable);
        closeView.setOnClickListener(v -> dismiss());

        mMusicInfoView = findViewById(R.id.tv_music_info);
        setMusicInfo(mMusicInfo);

        // 设置分数字体颜色为渐变色
        mScoreView = findViewById(R.id.tv_score_value);
        mScoreView.measure(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        LinearGradient shaper = new LinearGradient(0, 0, 0, mScoreView.getMeasuredHeight(),
                new int[]{0xFF7D00BD, 0xFFFFBBDD}, null, Shader.TileMode.CLAMP);
        mScoreView.getPaint().setShader(shaper);
        setScore(mScore);
    }

    public void setMusicInfo(String musicInfo) {
        mMusicInfo = musicInfo;
        if (mMusicInfoView != null) {
            mMusicInfoView.setText(musicInfo);
        }
    }

    public void setScore(int score) {
        mScore = score;
        if (mScoreView != null) {
            mScoreView.setText(String.valueOf(score));
        }
    }

    @Override
    public void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        setMusicInfo("");
        setScore(0);
    }
}

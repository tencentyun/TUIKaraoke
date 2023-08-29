package com.tencent.liteav.tuikaraoke.ui.utils;

import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.TextView;

import androidx.annotation.StringRes;
import androidx.core.view.ViewCompat;

import com.google.android.material.snackbar.Snackbar;
import com.tencent.qcloud.tuicore.util.ScreenUtil;

/**
 * Karaoke 模块定制Toast
 * 要求：
 * - 居中显示
 */
public class Toast {

    private static final String TAG = "Toast";

    public static final int LENGTH_SHORT = Snackbar.LENGTH_SHORT;
    public static final int LENGTH_LONG = Snackbar.LENGTH_LONG;

    private static final GradientDrawable BACK_DRAWABLE = new GradientDrawable();
    private static final Handler MAIN_HANDLER = new Handler(Looper.getMainLooper());

    static {
        BACK_DRAWABLE.setColor(0xCC000000);
        BACK_DRAWABLE.setCornerRadius(20);
    }

    public static void show(View anchorView, @StringRes int resId, int duration) {
        if (anchorView == null) {
            return;
        }
        String message = anchorView.getResources().getString(resId);
        show(anchorView, message, duration);
    }

    public static void show(View anchorView, CharSequence message, int duration) {
        MAIN_HANDLER.post(() -> showSnackbar(anchorView, message, duration));
    }

    private static void showSnackbar(View anchorView, CharSequence message, int duration) {
        if (anchorView == null || !ViewCompat.isAttachedToWindow(anchorView)) {
            Log.e(TAG, "anchorView is null or not attached to window! anchorView:" + anchorView);
            return;
        }
        Snackbar snackbar = Snackbar.make(anchorView, message, duration);
        View view = snackbar.getView();
        view.setBackgroundColor(Color.TRANSPARENT);
        int padding = ScreenUtil.getScreenWidth(anchorView.getContext()) / 10;
        view.setPadding(padding, 0, padding, 0);
        TextView textView = view.findViewById(com.google.android.material.R.id.snackbar_text);
        if (textView != null) {
            textView.setTextColor(Color.WHITE);
            textView.setTextSize(16);
            textView.setGravity(Gravity.START);
            textView.setBackground(BACK_DRAWABLE);
            textView.setMaxLines(Integer.MAX_VALUE);
            textView.setEllipsize(null);
        }
        ViewGroup.LayoutParams params = view.getLayoutParams();
        params.width = ViewGroup.LayoutParams.WRAP_CONTENT;
        if (params instanceof FrameLayout.LayoutParams) {
            FrameLayout.LayoutParams params1 = (FrameLayout.LayoutParams) params;
            params1.gravity = Gravity.CENTER;
        }
        snackbar.show();
    }
}

package com.tencent.liteav.tuikaraoke.ui.utils;

import android.view.Gravity;

import androidx.annotation.StringRes;

import com.blankj.utilcode.util.ToastUtils;

/**
 * Karaoke 模块定制Toast
 * 要求：
 * - 居中显示
 */
public class Toast {

    public static final int LENGTH_SHORT = android.widget.Toast.LENGTH_SHORT;
    public static final int LENGTH_LONG = android.widget.Toast.LENGTH_LONG;

    private static final ToastUtils TOAST_MAKER = new ToastUtils();

    static {
        TOAST_MAKER.setGravity(Gravity.CENTER, 0, 0);
    }

    public static void show(CharSequence message, int duration) {
        TOAST_MAKER.setDurationIsLong(LENGTH_LONG == duration);
        TOAST_MAKER.show(message);
    }

    public static void show(@StringRes final int resId, int duration) {
        TOAST_MAKER.setDurationIsLong(LENGTH_LONG == duration);
        TOAST_MAKER.show(resId);
    }
}

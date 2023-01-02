package com.tencent.liteav.tuikaraoke.ui.utils;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.res.Resources;
import android.text.TextUtils;

import androidx.annotation.IntDef;

import com.tencent.liteav.tuikaraoke.R;
import com.tencent.qcloud.tuicore.util.PermissionRequester;

public class PermissionHelper {
    public static final int PERMISSION_MICROPHONE = 1;

    @IntDef({PERMISSION_MICROPHONE})
    public @interface PermissionType {
    }

    public static void requestPermission(Context context, @PermissionType int type, final PermissionCallback callback) {
        String permission = null;
        String reason = null;
        String reasonTitle = null;
        String deniedAlert = null;
        ApplicationInfo applicationInfo = context.getApplicationInfo();
        String appName = context.getPackageManager().getApplicationLabel(applicationInfo).toString();
        switch (type) {
            case PERMISSION_MICROPHONE: {
                permission = PermissionRequester.PermissionConstants.MICROPHONE;
                reasonTitle = context.getString(R.string.trtckaraoke_permission_mic_reason_title, appName);
                reason = context.getString(R.string.trtckaraoke_permission_mic_reason);
                deniedAlert = context.getString(R.string.trtckaraoke_tips_start_audio);
                break;
            }
            default:
                break;
        }

        PermissionRequester.SimpleCallback simpleCallback = new PermissionRequester.SimpleCallback() {
            @Override
            public void onGranted() {
                if (callback != null) {
                    callback.onGranted();
                }
            }

            @Override
            public void onDenied() {
                if (callback != null) {
                    callback.onDenied();
                }
            }
        };
        if (!TextUtils.isEmpty(permission)) {
            PermissionRequester.permission(permission)
                    .reason(reason)
                    .reasonTitle(reasonTitle)
                    .deniedAlert(deniedAlert)
                    .callback(simpleCallback)
                    .request();
        }
    }

    public interface PermissionCallback {
        void onGranted();

        void onDenied();
    }
}
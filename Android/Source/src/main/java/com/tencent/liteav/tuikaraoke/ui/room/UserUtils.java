package com.tencent.liteav.tuikaraoke.ui.room;

import android.content.Context;
import android.util.TypedValue;

import com.tencent.liteav.basic.UserModelManager;


public class UserUtils {

    public static String sUserId;

    /**
     * 当前用户是房主还是其他人
     */
    public static void setRoomUserId(String userId) {
        sUserId = userId;
    }

    public static boolean isOwner() {
        if (sUserId == null) {
            return false;
        }
        return (sUserId.equals(UserModelManager.getInstance().getUserModel().userId));
    }

    public static int dp2px(Context context, float dpVal) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP,
                dpVal, context.getResources().getDisplayMetrics());
    }
}

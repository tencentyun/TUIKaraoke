package com.tencent.liteav.demo;

import android.app.Activity;
import android.app.Application;
import android.os.Build;
import android.os.Bundle;
import android.os.StrictMode;
import androidx.multidex.MultiDexApplication;

import com.tencent.liteav.tuikaraoke.ui.floatwindow.IFloatWindowCallback;
import com.tencent.liteav.tuikaraoke.ui.room.KaraokeRoomAudienceActivity;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

public class DemoApplication extends MultiDexApplication {
    private static String TAG = "DemoApplication";

    private int                  startCount = 0;
    private IFloatWindowCallback mCallback;

    @Override
    public void onCreate() {
        super.onCreate();
        StrictMode.VmPolicy.Builder builder = new StrictMode.VmPolicy.Builder();
        StrictMode.setVmPolicy(builder.build());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            builder.detectFileUriExposure();
        }
        closeAndroidPDialog();
        this.registerActivityLifecycleCallbacks(new Application.ActivityLifecycleCallbacks() {

            @Override
            public void onActivityCreated(Activity activity, Bundle savedInstanceState) {

            }

            @Override
            public void onActivityStarted(Activity activity) {


            }

            @Override
            public void onActivityResumed(Activity activity) {
                startCount++;
                if (!(activity instanceof KaraokeRoomAudienceActivity)) {
                    if (mCallback != null)
                        mCallback.onAppBackground(false);
                }
            }

            @Override
            public void onActivityPaused(Activity activity) {
                startCount--;
                if (!(activity instanceof KaraokeRoomAudienceActivity)) {
                    if (startCount < 1) {
                        if (mCallback != null)
                            mCallback.onAppBackground(true);
                    }
                }

            }

            @Override
            public void onActivityStopped(Activity activity) {

            }

            @Override
            public void onActivitySaveInstanceState(Activity activity, Bundle outState) {

            }

            @Override
            public void onActivityDestroyed(Activity activity) {

            }
        });
    }

    public void setCallback(IFloatWindowCallback callback) {
        mCallback = callback;
        if (mCallback != null) {
            boolean is = mCallback instanceof IFloatWindowCallback;
        }
    }

    private void closeAndroidPDialog() {
        try {
            Class       aClass              = Class.forName("android.content.pm.PackageParser$Package");
            Constructor declaredConstructor = aClass.getDeclaredConstructor(String.class);
            declaredConstructor.setAccessible(true);
        } catch (Exception e) {
            e.printStackTrace();
        }
        try {
            Class  cls            = Class.forName("android.app.ActivityThread");
            Method declaredMethod = cls.getDeclaredMethod("currentActivityThread");
            declaredMethod.setAccessible(true);
            Object activityThread         = declaredMethod.invoke(null);
            Field  mHiddenApiWarningShown = cls.getDeclaredField("mHiddenApiWarningShown");
            mHiddenApiWarningShown.setAccessible(true);
            mHiddenApiWarningShown.setBoolean(activityThread, true);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
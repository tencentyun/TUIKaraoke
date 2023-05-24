package com.tencent.liteav.tuikaraoke.ui.room;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Color;
import android.graphics.Point;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.tencent.liteav.basic.ResourceUtils;
import com.tencent.liteav.tuikaraoke.R;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.trtc.TRTCCloudDef.TRTCVolumeInfo;
import com.tencent.trtc.TRTCStatistics;
import com.tencent.trtc.TRTCStatistics.TRTCLocalStatistics;
import com.tencent.trtc.TRTCStatistics.TRTCRemoteStatistics;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class KaraokeDashboardDialog extends Dialog {

    private static String                  TAG = "KaraokeDashboardDialog";
    private final  Context                 mContext;


    private LinearLayout                         mLayoutRemoteAudioInfoList;

    private NetworkInfoView                      mLocalNetworkInfoView;
    private LocalAudioInfoView                   mLocalAudioInfoView;
    private Map<String, RemoteAudioInfoView>     mRemoteAudioInfoViews;

    private final TRTCLocalStatistics            mDefaultLocalStatistics = new TRTCLocalStatistics();

    private String                               mSelfUserId;


    public KaraokeDashboardDialog(Context context) {
        super(context, R.style.TRTCKTVRoomDialogTheme);
        mContext = context;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initView();
        mRemoteAudioInfoViews = new HashMap<>();
    }

    private void initView() {
        mLocalNetworkInfoView = new NetworkInfoView(mContext);
        mLocalAudioInfoView = new LocalAudioInfoView(mContext);

        setContentView(R.layout.trtckaraoke_dialog_dashboard);
        setHeightAndBackground();

        // 本地网络信息 和 本地音频信息
        LinearLayout localLayout = findViewById(R.id.ll_dashboard_local_info);
        localLayout.addView(mLocalNetworkInfoView);
        localLayout.addView(mLocalAudioInfoView);

        // 远端音频信息列表
        mLayoutRemoteAudioInfoList = findViewById(R.id.ll_dashboard_remote_audio_info_list);
    }

    private void setHeightAndBackground() {
        int screenHeight = getScreenHeight(getContext());
        if (screenHeight == 0) {
            screenHeight = 1920;
        }
        Window window = getWindow();
        if (window == null) {
            TRTCLogger.d(TAG, " the window is null");
            return;
        }
        window.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, (int) (screenHeight / 4 * 3));
        window.setGravity(Gravity.BOTTOM);
        window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
    }

    public void setSelfUserId(String userId) {
        mSelfUserId = userId;
    }

    public static int getScreenHeight(Context context) {
        WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        Point point = new Point();
        if (wm == null) {
            TRTCLogger.d(TAG, " the wm is null");
            return 0;
        }
        wm.getDefaultDisplay().getSize(point);
        return point.y;
    }

    public void updateUserVolume(List<TRTCVolumeInfo> userVolumes) {
        if (userVolumes == null) {
            return;
        }
        for (TRTCVolumeInfo info : userVolumes) {
            updateUserVolume(info);
        }
    }

    private void updateUserVolume(TRTCVolumeInfo info) {
        if (info == null) {
            return;
        }
        if (TextUtils.equals(mSelfUserId, info.userId)) {
            updateLocalUserVolume(info);
        } else {
            updateRemoteUserVolume(info);
        }
    }

    private void updateLocalUserVolume(TRTCVolumeInfo info) {
        if (mLocalAudioInfoView == null || info == null) {
            return;
        }
        mLocalAudioInfoView.update(null, info.volume);
    }

    private void updateRemoteUserVolume(TRTCVolumeInfo info) {
        if (mRemoteAudioInfoViews == null || info == null) {
            return;
        }
        RemoteAudioInfoView remoteView = mRemoteAudioInfoViews.get(info.userId);
        if (remoteView != null) {
            remoteView.update(null, info.volume);
        }
    }

    public void update(TRTCStatistics statistics) {
        if (statistics == null) {
            return;
        }
        if (mLocalNetworkInfoView != null) {
            mLocalNetworkInfoView.update(statistics, null);
        }
        if (mLocalAudioInfoView != null) {
            if (statistics.localArray != null && !statistics.localArray.isEmpty()) {
                // 上麦
                mLocalAudioInfoView.update(statistics.localArray.get(0), null);
            } else {
                // 麦下，sdk不回调TRTCLocalStatistics，但界面上需要清零
                mLocalAudioInfoView.update(mDefaultLocalStatistics, null);
            }
        }
        if (statistics.remoteArray == null || mRemoteAudioInfoViews == null) {
            return;
        }
        // 上次上麦，但本次下麦的用户集合（将会被移除）
        Set<String> needRemoveUserIds = new HashSet<>(mRemoteAudioInfoViews.keySet().size());
        needRemoveUserIds.addAll(mRemoteAudioInfoViews.keySet());
        for (TRTCRemoteStatistics remoteStatistics : statistics.remoteArray) {
            if (remoteStatistics == null || TextUtils.isEmpty(remoteStatistics.userId)) {
                continue;
            }
            RemoteAudioInfoView remoteView = mRemoteAudioInfoViews.get(remoteStatistics.userId);
            if (remoteView == null) {
                // 新上麦用户
                remoteView = new RemoteAudioInfoView(mContext);
                mRemoteAudioInfoViews.put(remoteStatistics.userId, remoteView);
                mLayoutRemoteAudioInfoList.addView(remoteView);
            } else {
                // 这个用户本次上麦了，不在待移除列表
                needRemoveUserIds.remove(remoteStatistics.userId);
            }
            remoteView.update(remoteStatistics, null);
            remoteView.setVisibility(View.VISIBLE);
        }
        // 最终剩下这些下麦用户，统一移除
        for (String userId : needRemoveUserIds) {
            RemoteAudioInfoView view = mRemoteAudioInfoViews.remove(userId);
            mLayoutRemoteAudioInfoList.removeView(view);
        }
    }

    private static class ItemView extends LinearLayout {
        private final TextView mTitleView;
        private final TextView mValueView;

        public ItemView(Context context, int orientation) {
            super(context);
            setOrientation(orientation);
            int paddingV = ResourceUtils.dip2px(5);
            setPadding(0, paddingV, 0, paddingV);

            mValueView = new TextView(context);
            mTitleView = new TextView(context);
            mTitleView.setTextSize(12);
            mTitleView.setTextColor(getResources().getColor(R.color.trtckaraoke_color_dashboard_title));
            if (orientation == HORIZONTAL) {
                initHorizontalStyle();
            } else {
                initVerticalStyle();
            }
        }

        private void initVerticalStyle() {
            mValueView.setGravity(Gravity.CENTER);
            mValueView.setTextSize(24);
            addView(mValueView);

            mTitleView.setGravity(Gravity.CENTER);
            addView(mTitleView);
        }

        private void initHorizontalStyle() {
            LayoutParams params = new LayoutParams(0, LayoutParams.WRAP_CONTENT);
            params.weight = 1;
            addView(mTitleView, params);

            mValueView.setGravity(Gravity.RIGHT);
            mValueView.setTextSize(13);
            addView(mValueView, params);
        }

        public void setTitle(String title) {
            mTitleView.setText(title);
        }

        public void setValue(String value, int valueColor) {
            mValueView.setText(value);
            mValueView.setTextColor(valueColor);
        }
    }

    private abstract static class DashboardInfoView<T> extends LinearLayout {

        protected TextView mTitleView;
        private LinearLayout mContentView;
        private final Map<String, ItemView> itemMap = new HashMap();

        public DashboardInfoView(Context context) {
            super(context);
            setOrientation(LinearLayout.VERTICAL);
            mTitleView = new TextView(context);
            mTitleView.setTextSize(15);
            mTitleView.setTextColor(getResources().getColor(R.color.white));
            addView(mTitleView);

            mContentView = new LinearLayout(context);
            mContentView.setOrientation(VERTICAL);
            onCreateContentView(mContentView);
            addView(mContentView);

            int paddingV = ResourceUtils.dip2px(10);
            setPadding(0, paddingV, 0, paddingV);
        }

        public void onCreateContentView(LinearLayout contentView) {

        }

        public abstract void update(T statistics, Integer volume);

        protected void setItem(int orientation, String title, String value) {
            setItem(orientation, title, value, getResources().getColor(R.color.trtckaraoke_white));
        }

        protected void setItem(int orientation, String title, String value, int valueColor) {
            ItemView itemView = itemMap.get(title);
            if (itemView == null) {
                itemView = addItem(orientation, title);
            }
            itemView.setValue(value, valueColor);
        }

        private ItemView addItem(int orientation, String title) {
            Context context = getContext();
            ItemView itemLayout = new ItemView(context, orientation);
            itemLayout.setTitle(title);
            if (mContentView.getOrientation() == HORIZONTAL) {
                LayoutParams params = new LayoutParams(0, LayoutParams.WRAP_CONTENT);
                params.weight = 1;
                mContentView.addView(itemLayout, params);
            } else {
                mContentView.addView(itemLayout);
            }
            itemMap.put(title, itemLayout);
            return itemLayout;
        }
    }

    private static class NetworkInfoView extends DashboardInfoView<TRTCStatistics> {

        private final int mColorGreen;
        private final int mColorPink;

        public NetworkInfoView(Context context) {
            super(context);
            mTitleView.setText(getResources().getText(R.string.trtckaraoke_network_info));
            mColorGreen = getResources().getColor(R.color.trtckaraoke_color_dashboard_green);
            mColorPink  = getResources().getColor(R.color.trtckaraoke_color_dashboard_pink);
        }

        @Override
        public void onCreateContentView(LinearLayout contentView) {
            contentView.setOrientation(LinearLayout.HORIZONTAL);
        }

        @Override
        public void update(TRTCStatistics statistics, Integer volume) {
            if (statistics == null) {
                return;
            }
            int rttColor = statistics.rtt > 100 ? mColorPink : mColorGreen;
            int downLossColor = statistics.downLoss > 10 ? mColorPink : mColorGreen;
            int upLossColor = statistics.upLoss > 10 ? mColorPink : mColorGreen;
            setItem(VERTICAL, "RTT", statistics.rtt + "ms", rttColor);
            setItem(VERTICAL, "downLoss", statistics.downLoss + "%", downLossColor);
            setItem(VERTICAL,"upLoss", statistics.upLoss + "%", upLossColor);
        }
    }

    private static class LocalAudioInfoView extends DashboardInfoView<TRTCLocalStatistics> {

        public LocalAudioInfoView(Context context) {
            super(context);
            mTitleView.setText(getResources().getText(R.string.trtckaraoke_local_audio_info));
            update(new TRTCLocalStatistics(), 0);
        }

        @Override
        public void update(TRTCLocalStatistics statistics, Integer volume) {
            if (statistics != null) {
                setItem(HORIZONTAL, "audioBitrate", statistics.audioBitrate + "kbps");
                setItem(HORIZONTAL, "audioCaptureState", statistics.audioCaptureState + "");
                setItem(HORIZONTAL, "audioSampleRate", statistics.audioSampleRate + "Hz");
            }
            if (volume != null) {
                setItem(HORIZONTAL,"audioVolume", volume.intValue() + "%");
            }
        }
    }

    private static class RemoteAudioInfoView extends DashboardInfoView<TRTCRemoteStatistics> {

        public RemoteAudioInfoView(Context context) {
            super(context);
            mTitleView.setText(getResources().getText(R.string.trtckaraoke_remote_audio_info));
            update(new TRTCRemoteStatistics(), 0);
        }

        @Override
        public void update(TRTCRemoteStatistics statistics, Integer volume) {
            if (statistics != null) {
                setItem(HORIZONTAL, "userId", statistics.userId + "");
                setItem(HORIZONTAL, "audioSampleRate", statistics.audioSampleRate + "Hz");
                setItem(HORIZONTAL, "audioBitrate", statistics.audioBitrate + "kbps");
                setItem(HORIZONTAL, "jitterBufferDelay", statistics.jitterBufferDelay + "ms");
                setItem(HORIZONTAL, "audioBlockRate", statistics.audioBlockRate + "%");
            }
            if (volume != null) {
                setItem(HORIZONTAL,"audioVolume", volume.intValue() + "%");
            }
        }
    }
}

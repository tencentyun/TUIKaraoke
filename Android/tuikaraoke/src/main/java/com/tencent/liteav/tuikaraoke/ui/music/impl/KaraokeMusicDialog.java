package com.tencent.liteav.tuikaraoke.ui.music.impl;

import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_MUSIC_EVENT;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_SELECTED_MUSIC_COUNT_KEY;
import static com.tencent.liteav.tuikaraoke.ui.utils.Constants.KARAOKE_UPDATE_SELECTED_MUSIC_COUNT_EVENT;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Color;
import android.graphics.Point;
import android.graphics.drawable.ColorDrawable;

import com.google.android.material.tabs.TabLayout;

import androidx.viewpager.widget.PagerAdapter;

import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;

import com.tencent.liteav.tuikaraoke.R;

import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.ui.music.CustomViewPager;
import com.tencent.liteav.tuikaraoke.ui.room.RoomInfoController;
import com.tencent.qcloud.tuicore.TUICore;
import com.tencent.qcloud.tuicore.interfaces.ITUINotification;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

public class KaraokeMusicDialog extends Dialog {

    private static String                  TAG = "KaraokeMusicDialog";
    private final  Context                 mContext;
    private final  RoomInfoController      mRoomInfoController;
    private        TabLayout               mTopTl;
    private        CustomViewPager         mContentVp;
    private        KaraokeMusicLibraryView mKTVLibraryView;
    private        KaraokeMusicSelectView  mKTVSelectView;

    private ITUINotification mUpdateSelectedMusicCount = new ITUINotification() {
        @Override
        public void onNotifyEvent(String key, String subKey, Map<String, Object> param) {
            if (param == null || !param.containsKey(KARAOKE_SELECTED_MUSIC_COUNT_KEY)) {
                return;
            }
            int count = (int) param.get(KARAOKE_SELECTED_MUSIC_COUNT_KEY);
            updateSelectedTagText(count);
        }
    };

    public KaraokeMusicDialog(Context context, RoomInfoController roomInfoController) {
        super(context, R.style.TRTCKTVRoomDialogTheme);
        mContext = context;
        mRoomInfoController = roomInfoController;
        setContentView(R.layout.trtckaraoke_fragment_base_tab_choose);
        initView(mContext);
        initData(mContext);
        setHeightAndBackground();
    }

    @Override
    public void onAttachedToWindow() {
        super.onAttachedToWindow();
        updateSelectedTagText(mRoomInfoController.getUserSelectMap().size());
        TUICore.registerEvent(KARAOKE_MUSIC_EVENT, KARAOKE_UPDATE_SELECTED_MUSIC_COUNT_EVENT,
                mUpdateSelectedMusicCount);
    }

    @Override
    public void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        TUICore.unRegisterEvent(KARAOKE_MUSIC_EVENT, KARAOKE_UPDATE_SELECTED_MUSIC_COUNT_EVENT,
                mUpdateSelectedMusicCount);
    }

    private void initView(Context context) {
        mTopTl = (TabLayout) findViewById(R.id.tl_top);
        mContentVp = (CustomViewPager) findViewById(R.id.vp_content);
        mKTVLibraryView = new KaraokeMusicLibraryView(context, mRoomInfoController);
        mKTVSelectView = new KaraokeMusicSelectView(context, mRoomInfoController);
        mContentVp.setNoScroll(true);
    }

    private void initData(Context context) {
        ArrayList<View> viewList = new ArrayList<>();
        viewList.add(mKTVLibraryView);
        viewList.add(mKTVSelectView);

        mTopTl.setupWithViewPager(mContentVp, false);

        PagerAdapter pagerAdapter = new KaraokeMusicPagerAdapter(viewList);
        mContentVp.setAdapter(pagerAdapter);
        String[] titleArray = new String[]{
                context.getString(R.string.trtckaraoke_btn_choose_song),
                context.getString(R.string.trtckaraoke_btn_choosed_song),
        };
        List<String> titleList = Arrays.asList(titleArray);
        for (int i = 0; i < titleList.size(); i++) {
            TabLayout.Tab tab = mTopTl.getTabAt(i);
            if (tab != null) {
                tab.setText(titleList.get(i));
            }
        }
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

    public void setCurrentItem(int index) {
        mContentVp.setCurrentItem(index);
    }

    private void updateSelectedTagText(int selectedMusicCount) {
        String text = mContext.getString(R.string.trtckaraoke_btn_choosed_song) + "(" + selectedMusicCount + ")";
        TabLayout.Tab tab = mTopTl.getTabAt(1);
        tab.setText(text);
    }

    public void updateMusicListChanged(List<KaraokeMusicInfo> musicInfoList) {
        mKTVSelectView.updateMusicListChanged(musicInfoList);
    }
}

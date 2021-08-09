package com.tencent.liteav.tuikaraoke.ui.music.impl;

import android.app.Dialog;
import android.content.Context;
import android.graphics.Color;
import android.graphics.Point;
import android.graphics.drawable.ColorDrawable;
import android.os.Bundle;
import android.support.design.widget.TabLayout;
import android.support.v4.view.PagerAdapter;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;

import com.tencent.liteav.tuikaraoke.R;

import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.ui.music.CustomViewPager;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicService;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class KaraokeMusicDialog extends Dialog {

    private static String                  TAG = "KaraokeMusicDialog";
    private final  Context                 mContext;
    private        TabLayout               mTopTl;
    private        CustomViewPager         mContentVp;
    private final  KaraokeMusicService     mMusicService;
    private        KaraokeMusicLibraryView mKTVLibraryView;
    private        KaraokeMusicSelectView  mKTVSelectView;

    public KaraokeMusicDialog(Context context, KaraokeMusicService musicService) {
        super(context, R.style.TRTCKTVRoomDialogTheme);
        mContext = context;
        mMusicService = musicService;
        setContentView(R.layout.trtckaraoke_fragment_base_tab_choose);
        initView(mContext);
        initData(mContext);
        setHeightAndBackground();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    private void initView(Context context) {
        mTopTl = (TabLayout) findViewById(R.id.tl_top);
        mContentVp = (CustomViewPager) findViewById(R.id.vp_content);
        mKTVLibraryView = new KaraokeMusicLibraryView(context, mMusicService);
        mKTVSelectView = new KaraokeMusicSelectView(context, mMusicService);
        mContentVp.setNoScroll(true);
    }

    private void initData(Context context) {
        String[] TITLE_LIST = new String[]{
                context.getString(R.string.trtckaraoke_btn_choose_song),
                context.getString(R.string.trtckaraoke_btn_choosed_song),
        };
        List<String> titleList = Arrays.asList(TITLE_LIST);

        ArrayList<View> viewList = new ArrayList<>();
        viewList.add(mKTVLibraryView);
        viewList.add(mKTVSelectView);

        mTopTl.setupWithViewPager(mContentVp, false);

        PagerAdapter pagerAdapter = new KaraokeMusicPagerAdapter(viewList);
        mContentVp.setAdapter(pagerAdapter);
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
        window.setLayout(ViewGroup.LayoutParams.MATCH_PARENT, (int) (screenHeight / 3 * 2));
        window.setGravity(Gravity.BOTTOM);
        window.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
    }

    public static int getScreenHeight(Context context) {
        WindowManager wm    = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        Point         point = new Point();
        if (wm == null) {
            TRTCLogger.d(TAG, " the wm is null");
            return 0;
        }
        wm.getDefaultDisplay().getSize(point);
        return point.y;
    }
}

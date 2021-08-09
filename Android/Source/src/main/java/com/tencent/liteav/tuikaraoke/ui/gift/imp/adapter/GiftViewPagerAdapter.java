package com.tencent.liteav.tuikaraoke.ui.gift.imp.adapter;

import android.support.v4.view.PagerAdapter;
import android.view.View;
import android.view.ViewGroup;

import java.util.List;

public class GiftViewPagerAdapter extends PagerAdapter {

    private List<View> mViews;

    public GiftViewPagerAdapter(List<View> views) {
        this.mViews = views;
    }

    @Override
    public int getCount() {
        return mViews != null ? mViews.size() : 0;
    }


    @Override
    public boolean isViewFromObject(View view, Object object) {
        return view == object;
    }

    @Override
    public Object instantiateItem(ViewGroup container, int position) {
        container.addView(mViews.get(position), 0);
        return mViews.get(position);
    }

    @Override
    public void destroyItem(ViewGroup container, int position, Object object) {
        container.removeView(mViews.get(position));
    }
}
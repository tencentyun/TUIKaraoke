package com.tencent.liteav.tuikaraoke.ui.audio;

public class Entity {

    public String  mTitle;
    public int     mIconId;
    public int     mSelectIconId;
    public int     mType;
    public boolean mIsSelected = false;

    public Entity(String title, int iconId, int selectIconId, int type) {
        mTitle = title;
        mIconId = iconId;
        mSelectIconId = selectIconId;
        mType = type;
    }
}

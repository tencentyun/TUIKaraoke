package com.tencent.liteav.tuikaraoke.ui.room;

import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicService;
import com.tencent.qcloud.tuicore.TUILogin;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class RoomInfoController {

    private String                         mRoomOwnerId; //房主的Id
    private String                         mSelfUserId;  //用户的Id
    private List<KaraokeRoomSeatEntity>    mKaraokeRoomSeatEntityList;
    private KaraokeMusicService           mKaraokeMusicServiceImpl;
    private KaraokeMusicInfo              mTopModel;
    private Map<String, KaraokeMusicInfo> mUserSelectMap = new HashMap<>(); // key:musicId value:model

    public String getSelfUserId() {
        return mSelfUserId;
    }

    public RoomInfoController() {
        mSelfUserId = TUILogin.getLoginUser();
    }

    public String getRoomOwnerId() {
        return mRoomOwnerId;
    }

    public void setRoomOwnerId(String roomOwnerId) {
        mRoomOwnerId = roomOwnerId;
    }

    public void setRoomSeatEntityList(List<KaraokeRoomSeatEntity> karaokeRoomSeatEntityList) {
        mKaraokeRoomSeatEntityList = karaokeRoomSeatEntityList;
    }

    public List<KaraokeRoomSeatEntity> getRoomSeatEntityList() {
        return mKaraokeRoomSeatEntityList;
    }

    //是否是主播
    public boolean isAnchor() {
        if (isRoomOwner()) {
            // mKaraokeRoomSeatEntityList 需要等到座位表回调才有值
            return true;
        }
        if (mSelfUserId == null || mKaraokeRoomSeatEntityList == null || mKaraokeRoomSeatEntityList.size() <= 0) {
            return false;
        }
        for (KaraokeRoomSeatEntity entity : mKaraokeRoomSeatEntityList) {
            if (entity != null && mSelfUserId.equals(entity.userId)) {
                return true;
            }
        }
        return false;
    }

    //是否是房主
    public boolean isRoomOwner() {
        if (mSelfUserId != null && mRoomOwnerId != null) {
            return mSelfUserId.equals(mRoomOwnerId);
        }
        return false;
    }

    public void setMusicImpl(KaraokeMusicService karaokeMusicService) {
        mKaraokeMusicServiceImpl = karaokeMusicService;
    }

    public KaraokeMusicService getMusicServiceImpl() {
        return mKaraokeMusicServiceImpl;
    }

    public KaraokeRoomSeatEntity getCurrentSeatEntity(String userId) {
        if (userId == null || mKaraokeRoomSeatEntityList == null || mKaraokeRoomSeatEntityList.size() <= 0) {
            return null;
        }
        for (KaraokeRoomSeatEntity entity : mKaraokeRoomSeatEntityList) {
            if (entity != null && userId.equals(entity.userId)) {
                return entity;
            }
        }
        return null;
    }

    public void setTopModel(KaraokeMusicInfo model) {
        this.mTopModel = model;
    }

    public KaraokeMusicInfo getTopModel() {
        return mTopModel;
    }

    public Map<String, KaraokeMusicInfo> getUserSelectMap() {
        return mUserSelectMap;
    }

}

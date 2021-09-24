package com.tencent.liteav.tuikaraoke.ui.room;

import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeRoomSeatEntity;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicService;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class RoomInfoController {

    private String                         mRoomOwnerId; //房主的Id
    private String                         mSelfUserId;  //用户的Id
    private List<KaraokeRoomSeatEntity>    mKaraokeRoomSeatEntityList;
    private KaraokeMusicService            mKaraokeMusicServiceImpl;
    private KaraokeMusicModel              mTopModel;
    private Map<String, KaraokeMusicModel> mUserSelectMap;

    public String getSelfUserId() {
        return mSelfUserId;
    }

    public RoomInfoController() {
        mSelfUserId = UserModelManager.getInstance().getUserModel().userId;
    }

    public String getRoomOwnerId() {
        return mRoomOwnerId;
    }

    public void setRoomOwnerId(String roomOwnerId) {
        mRoomOwnerId = roomOwnerId;
    }

    public void setRoomSeatEntityList(List<KaraokeRoomSeatEntity> KaraokeRoomSeatEntityList) {
        mKaraokeRoomSeatEntityList = KaraokeRoomSeatEntityList;
    }

    public List<KaraokeRoomSeatEntity> getRoomSeatEntityList() {
        return mKaraokeRoomSeatEntityList;
    }

    //是否是主播
    public boolean isAnchor() {
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

    public void setMusicImpl(KaraokeMusicService KaraokeMusicService) {
        mKaraokeMusicServiceImpl = KaraokeMusicService;
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

    public void setTopModel(KaraokeMusicModel model) {
        this.mTopModel = model;
    }

    public KaraokeMusicModel getTopModel() {
        return mTopModel;
    }
    //key:musicId value:model
    public void setUserSelectMap(Map<String, KaraokeMusicModel> map) {
        this.mUserSelectMap = map;
    }

    public Map<String, KaraokeMusicModel> getUserSelectMap() {
        if(mUserSelectMap == null){
            mUserSelectMap = new HashMap<>();
        }
        return mUserSelectMap;
    }

}

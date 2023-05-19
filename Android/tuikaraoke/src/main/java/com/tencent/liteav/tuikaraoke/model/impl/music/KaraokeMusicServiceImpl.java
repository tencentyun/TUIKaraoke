package com.tencent.liteav.tuikaraoke.model.impl.music;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;

import androidx.core.content.ContextCompat;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.tencent.imsdk.v2.V2TIMGroupMemberInfo;
import com.tencent.imsdk.v2.V2TIMManager;
import com.tencent.imsdk.v2.V2TIMMessage;
import com.tencent.imsdk.v2.V2TIMSimpleMsgListener;
import com.tencent.imsdk.v2.V2TIMValueCallback;
import com.tencent.liteav.basic.UserModel;
import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.debug.GenerateTestUserSig;
import com.tencent.liteav.tuikaraoke.model.KaraokeAddMusicCallback;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicPageInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicTag;
import com.tencent.liteav.tuikaraoke.model.impl.server.TRTCKaraokeRoomManager;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.model.KaraokeMusicServiceObserver;
import com.tencent.qcloud.tuicore.interfaces.TUICallback;
import com.tencent.qcloud.tuicore.interfaces.TUIValueCallback;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * 歌曲管理实现类
 */
public class KaraokeMusicServiceImpl extends KaraokeMusicService implements TRTCKaraokeRoomManager.RoomCallback {

    private static String TAG = "KaraokeMusicServiceImpl";

    private List<KaraokeMusicServiceObserver> mSelectDelegates;
    private KTVMusicListener                  mSimpleListener;

    private List<KaraokeMusicInfo> mMusicLibraryList;   //点歌列表
    private List<KaraokeMusicInfo> mMusicSelectedList;  //已点列表

    private final TRTCKaraokeRoomDef.RoomInfo mRoomInfo = new TRTCKaraokeRoomDef.RoomInfo();

    private Context                mContext;


    private       String           mDefaultUrl  =
            "https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar2.png";

    private String mUserId;             //当前用户id

    private String mPath;


    public KaraokeMusicServiceImpl(Context context, TRTCKaraokeRoomDef.RoomInfo roomInfo) {
        mContext = context;
        mRoomInfo.roomId = roomInfo.roomId;
        mRoomInfo.ownerId = roomInfo.ownerId;
        mMusicLibraryList = new ArrayList<>();
        mMusicSelectedList = new ArrayList<>();
        mSimpleListener = new KTVMusicListener();
        // 初始化IM
        initIMListener();
        UserModel userModel = UserModelManager.getInstance().getUserModel();
        mUserId = userModel.userId;
        TRTCKaraokeRoomManager.getInstance().addCallback(this);
        mPath = ContextCompat.getExternalFilesDirs(mContext, null)[0].getAbsolutePath() + "/";
        for (int i = 0; i < 5; i++) {
            mMusicLibraryList.add(getSongEntity(i));
        }
        TRTCLogger.i(TAG, "KaraokeMusicServiceImpl from tuikaraoke constructor");
    }

    private KaraokeMusicInfo getSongEntity(int id) {
        KaraokeMusicInfo songEntity = new KaraokeMusicInfo();
        if (id == 0) {
            songEntity.musicId = "1001";
            songEntity.musicName = "后来";
            songEntity.singers = Arrays.asList("刘若英");
            songEntity.coverUrl = mDefaultUrl;
            songEntity.lrcUrl = mPath + "houlai_lrc.vtt";;
            songEntity.performId = "1001";
            songEntity.originUrl = mPath + "houlai_yc.mp3";
            songEntity.accompanyUrl = mPath + "houlai_bz.mp3";
            return songEntity;
        } else if (id == 1) {
            songEntity.musicId = "1002";
            songEntity.musicName = "情非得已";
            songEntity.singers = Arrays.asList("庾澄庆");
            songEntity.coverUrl = mDefaultUrl;
            songEntity.lrcUrl = mPath + "qfdy_lrc.vtt";
            songEntity.performId = "1002";
            songEntity.originUrl = mPath + "qfdy_yc.mp3";
            songEntity.accompanyUrl = mPath + "qfdy_bz.mp3";
            return songEntity;
        } else if (id == 2) {
            songEntity.musicId = "1003";
            songEntity.musicName = "星晴";
            songEntity.singers = Arrays.asList("周杰伦");
            songEntity.coverUrl = mDefaultUrl;
            songEntity.lrcUrl = mPath + "xq_lrc.vtt";
            songEntity.performId = "1003";
            songEntity.originUrl = mPath + "xq_yc.mp3";
            songEntity.accompanyUrl = mPath + "xq_bz.mp3";
            return songEntity;
        } else if (id == 3) {
            songEntity.musicId = "1004";
            songEntity.musicName = "暖暖";
            songEntity.singers = Arrays.asList("梁静茹");
            songEntity.coverUrl = mDefaultUrl;
            songEntity.lrcUrl = mPath + "nuannuan_lrc.vtt";
            songEntity.performId = "1004";
            songEntity.originUrl = mPath + "nuannuan_yc.mp3";
            songEntity.accompanyUrl = mPath + "nuannuan_bz.mp3";
            return songEntity;
        } else if (id == 4) {
            songEntity.musicId = "1005";
            songEntity.musicName = "简单爱";
            songEntity.singers = Arrays.asList("周杰伦");
            songEntity.coverUrl = mDefaultUrl;
            songEntity.lrcUrl = mPath + "jda_lrc.vtt";
            songEntity.performId = "1005";
            songEntity.originUrl = mPath + "jda_yc.mp3";
            songEntity.accompanyUrl = mPath + "jda_bz.mp3";
            return songEntity;
        }
        return null;
    }

    @Override
    public void addObserver(KaraokeMusicServiceObserver delegate) {
        if (mSelectDelegates == null) {
            mSelectDelegates = new ArrayList<>();
        }
        if (!mSelectDelegates.contains(delegate)) {
            mSelectDelegates.add(delegate);
        }
    }

    public boolean isOwner() {
        return TextUtils.equals(mRoomInfo.ownerId, mUserId);
    }

    private String buildGroupMsg(String cmd) {
        KaraokeJsonData jsonData = new KaraokeJsonData();
        try {
            jsonData.setVersion(KaraokeConstants.KARAOKE_VALUE_CMD_VERSION);
            jsonData.setBusinessID(KaraokeConstants.KARAOKE_VALUE_CMD_BUSINESSID);
            jsonData.setPlatform(KaraokeConstants.KARAOKE_VALUE_CMD_PLATFORM);

            KaraokeJsonData.Data data = new KaraokeJsonData.Data();
            data.setRoomId(mRoomInfo.roomId);
            data.setInstruction(cmd);
            jsonData.setData(data);

            Gson gsonContent = new Gson();
            String content = gsonContent.toJson(mMusicSelectedList);

            data.setContent(content);

        } catch (Exception e) {
            e.printStackTrace();
        }
        Gson gson = new Gson();
        return gson.toJson(jsonData);
    }

    private String buildSingleMsg(String cmd, String content) {
        KaraokeJsonData jsonData = new KaraokeJsonData();
        try {
            jsonData.setVersion(KaraokeConstants.KARAOKE_VALUE_CMD_VERSION);
            jsonData.setBusinessID(KaraokeConstants.KARAOKE_VALUE_CMD_BUSINESSID);
            jsonData.setPlatform(KaraokeConstants.KARAOKE_VALUE_CMD_PLATFORM);

            KaraokeJsonData.Data data = new KaraokeJsonData.Data();
            data.setRoomId(mRoomInfo.roomId);
            data.setInstruction(cmd);
            data.setContent(content);

            jsonData.setData(data);

        } catch (Exception e) {
            e.printStackTrace();
        }
        Gson gson = new Gson();
        return gson.toJson(jsonData);
    }

    @Override
    public void getMusicTagList(TUIValueCallback<List<KaraokeMusicTag>> callback) {
        List<KaraokeMusicTag> musicTagList = new ArrayList();
        musicTagList.add(new KaraokeMusicTag("-10005", "本地歌曲"));
        TUIValueCallback.onSuccess(callback, musicTagList);
    }

    @Override
    public void getMusicsByTagId(String tagId, String scrollToken, TUIValueCallback<KaraokeMusicPageInfo> callback) {
        KaraokeMusicPageInfo pageInfo = new KaraokeMusicPageInfo();
        pageInfo.scrollToken = scrollToken;
        for (int i = 0; i < 5; i++) {
            KaraokeMusicInfo model = getSongEntity(i);
            pageInfo.musicInfoList.add(model);
        }
        TUIValueCallback.onSuccess(callback, pageInfo);
    }

    @Override
    public void getMusicsByKeywords(String scrollToken, int pageSize, String keyWords,
                                    final TUIValueCallback<KaraokeMusicPageInfo> callback) {
        if (keyWords == null) {
            return;
        }
        List<KaraokeMusicInfo> list = new ArrayList<>();
        for (KaraokeMusicInfo info : mMusicLibraryList) {
            if (info == null) {
                return;
            }
            if (info.musicName.contains(keyWords) || info.singers.contains(keyWords)) {
                list.add(info);
            }
        }
        KaraokeMusicPageInfo pageInfo = new KaraokeMusicPageInfo();
        pageInfo.scrollToken = scrollToken;
        pageInfo.musicInfoList = list;
        TUIValueCallback.onSuccess(callback, pageInfo);
    }

    @Override
    public void getPlaylist(final TUIValueCallback<List<KaraokeMusicInfo>> callback) {
        synchronized (this) {
            if (isOwner()) {
                TUIValueCallback.onSuccess(callback, mMusicSelectedList);
            }
        }
    }

    @Override
    public void addMusicToPlaylist(final KaraokeMusicInfo musicInfo, final KaraokeAddMusicCallback callback) {
        musicInfo.isSelected = true;
        musicInfo.performId = musicInfo.musicId;

        //房主点歌,自己更新列表,且如果是点的第一首歌,则播放
        if (isOwner()) {
            musicInfo.userId = mRoomInfo.ownerId;
            mMusicSelectedList.add(musicInfo);
            callback.onStart(musicInfo);
            callback.onProgress(musicInfo, 100);
            callback.onFinish(musicInfo, 0, "");
            notiListChange();
        } else {
            //其他主播点歌,发通知给房主
            sendInstruction(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MPICK, mRoomInfo.ownerId, musicInfo.musicId);
        }
    }

    @Override
    public void deleteMusicFromPlaylist(KaraokeMusicInfo musicInfo, final TUICallback callback) {
        if (isOwner()) {
            synchronized (this) {
                musicInfo.isSelected = true;
                if (mMusicSelectedList != null && mMusicSelectedList.size() > 0) {
                    mMusicSelectedList.remove(musicInfo);
                }
                notiListChange();
            }
        }
    }

    @Override
    public void clearPlaylistByUserId(String userID, final TUICallback callback) {
        if (mMusicSelectedList.size() <= 0 || userID == null) {
            return;
        }
        //房主下麦
        if (isOwner()) {
            synchronized (this) {
                if (mMusicSelectedList.size() > 0) {
                    List<KaraokeMusicInfo> list = new ArrayList<>();
                    for (KaraokeMusicInfo temp : mMusicSelectedList) {
                        if (temp != null && userID.equals(temp.userId)) {
                            list.add(temp);
                        }
                    }
                    mMusicSelectedList.removeAll(list);
                    notiListChange();
                }
            }
        }
    }

    @Override
    public void topMusic(KaraokeMusicInfo musicInfo, final TUICallback callback) {
        if (mMusicSelectedList.size() <= 2 || !isOwner() || musicInfo.musicId == null) {
            return;
        }

        KaraokeMusicInfo entity = null;
        for (KaraokeMusicInfo temp : mMusicSelectedList) {
            if (temp != null && musicInfo.musicId.equals(temp.musicId)) {
                entity = temp;
                break;
            }
        }
        mMusicSelectedList.remove(entity);
        mMusicSelectedList.add(1, entity);

        notiListChange();
    }


    @Override
    public void switchMusicFromPlaylist(final KaraokeMusicInfo musicInfo, final TUICallback callback) {
        if (mMusicSelectedList.size() <= 0 || !isOwner()) {
            return;
        }
        KaraokeMusicInfo entity = mMusicSelectedList.get(0); //备份

        //如果房主切的是自己的歌
        if (entity.userId.equals(mRoomInfo.ownerId) && TextUtils.equals(musicInfo.performId, entity.performId)) {
            mMusicSelectedList.remove(entity);
            notifyOnMusicListChange(mMusicSelectedList);
        }
    }

    @Override
    public void completePlaying(KaraokeMusicInfo musicInfo) {
        if (isOwner()) {
            if (mMusicSelectedList.size() <= 0) {
                return;
            }

            synchronized (this) {
                if (musicInfo.performId.equals(mMusicSelectedList.get(0).performId)) {
                    mMusicSelectedList.remove(0); //移除第一首歌
                    notiListChange();
                }
            }
        }
    }

    @Override
    public void destroyService() {
        unInitImListener();
    }

    public KaraokeMusicInfo findEntityFromLibrary(String musicId) {
        if (musicId == null || mMusicLibraryList == null) {
            return null;
        }
        for (KaraokeMusicInfo entity : mMusicLibraryList) {
            if (entity.musicId.equals(musicId)) {
                return entity;
            }
        }
        return null;
    }

    // 广播通知列表发生变化
    private void notiListChange() {
        notifyOnMusicListChange(mMusicSelectedList);
        String data = buildGroupMsg(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MLISTCHANGE);
        Log.d(TAG, "sendNoti: cmd= " + KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MLISTCHANGE);
        sendNoti(data);
    }

    private void initIMListener() {
        V2TIMManager.getMessageManager();
        V2TIMManager.getInstance().addSimpleMsgListener(mSimpleListener);
    }

    private void unInitImListener() {
        V2TIMManager.getInstance().removeSimpleMsgListener(mSimpleListener);
    }

    public void sendNoti(String data) {
        V2TIMManager.getInstance().sendGroupCustomMessage(data.getBytes(),
                mRoomInfo.roomId, V2TIMMessage.V2TIM_PRIORITY_NORMAL, new V2TIMValueCallback<V2TIMMessage>() {
                    @Override
                    public void onSuccess(V2TIMMessage v2TIMMessage) {
                    }

                    @Override
                    public void onError(int code, String desc) {
                        TRTCLogger.d(TAG, "sendNoti onError:" + desc);
                    }
                });
    }

    public void sendInstruction(String cmd, String userId, String content) {
        Log.d(TAG, "sendInstruction: cmd = " + cmd + " , content = " + content);
        String data = buildSingleMsg(cmd, content);
        V2TIMManager.getInstance().sendC2CCustomMessage(data.getBytes(),
                userId, new V2TIMValueCallback<V2TIMMessage>() {
                    @Override
                    public void onSuccess(V2TIMMessage v2TIMMessage) {
                    }

                    @Override
                    public void onError(int code, String desc) {
                        TRTCLogger.d(TAG, "sendInstruction onError: code = " + code);
                    }
                });
    }

    @Override
    public void onRoomCreate(int roomId, TRTCKaraokeRoomManager.ActionCallback callback) {

    }

    @Override
    public void onRoomDestroy(int roomId, TRTCKaraokeRoomManager.ActionCallback callback) {

    }

    @Override
    public void onGenUserSig(String userId, TRTCKaraokeRoomManager.GenUserSigCallback callback) {
        String userSig = GenerateTestUserSig.genTestUserSig(userId);
        callback.onSuccess(userSig);
    }

    private class KTVMusicListener extends V2TIMSimpleMsgListener {
        public KTVMusicListener() {
            super();
        }

        @Override
        public void onRecvGroupCustomMessage(String msgID, String groupID,
                                             V2TIMGroupMemberInfo sender, byte[] customData) {
            String customStr = new String(customData);
            if (TextUtils.isEmpty(customStr)) {
                Log.d(TAG, "onRecvC2CCustomMessage  the customData is null");
                return;
            }
            Gson gson = new Gson();
            KaraokeJsonData jsonData;
            try {
                jsonData = gson.fromJson(customStr, KaraokeJsonData.class);
            } catch (Exception e) {
                return;
            }
            String businessID = jsonData.getBusinessID();
            if (!KaraokeConstants.KARAOKE_VALUE_CMD_BUSINESSID.equals(businessID)) {
                return;
            }
            KaraokeJsonData.Data data = jsonData.getData();
            String instruction = data.getInstruction();
            if (KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MLISTCHANGE.equals(instruction)) {
                receiveListChange(data);
            }
        }
    }

    private void receiveListChange(KaraokeJsonData.Data data) {
        List<KaraokeMusicInfo> list = new ArrayList<>();
        Gson gsonTemp = new Gson();
        list = gsonTemp.fromJson(data.getContent(),
                new TypeToken<List<KaraokeMusicInfo>>() {
                }.getType());

        mMusicSelectedList.clear();
        //避免ios端和Android数据不一致导致的数据异常
        //根据musicId对齐两端的信息
        if (list != null && list.size() > 0) {
            for (KaraokeMusicInfo temp : list) {
                if (temp != null) {
                    KaraokeMusicInfo tempEntity = findEntityFromLibrary(temp.musicId);
                    if (tempEntity != null) {
                        tempEntity.userId = temp.userId;
                        tempEntity.isSelected = temp.isSelected;
                        mMusicSelectedList.add(tempEntity);
                    }
                }
            }
        }
        //收到列表变化的通知,去更新自己的界面信息
        notifyOnMusicListChange(mMusicSelectedList);
    }

    private void notifyOnMusicListChange(List<KaraokeMusicInfo> list) {
        if (mSelectDelegates == null || mSelectDelegates.isEmpty()) {
            return;
        }
        if (mSelectDelegates != null) {
            for (KaraokeMusicServiceObserver delegate : mSelectDelegates) {
                delegate.onMusicListChanged(list);
            }
        }
    }

}

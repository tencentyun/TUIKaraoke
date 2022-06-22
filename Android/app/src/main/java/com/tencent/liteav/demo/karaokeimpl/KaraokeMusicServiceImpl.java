package com.tencent.liteav.demo.karaokeimpl;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.tencent.imsdk.v2.V2TIMGroupMemberInfo;
import com.tencent.imsdk.v2.V2TIMManager;
import com.tencent.imsdk.v2.V2TIMMessage;
import com.tencent.imsdk.v2.V2TIMSimpleMsgListener;
import com.tencent.imsdk.v2.V2TIMUserInfo;
import com.tencent.imsdk.v2.V2TIMValueCallback;
import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.model.impl.base.TRTCLogger;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokePopularInfo;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicCallback;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicService;
import com.tencent.liteav.tuikaraoke.ui.music.KaraokeMusicServiceDelegate;

import java.util.ArrayList;
import java.util.List;

/**
 * 歌曲管理实现类
 */
public class KaraokeMusicServiceImpl extends KaraokeMusicService {

    private static String TAG = "KaraokeMusicServiceImpl";

    private List<KaraokeMusicServiceDelegate> mSelectDelegates;
    private KTVMusicListener                  mSimpleListener;

    private List<KaraokeMusicInfo>  mMusicLibraryList;   //点歌列表
    private List<KaraokeMusicModel> mMusicSelectedList;  //已点列表
    private String                  mRoomId;
    private String                  mOwnerId;            //房主的id
    private String                  mCurrentMusicId;
    private Context                 mContext;

    private static final int    CODE_SUCCEED      = 0;  //succeed
    private static final int    CODE_FAILED       = -1; //failed
    //本地分类歌曲数据
    private static final String LOCAL_DESCRIPTION = "sweet song";
    private static final String LOCAL_MUSICNUM    = "0";
    private static final String LOCAL_PLAYLISTID  = "music123";
    private static final String LOCAL_TOPIC       = "romance";

    public KaraokeMusicServiceImpl() {
        mMusicLibraryList = new ArrayList<>();
        mMusicSelectedList = new ArrayList<>();
        mSimpleListener = new KTVMusicListener();
        // 初始化IM
        initIMListener();
    }

    public KaraokeMusicServiceImpl(Context context) {
        mContext = context;
        mMusicLibraryList = new ArrayList<>();
        mMusicSelectedList = new ArrayList<>();
        mSimpleListener = new KTVMusicListener();
        // 初始化IM
        initIMListener();
    }

    @Override
    public void setServiceDelegate(KaraokeMusicServiceDelegate delegate) {
        if (mSelectDelegates == null) {
            mSelectDelegates = new ArrayList<>();
        }
        if (!mSelectDelegates.contains(delegate)) {
            mSelectDelegates.add(delegate);
        }
    }

    public boolean isOwner() {
        if (mOwnerId == null) {
            return false;
        }
        return mOwnerId.equals(UserModelManager.getInstance().getUserModel().userId);
    }

    private String buildGroupMsg(String cmd, List<KaraokeMusicModel> list) {
        KaraokeJsonData jsonData = new KaraokeJsonData();
        try {
            jsonData.setVersion(KaraokeConstants.KARAOKE_VALUE_CMD_VERSION);
            jsonData.setBusinessID(KaraokeConstants.KARAOKE_VALUE_CMD_BUSINESSID);
            jsonData.setPlatform(KaraokeConstants.KARAOKE_VALUE_CMD_PLATFORM);

            KaraokeJsonData.Data data = new KaraokeJsonData.Data();
            data.setRoomId(mRoomId);
            data.setInstruction(cmd);

            Gson gsonContent = new Gson();
            String content = gsonContent.toJson(mMusicSelectedList);

            data.setContent(content);
            jsonData.setData(data);

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
            data.setRoomId(mRoomId);
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
    public void ktvGetPopularMusic(KaraokeMusicCallback.PopularMusicListCallback callback) {
        List<KaraokePopularInfo> list = new ArrayList<>();
        KaraokePopularInfo info = new KaraokePopularInfo();
        info.description = LOCAL_DESCRIPTION;
        info.musicNum = LOCAL_MUSICNUM;
        info.playlistId = LOCAL_PLAYLISTID;
        info.topic = LOCAL_TOPIC;
        list.add(info);
        callback.onCallBack(list);
    }

    @Override
    public void ktvGetMusicPage(String playlistId, int offset, int pageSize, KaraokeMusicCallback.MusicListCallback callback) {
        if (!LOCAL_PLAYLISTID.equals(playlistId)) {
            return;
        }
        MusicInfoController musicInfoController = new MusicInfoController(mContext);
        List<KaraokeMusicInfo> list = musicInfoController.getLibraryList();
        callback.onCallback(0, "success", list);

        if (mMusicLibraryList.size() <= 0) {
            for (KaraokeMusicInfo info : list) {
                KaraokeMusicModel model = new KaraokeMusicModel();
                model.musicId = info.musicId;
                model.musicName = info.musicName;
                model.singers = info.singers;
                model.originUrl = info.originUrl;
                model.accompanyUrl = info.accompanyUrl;
                model.coverUrl = info.coverUrl;
                model.lrcUrl = info.lrcUrl;
                model.userId = info.userId;
                model.performId = info.performId;
                model.isSelected = false;
                mMusicLibraryList.add(model);
            }
        }
    }

    @Override
    public void ktvSearchMusicByKeyWords(int offset, int pageSize, String keyWords, KaraokeMusicCallback.MusicListCallback callback) {
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
        callback.onCallback(CODE_SUCCEED, "succeed", list);
    }

    @Override
    public void ktvGetSelectedMusicList(KaraokeMusicCallback.MusicSelectedListCallback callback) {
        synchronized (this) {
            if (isOwner()) {
                if (mMusicSelectedList.size() > 0) {
                    if (mSelectDelegates != null) {
                        for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                            delegate.onShouldSetLyric(mMusicSelectedList.get(0));
                        }
                    }
                }
                callback.onCallback(0, "success", mMusicSelectedList);
            } else {
                sendRequestSelectedList();
            }
        }
    }

    @Override
    public void pickMusic(KaraokeMusicInfo musicInfo, KaraokeMusicCallback.ActionCallback callback) {
        boolean shouldPlay = mMusicSelectedList.size() == 0;
        KaraokeMusicModel songEntity = changeMusicInfoToModel(musicInfo);
        songEntity.isSelected = true;
        songEntity.performId = songEntity.musicId;

        //房主点歌,自己更新列表,且如果是点的第一首歌,则播放
        if (isOwner()) {
            songEntity.userId = mOwnerId;
            mMusicSelectedList.add(songEntity);
            callback.onCallback(0, "succeed");
            notiListChange();
            if (shouldPlay) {
                if (mSelectDelegates != null) {
                    for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                        delegate.onShouldPlay(songEntity);
                    }
                }
            }
            if (mSelectDelegates != null) {
                for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                    delegate.onShouldShowMessage(songEntity);
                }
            }
        } else {
            //其他主播点歌,发通知给房主
            sendInstruction(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MPICK, mOwnerId, songEntity.musicId);
        }
    }

    @Override
    public void deleteMusic(KaraokeMusicInfo musicInfo, KaraokeMusicCallback.ActionCallback callback) {
        if (isOwner()) {
            synchronized (this) {
                KaraokeMusicModel entity = changeMusicInfoToModel(musicInfo);
                entity.isSelected = true;
                if (mMusicSelectedList != null && mMusicSelectedList.size() > 0) {
                    mMusicSelectedList.remove(entity);
                }
                notiListChange();
            }
        } else {
            sendDeleteMusic(musicInfo.musicId);
        }
    }

    @Override
    public void deleteAllMusic(String userID, KaraokeMusicCallback.ActionCallback callback) {
        if (mMusicSelectedList.size() <= 0 || userID == null) {
            return;
        }
        //房主下麦
        if (isOwner()) {
            synchronized (this) {
                if (mMusicSelectedList.size() > 0) {
                    List<KaraokeMusicModel> list = new ArrayList<>();
                    for (KaraokeMusicModel temp : mMusicSelectedList) {
                        if (temp != null && userID.equals(temp.userId)) {
                            list.add(temp);
                        }
                    }
                    mMusicSelectedList.removeAll(list);
                    notiListChange();
                }
            }
        } else {
            //如果是其他主播下麦,通知房主删除歌曲,并更新
            sendDeleteAll();
        }
    }

    @Override
    public void topMusic(KaraokeMusicInfo musicInfo, KaraokeMusicCallback.ActionCallback callback) {
        if (mMusicSelectedList.size() <= 2 || !isOwner() || musicInfo.musicId == null) {
            return;
        }

        KaraokeMusicModel entity = null;
        for (KaraokeMusicModel temp : mMusicSelectedList) {
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
    public void nextMusic(KaraokeMusicInfo musicInfo, KaraokeMusicCallback.ActionCallback callback) {
        if (mMusicSelectedList.size() <= 0 || !isOwner()) {
            return;
        }
        KaraokeMusicModel entity = mMusicSelectedList.get(0); //备份

        //如果房主切的是自己的歌
        if (entity.userId.equals(mOwnerId)) {
            if (mSelectDelegates != null) {
                for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                    delegate.onShouldStopPlay(entity);
                }
            }
        } else {
            //如果房主切的其他人的歌,先通知其他人停止播放,然后调用complete发通知给房主,房主确定下一首谁播
            sendShouldStop(entity.userId, entity.musicId);

        }
    }

    @Override
    public void setRoomInfo(TRTCKaraokeRoomDef.RoomInfo roomInfo) {
        mRoomId = String.valueOf(roomInfo.roomId);
        mOwnerId = roomInfo.ownerId;
    }

    @Override
    public void prepareToPlay(String musicID) {
        notiPrepare(musicID);
    }

    @Override
    public void completePlaying(String musicID) {
        if (isOwner()) {
            if (mMusicSelectedList.size() <= 0) {
                if (mSelectDelegates != null) {
                    for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                        delegate.onShouldSetLyric(null);
                    }
                }
                notiPrepare("0");
                return;
            }

            synchronized (this) {
                if (musicID.equals(mMusicSelectedList.get(0).musicId)) {
                    mMusicSelectedList.remove(0); //移除第一首歌
                    notiListChange();
                    notiComplete(musicID);
                }
            }

            synchronized (this) {
                //如果切歌后已点列表还有歌,判断歌曲是谁的,通知播放.
                if (mMusicSelectedList.size() <= 0) {
                    return;
                }
                KaraokeMusicModel curEntity = mMusicSelectedList.get(0);
                if (curEntity != null && curEntity.userId.equals(mOwnerId)) {
                    if (mSelectDelegates != null) {
                        for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                            delegate.onShouldPlay(curEntity);
                        }
                    }
                } else {
                    sendShouldPlay(curEntity.userId, curEntity.musicId);
                }
            }
        } else {
            //主播播放完成/或被踢下麦后后通知房主,房主去删除列表并广播更新
            notiComplete(musicID);
        }
    }

    @Override
    public void onExitRoom() {
        unInitImListener();
        if (mMusicLibraryList != null) {
            mMusicLibraryList.clear();
            mMusicLibraryList = null;
        }
        if (mMusicSelectedList != null) {
            mMusicSelectedList.clear();
            mMusicSelectedList = null;
        }
    }

    @Override
    public void downLoadMusic(KaraokeMusicInfo musicInfo, KaraokeMusicCallback.MusicLoadingCallback callback) {

    }

    @Override
    public String genMusicURI(String musicId, int type) {
        return null;
    }

    @Override
    public boolean isMusicPreloaded(String musicId) {
        return false;
    }

    //将KaraokeMusicInfo转换为KaraokeMusicModel类型
    private KaraokeMusicModel changeMusicInfoToModel(KaraokeMusicInfo info) {
        if (info == null) {
            return null;
        }
        KaraokeMusicModel model = new KaraokeMusicModel();
        model.userId = info.userId;
        model.musicId = info.musicId;
        model.musicName = info.musicName;
        model.singers = info.singers;
        model.originUrl = info.originUrl;
        model.accompanyUrl = info.accompanyUrl;
        model.coverUrl = info.coverUrl;
        model.lrcUrl = info.lrcUrl;
        model.status = info.status;
        model.userId = info.userId;
        model.performId = info.performId;
        return model;
    }

    public KaraokeMusicModel findEntityFromLibrary(String musicId) {
        if (musicId == null || mMusicLibraryList == null) {
            return null;
        }
        for (KaraokeMusicInfo entity : mMusicLibraryList) {
            if (entity.musicId.equals(musicId)) {
                return changeMusicInfoToModel(entity);
            }
        }
        return null;
    }

    public KaraokeMusicModel findEntityFromSelect(String musicId) {
        if (musicId == null || mMusicSelectedList == null) {
            return null;
        }
        for (KaraokeMusicModel entity : mMusicSelectedList) {
            if (entity.musicId.equals(musicId)) {
                return entity;
            }
        }
        return null;
    }

    // 收发信息的管理
    // 准备播放，发通知，收到通知后应准备好歌词
    private void notiPrepare(String musicId) {
        String data = buildSingleMsg(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MPREPARE, musicId);
        Log.d(TAG, "sendNoti: cmd= " + KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MPREPARE);
        sendNoti(data);
    }

    // 播放完成时，应发送complete消息,然后房主进行列表更新,并通知其他人
    private void notiComplete(String musicId) {
        if (mSelectDelegates != null) {
            for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                delegate.onShouldSetLyric(null);
            }
        }
        String data = buildSingleMsg(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MCOMPLETE, musicId);
        Log.d(TAG, "sendNoti: cmd= " + KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MCOMPLETE);
        sendNoti(data);
    }

    // 给某人发送应该播放音乐了（下一个是你）
    private void sendShouldPlay(String userId, String musicId) {
        sendInstruction(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MPLAYMUSIC, userId, musicId);
    }

    // 给某人发送应该停止了（被切歌了）
    private void sendShouldStop(String userId, String musicId) {
        sendInstruction(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MSTOP, userId, musicId);
    }

    //主播删除自己的歌
    private void sendDeleteMusic(String musicId) {
        sendInstruction(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MDELETE, mOwnerId, musicId);
    }

    //主播下麦发通知给房主清除列表
    private void sendDeleteAll() {
        sendInstruction(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MDELETEALL, mOwnerId, "");
    }

    private void sendRequestSelectedList() {
        sendInstruction(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MGETLIST, mOwnerId, "");
    }

    // 广播通知列表发生变化
    private void notiListChange() {
        if (mSelectDelegates != null) {
            for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                delegate.OnMusicListChange(mMusicSelectedList);
            }
        }

        String data = buildGroupMsg(KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MLISTCHANGE, mMusicSelectedList);
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
        V2TIMManager.getInstance().sendGroupCustomMessage(data.getBytes(), mRoomId, V2TIMMessage.V2TIM_PRIORITY_NORMAL, new V2TIMValueCallback<V2TIMMessage>() {
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
        V2TIMManager.getInstance().sendC2CCustomMessage(data.getBytes(), userId, new V2TIMValueCallback<V2TIMMessage>() {
            @Override
            public void onSuccess(V2TIMMessage v2TIMMessage) {
            }

            @Override
            public void onError(int code, String desc) {
                TRTCLogger.d(TAG, "sendInstruction onError: code = " + code);
            }
        });
    }

    private class KTVMusicListener extends V2TIMSimpleMsgListener {
        public KTVMusicListener() {
            super();
        }

        @Override
        public void onRecvC2CTextMessage(String msgID, V2TIMUserInfo sender, String text) {
            super.onRecvC2CTextMessage(msgID, sender, text);
        }

        @Override
        public void onRecvC2CCustomMessage(String msgID, V2TIMUserInfo sender, byte[] customData) {
            String customStr = new String(customData);
            if (TextUtils.isEmpty(customStr)) {
                Log.d(TAG, "onRecvC2CCustomMessage  the customData is null");
                return;
            }
            try {
                Gson gson = new Gson();
                KaraokeJsonData jsonData = gson.fromJson(customStr, KaraokeJsonData.class);
                String businessID = jsonData.getBusinessID();
                if (!KaraokeConstants.KARAOKE_VALUE_CMD_BUSINESSID.equals(businessID)) {
                    return;
                }
                KaraokeJsonData.Data data = jsonData.getData();
                String instruction = data.getInstruction();
                String musicId = data.getContent();
                KaraokeMusicModel entity = findEntityFromLibrary(musicId);
                TRTCLogger.d(TAG, "RecvC2CMessage: instruction = " + instruction + " customStr = " + customStr);
                switch (instruction) {
                    case KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MGETLIST:
                        //房主收到其他人的进房请求后,更新列表,然后通知去设置歌词
                        if (!isOwner()) {
                            return;
                        }
                        notiListChange();
                        if (mMusicSelectedList.size() > 0) {
                            notiPrepare(mMusicSelectedList.get(0).musicId);
                        }
                        break;
                    case KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MPICK:
                        //房主收到其他人的点歌后,去更新列表并通知主播去播放;其他人不处理该通知
                        if (!isOwner()) {
                            return;
                        }
                        boolean shouPlay = mMusicSelectedList.size() == 0;
                        entity.userId = sender.getUserID();
                        mMusicSelectedList.add(entity);
                        notiListChange();
                        if (shouPlay) {
                            sendShouldPlay(sender.getUserID(), entity.musicId);
                        }
                        if (mSelectDelegates != null) {
                            for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                                delegate.onShouldShowMessage(entity);
                            }
                        }
                        break;
                    case KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MPLAYMUSIC:
                        if (mSelectDelegates != null) {
                            for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                                delegate.onShouldPlay(entity);
                            }
                        }
                        break;
                    case KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MSTOP:
                        if (mSelectDelegates != null && mSelectDelegates.size() > 0) {
                            for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                                delegate.onShouldStopPlay(entity);
                            }
                        }
                        break;
                    case KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MDELETE:
                        //房主收到主播删除歌曲的请求后,直接删除歌曲
                        KaraokeMusicModel model = findEntityFromSelect(musicId);
                        if (mMusicSelectedList.size() > 0 && model != null) {
                            mMusicSelectedList.remove(model);
                        }
                        notiListChange();
                        break;
                    case KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MDELETEALL:
                        // 房主处理,其他人收到不处理
                        if (!isOwner()) {
                            return;
                        }
                        if (mMusicSelectedList.size() > 0) {
                            List<KaraokeMusicModel> list = new ArrayList<>();
                            for (KaraokeMusicModel temp : mMusicSelectedList) {
                                if (sender != null && sender.getUserID().equals(temp.userId)) {
                                    list.add(temp);
                                }
                            }
                            mMusicSelectedList.removeAll(list);
                            notiListChange();
                        }
                        break;
                    default:
                        break;
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        @Override
        public void onRecvGroupTextMessage(String msgID, String groupID, V2TIMGroupMemberInfo sender, String text) {
            super.onRecvGroupTextMessage(msgID, groupID, sender, text);
        }

        @Override
        public void onRecvGroupCustomMessage(String msgID, String groupID, V2TIMGroupMemberInfo sender, byte[] customData) {
            String customStr = new String(customData);
            if (TextUtils.isEmpty(customStr)) {
                Log.d(TAG, "onRecvC2CCustomMessage  the customData is null");
                return;
            }
            Gson gson = new Gson();
            KaraokeJsonData jsonData = gson.fromJson(customStr, KaraokeJsonData.class);
            String businessID = jsonData.getBusinessID();
            if (!KaraokeConstants.KARAOKE_VALUE_CMD_BUSINESSID.equals(businessID)) {
                return;
            }
            KaraokeJsonData.Data data = jsonData.getData();
            String instruction = data.getInstruction();
            String musicId = data.getContent();
            TRTCLogger.d(TAG, "RecvGroupMessage instruction = " + instruction + " ,data = " + data);
            switch (instruction) {
                case KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MLISTCHANGE:
                    List<KaraokeMusicModel> list = new ArrayList<>();
                    Gson gsonTemp = new Gson();
                    list = gsonTemp.fromJson(data.getContent(),
                            new TypeToken<List<KaraokeMusicModel>>() {
                            }.getType());

                    mMusicSelectedList.clear();
                    //避免ios端和Android数据不一致导致的数据异常
                    //根据musicId对齐两端的信息
                    if (list.size() > 0) {
                        for (KaraokeMusicModel temp : list) {
                            if (temp != null) {
                                KaraokeMusicModel tempEntity = findEntityFromLibrary(temp.musicId);
                                if (tempEntity != null) {
                                    tempEntity.userId = temp.userId;
                                    tempEntity.isSelected = temp.isSelected;
                                    mMusicSelectedList.add(tempEntity);
                                }
                            }
                        }
                    }
                    //收到列表变化的通知,去更新自己的界面信息
                    if (mSelectDelegates != null && mSelectDelegates.size() > 0) {
                        for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                            delegate.OnMusicListChange(mMusicSelectedList);
                        }
                    }
                    break;
                case KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MPREPARE:
                    mCurrentMusicId = musicId;
                    if (mSelectDelegates != null) {
                        for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                            delegate.onShouldSetLyric(findEntityFromLibrary(mCurrentMusicId));
                        }
                    }
                    break;
                case KaraokeConstants.KARAOKE_VALUE_CMD_INSTRUCTION_MCOMPLETE:
                    if (mCurrentMusicId == null || musicId.equals(mCurrentMusicId)) {
                        if (mSelectDelegates != null) {
                            for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                                delegate.onShouldSetLyric(null);
                            }
                        }
                    }
                    //房主收到后处理,其他人不处理
                    if (!isOwner()) {
                        return;
                    }
                    if (mMusicSelectedList.size() > 0 && musicId != null) {
                        KaraokeMusicModel temp = null;
                        for (KaraokeMusicModel model : mMusicSelectedList) {
                            if (model != null && musicId.equals(model.musicId)) {
                                temp = model;
                            }
                        }
                        if (temp != null) {
                            mMusicSelectedList.remove(temp);
                            notiListChange();
                        }
                    }
                    //如果切歌后已点列表还有歌,判断歌曲是谁的,通知播放.
                    if (mMusicSelectedList.size() > 0) {
                        KaraokeMusicModel curEntity = mMusicSelectedList.get(0);
                        if (curEntity.userId.equals(mOwnerId)) {
                            if (mSelectDelegates != null) {
                                for (KaraokeMusicServiceDelegate delegate : mSelectDelegates) {
                                    delegate.onShouldPlay(curEntity);
                                }
                            }
                        } else {
                            sendShouldPlay(curEntity.userId, curEntity.musicId);
                        }
                    }
                    break;
                default:
                    break;
            }
        }
    }
}

package com.tencent.liteav.tuikaraoke.ui.music;

import com.tencent.liteav.tuikaraoke.model.TRTCKaraokeRoomDef;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.ui.base.KaraokeMusicModel;

public abstract class KaraokeMusicService {

    //////////////////////////////////////////////////////////
    //                 歌曲列表管理
    //////////////////////////////////////////////////////////

    /**
     * 热门推荐歌单列表
     */
    public abstract void ktvGetPopularMusic(KaraokeMusicCallback.PopularMusicListCallback callback);

    /**
     * * 获取歌曲列表
     *
     * @param playlistId 分类详情
     */
    public abstract void ktvGetMusicPage(String playlistId, KaraokeMusicCallback.MusicListCallback callback);

    /**
     * 获取搜索歌曲列表
     *
     * @param scrollToken 分页的滚动标记
     * @param pageSize    分页大小
     * @param keyWords    搜索词
     */
    public abstract void ktvSearchMusicByKeyWords(String scrollToken, int pageSize, String keyWords,
                                                  KaraokeMusicCallback.MusicListPagingCallback callback);

    /**
     * 获取已点歌曲列表
     */
    public abstract void ktvGetSelectedMusicList(KaraokeMusicCallback.MusicSelectedListCallback callback);

    /**
     * 选择歌曲
     *
     * @param musicInfo 歌曲信息
     */
    public abstract void pickMusic(KaraokeMusicInfo musicInfo, KaraokeMusicCallback.ActionCallback callback);

    /**
     * 删除歌曲
     *
     * @param musicInfo 歌曲信息
     */
    public abstract void deleteMusic(KaraokeMusicInfo musicInfo, KaraokeMusicCallback.ActionCallback callback);

    /**
     * 删除某个用户全部已点歌曲
     *
     * @param userID 用户ID
     */
    public abstract void deleteAllMusic(String userID, KaraokeMusicCallback.ActionCallback callback);

    /**
     * 置顶歌曲
     *
     * @param musicInfo 歌曲信息
     */

    public abstract void topMusic(KaraokeMusicInfo musicInfo, KaraokeMusicCallback.ActionCallback callback);

    /**
     * 切歌
     *
     * @param musicInfo 歌曲信息
     */
    public abstract void nextMusic(KaraokeMusicInfo musicInfo, KaraokeMusicCallback.ActionCallback callback);

    /**
     * 歌曲即将播放
     *
     * @param musicID 歌曲ID
     */
    public abstract void prepareToPlay(String musicID);

    /**
     * 歌曲播放完成
     *
     * @param musicID 歌曲ID
     */
    public abstract void completePlaying(String musicID);

    /**
     * 退出房间
     */
    public abstract void onExitRoom();

    //////////////////////////////////////////////////////////
    //                 预加载管理
    //////////////////////////////////////////////////////////

    /**
     * 下载歌曲
     *
     * @param musicInfo 歌曲信息
     */
    public abstract void downLoadMusic(KaraokeMusicInfo musicInfo, KaraokeMusicCallback.MusicLoadingCallback callback);

    /**
     * 生成歌曲URL,客户端播放的时候调用,传给trtc进行播放,与preloadMusic--对应
     *
     * @param musicId 歌曲Id
     * @param type    类型
     */
    public abstract String genMusicURI(String musicId, int type);

    /**
     * 获取当前播放的歌曲信息
     */
    public abstract KaraokeMusicModel getCurrentPlayMusicModel();

    /**
     * 检测是否已经加载音乐数据
     *
     * @param musicId 歌曲Id
     */
    public abstract boolean isMusicPreloaded(String musicId);

    //////////////////////////////////////////////////////////
    //                 房间信息传递
    //////////////////////////////////////////////////////////

    /**
     * 设置房间信息
     *
     * @param roomInfo 房间信息
     */
    public abstract void setRoomInfo(TRTCKaraokeRoomDef.RoomInfo roomInfo);

    /**
     * 设置歌曲管理回调对象
     *
     * @param delegate 代理实现对象
     */
    public abstract void setServiceDelegate(KaraokeMusicServiceDelegate delegate);
}

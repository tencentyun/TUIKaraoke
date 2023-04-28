package com.tencent.liteav.tuikaraoke.model;

import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicPageInfo;
import com.tencent.liteav.tuikaraoke.model.impl.base.KaraokeMusicTag;
import com.tencent.qcloud.tuicore.interfaces.TUICallback;
import com.tencent.qcloud.tuicore.interfaces.TUIValueCallback;

import java.util.List;

public abstract class KaraokeMusicService {

    /**
     * 设置歌曲管理回调对象
     *
     * @param delegate 代理实现对象
     */
    public abstract void addObserver(KaraokeMusicServiceObserver delegate);

    /**
     * 销毁实例
     */
    public abstract void destroyService();

    /**
     * 歌曲标签列表
     */
    public abstract void getMusicTagList(TUIValueCallback<List<KaraokeMusicTag>> callback);


    /**
     * 搜索歌曲标签下的歌曲信息
     */
    public abstract void getMusicsByTagId(String tagId, String scrollToken,
                                          TUIValueCallback<KaraokeMusicPageInfo> callback);

    /**
     * 获取搜索歌曲列表
     *
     * @param scrollToken 分页的滚动标记
     * @param pageSize    分页大小
     * @param keyWords    搜索词
     */
    public abstract void getMusicsByKeywords(String scrollToken, int pageSize, String keyWords,
                                             TUIValueCallback<KaraokeMusicPageInfo> callback);

    /**
     * 获取已点歌曲列表
     */
    public abstract void getPlaylist(TUIValueCallback<List<KaraokeMusicInfo>> callback);

    /**
     * 选择歌曲
     * - 通知后台点歌了（pickMusic）
     *   - 成功：
     *     - 发群通知：歌曲列表更新了
     *     - 下载歌曲
     *       - 成功：
     *         - 更新本地歌单，并回调通知外部 (onMusicListChange)
     *           - 副唱/观众收到后，先下载首歌，然后通知外部更新UI（歌曲信息、歌词信息）
     *       - 失败：
     *   - 失败：
     * @param musicInfo 歌曲信息
     */
    public abstract void addMusicToPlaylist(KaraokeMusicInfo musicInfo, KaraokeAddMusicCallback callback);

    /**
     * 删除歌曲
     *
     * @param musicInfo 歌曲信息
     */
    public abstract void deleteMusicFromPlaylist(KaraokeMusicInfo musicInfo, TUICallback callback);

    /**
     * 删除某个用户全部已点歌曲
     *
     * @param userID 用户ID
     */
    public abstract void clearPlaylistByUserId(String userID, TUICallback callback);

    /**
     * 置顶歌曲
     *
     * @param musicInfo 歌曲信息
     */

    public abstract void topMusic(KaraokeMusicInfo musicInfo, TUICallback callback);

    /**
     * 切歌
     *
     * @param musicInfo 歌曲信息
     */
    public abstract void switchMusicFromPlaylist(KaraokeMusicInfo musicInfo, TUICallback callback);

    /**
     * 歌曲播放完成
     *
     * @param musicInfo 歌曲信息
     */
    public abstract void completePlaying(KaraokeMusicInfo musicInfo);
}

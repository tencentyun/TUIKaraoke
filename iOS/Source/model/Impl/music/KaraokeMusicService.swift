//
//  KaraokeMusicService.swift
//  TUIKaraoke
//
//  Created by gg on 2021/7/8.
//  Copyright © 2022 Tencent. All rights reserved.

import Foundation

/**
 * 歌曲信息列表回调
 */
public typealias MusicListCallback = (_ errorCode: NSInteger, _ errorMessage: String, _ list: [KaraokeMusicInfo], _ scrollToken: String) -> Void

/**
 * 歌曲标签列表回调
 */
public typealias MusicTagListCallback = (_ errorCode: NSInteger, _ errorMessage: String, _ list: [KaraokeMusicTagModel]) -> Void

/**
 * 已选列表回调
 */
public typealias MusicSelectedListCallback = (_ errorCode: NSInteger, _ errorMessage: String, _ list: [KaraokeMusicInfo]) -> Void

/**
 * 开始下载回调
 */
public typealias MusicStartCallback = (_ musicInfo: KaraokeMusicInfo) -> Void

/**
 * 下载进度回调
 */
public typealias MusicProgressCallback = (_ musicInfo: KaraokeMusicInfo?, _ progress: Float) -> Void

/**
 * 下载完成回调
 */
public typealias MusicFinishCallback = (_ musicInfo: KaraokeMusicInfo, _ errorCode: Int32, _ msg: String) -> Void

/**
 * 添加歌曲回调
 */
public typealias KaraokeAddMusicCallback = (start: MusicStartCallback, progress: MusicProgressCallback, finish: MusicFinishCallback)

/**
 * 歌曲管理接口
 */
public protocol KaraokeMusicService: AnyObject {
    //////////////////////////////////////////////////////////
    //                 歌曲列表管理
    //////////////////////////////////////////////////////////
    
    /**
     * 设置回调对象
     * - parameter observer   代理实现对象
     */
    func addObserver(_ observer: KaraokeMusicServiceObserver)
    
    /**
     * 销毁对象
     */
    func destroyService()
    
    /**
     * 歌曲标签列表
     */
    func getMusicTagList(callback: @escaping MusicTagListCallback)
    
    /**
     * 搜索歌曲标签下的歌曲信息
     * - parameter tagId    歌曲标签ID
     */
    func getMusicsByTagId(tagId: String, scrollToken: String, callback: @escaping MusicListCallback)
    
    /**
     * 搜索
     * - parameter keyWord     搜索词
     * - parameter limit       分页大小
     * - parameter scrollToken 分页游标
     * 获取歌曲搜索
     */
    func getMusicsByKeywords(keyWord: String, limit: Int, scrollToken: String, callback: @escaping MusicListCallback)
    
    
    /**
     * 获取已点歌曲列表
     */
    func getPlaylist(_ callback: @escaping MusicSelectedListCallback)
    
    /**
     * 添加歌曲
     * - parameter musicInfo   歌曲model
     */
    func addMusicToPlaylist(musicInfo: KaraokeMusicInfo, callBack: KaraokeAddMusicCallback)
    
    /**
     * 删除歌曲
     * - parameter musicInfo   歌曲model
     */
    func deleteMusicFromPlaylist(musicInfo: KaraokeMusicInfo, callback: @escaping KaraokeCallback)
    
    /**
     * 删除某个用户全部已点歌曲
     * - parameter userID   用户ID
     */
    func clearPlaylistByUserId(userID: String, callback: @escaping KaraokeCallback)
    
    /**
     * 置顶歌曲
     * - parameter musicInfo   歌曲model
     */
    func topMusic(musicInfo: KaraokeMusicInfo, callback: @escaping KaraokeCallback)
    
    /**
     * 切歌
     * - parameter musicInfo   歌曲model
     */
    func switchMusicFromPlaylist(musicInfo: KaraokeMusicInfo, callback: @escaping KaraokeCallback)
    
    /**
     * 播放完成
     * - parameter musicInfo   歌曲model
     */
    func completePlaying(musicInfo: KaraokeMusicInfo, callback: @escaping KaraokeCallback)
    
}

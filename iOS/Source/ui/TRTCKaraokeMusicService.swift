//
//  TRTCKaraokeMusicDelegate.swift
//  TUIKaraoke
//
//  Created by gg on 2021/7/8.
//  Copyright © 2022 Tencent. All rights reserved.

import Foundation

/**
 * 歌曲信息列表回调
 */
public typealias MusicListCallback = (_ errorCode: NSInteger, _ errorMessage: String, _ list: [KaraokeMusicInfo]) -> Void

/**
 * 热门推荐歌单列表回调
 */
public typealias PopularMusicListCallback = (_ errorCode: NSInteger, _ errorMessage: String, _ list: [KaraokePopularInfo]) -> Void

/**
 * 已选列表回调
 */
public typealias MusicSelectedListCallback = (_ errorCode: NSInteger, _ errorMessage: String, _ list: [KaraokeMusicModel]) -> Void

/**
 * 下载完成回调
 */
public typealias MusicFinishCallback = (_ musicId: String, _ errorCode: Int32, _ msg: String) -> Void
/**
 * 下载进度回调
 */
public typealias MusicProgressCallback = (_ musicId: String?, _ progress: Float) -> Void

/**
 * 歌曲管理接口
 */
public protocol KaraokeMusicService: AnyObject {
    //////////////////////////////////////////////////////////
//                 歌曲列表管理
    //////////////////////////////////////////////////////////

    /**
     * 获取歌曲列表
     * - parameter playlistId          playlistId
     * - parameter offset          分页游标
     * - parameter pageSize     分页大小  
     */
    func ktvGetMusicPage(playlistId: String, offset: Int, pageSize:Int, callback: @escaping MusicListCallback)

    /**
     * 热门推荐歌单列表
     */
    func ktvGetPopularMusic(callback: @escaping PopularMusicListCallback)

    /**
     * 搜索
     * - parameter offset    分页游标
     * - parameter pageSize    分页大小
     * - parameter keyWords     搜索词
     * 获取歌曲搜索
     */
    func ktvSearchMusicByKeyWords(offset: Int, pageSize:Int, keyWords: String, callback: @escaping MusicListCallback)

    /**
     * 获取已点歌曲列表
     */
    func ktvGetSelectedMusicList(_ callback: @escaping MusicSelectedListCallback)

    /**
     * 选择歌曲
     * - parameter musicInfo   歌曲model
     */
    func pickMusic(musicInfo: KaraokeMusicInfo, callback: @escaping ActionCallback)

    /**
     * 删除歌曲
     * - parameter musicInfo   歌曲model
     */
    func deleteMusic(musicInfo: KaraokeMusicInfo, callback: @escaping ActionCallback)

    /**
     * 删除某个用户全部已点歌曲
     * - parameter userID   用户ID
     */
    func deleteAllMusic(userID: String, callback: @escaping ActionCallback)

    /**
     * 置顶歌曲
     * - parameter musicInfo   歌曲model
     */
    func topMusic(musicInfo: KaraokeMusicInfo, callback: @escaping ActionCallback)

    /**
     * 切歌
     * - parameter musicInfo   歌曲model
     */
    func nextMusic(musicInfo: KaraokeMusicInfo, callback: @escaping ActionCallback)

    /**
     * 歌曲即将播放
     * - parameter musicID   歌曲ID
     */
    func prepareToPlay(musicID: String)

    /**
     * 歌曲播放完成
     * - parameter musicID   歌曲ID
     */
    func completePlaying(musicID: String)

    /**
     * 退出房间
     */
    func onExitRoom()

    //////////////////////////////////////////////////////////
//                 预加载管理
    //////////////////////////////////////////////////////////

    /**
     * 下载歌曲
     * - parameter musicInfo   歌曲model
     */
    func downloadMusic(_ musicInfo: KaraokeMusicInfo, progress: @escaping MusicProgressCallback, complete: @escaping MusicFinishCallback)

    //////////////////////////////////////////////////////////
//                 房间信息传递
    //////////////////////////////////////////////////////////

    /**
     * 设置房间信息
     * - parameter roomInfo   房间信息
     */
    func setRoomInfo(roomInfo: RoomInfo)

    /**
     * 设置回调对象
     * - parameter delegate   代理实现对象
     */
    func setServiceDelegate(_ delegate: KaraokeMusicServiceDelegate)

    /**
     * 检测是否已预加载音乐数据
     * - parameter musicId 歌曲Id
     */
    func isMusicPreloaded(musicId: String) -> Bool

    /**
     * 生成音乐 URI，App客户端，播放时候调用，传给trtc进行播放。与preloadMusic一一对应
     * - parameter musicId 歌曲Id
     * - parameter bgmType 0：原唱，1：伴奏  2:  歌词
     */
    func genMusicURI(musicId: String, bgmType: Int32) -> String
}

/**
 * 歌曲管理回调接口
 */
public protocol KaraokeMusicServiceDelegate: AnyObject {
    /**
     * 歌曲列表更新回调
     * - parameter musicInfoList   已点歌曲列表数组
     */
    func onMusicListChange(musicInfoList: [KaraokeMusicModel], reason: Int)

    /**
     * 歌词设置回调
     * - parameter musicID   歌曲ID
     */
    func onShouldSetLyric(musicID: String)

    /**
     * 歌曲播放回调
     * - parameter music   音乐model
     */
    func onShouldPlay(_ music: KaraokeMusicModel) -> Bool

    /**
     * 歌曲停止回调
     * - parameter music   音乐model
     */
    func onShouldStopPlay(_ music: KaraokeMusicModel?)

    /**
     * 点歌信息展示回调
     * - parameter music   音乐model
     */
    func onShouldShowMessage(_ music: KaraokeMusicModel)
    
    /**
     * 歌曲下载成功
     * - parameter musicId   音乐Id
     */
    func onDownloadMusicComplete(_ musicId: String)
}

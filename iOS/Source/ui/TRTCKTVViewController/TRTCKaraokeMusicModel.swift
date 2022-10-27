//
//  TRTCKaraokeMusicModel.swift
//  TUIKaraoke
//
//  Created by gg on 2021/6/29.
//  Copyright © 2022 Tencent. All rights reserved.

import Foundation
let KaraokeFileDirectoryPath = NSHomeDirectory().appending("/Documents/Karaoke") // 返回歌词缓存路径

public enum KaraokeMusicStatus: NSInteger {
    case wait = 0
    case playing = 1
    case completePlay = 2
    case pause = 3
}

public class KaraokeMusicCacheDelegate: NSObject {
    weak static var musicDataSource: KaraokeMusicService?

    /**
     * 生成音乐 URI，App客户端，播放时候调用，传给trtc进行播放。与preloadMusic一一对应
     * - parameter musicId 歌曲Id
     * - parameter bgmType 0：原唱，1：伴奏  2:  歌词
     */
    static func genMusicURI(musicId: String, bgmType: Int32) -> String {
        return musicDataSource?.genMusicURI(musicId: musicId, bgmType: bgmType) ?? ""
    }

    /**
     * 检测是否已预加载音乐数据
     * - parameter musicId 歌曲Id
     */
    static func isMusicPreloaded(musicId: String) -> Bool {
        return musicDataSource?.isMusicPreloaded(musicId: musicId) ?? false
    }
}

public class KaraokePopularInfo: NSObject {
    // 只读属性
    public let popularDescription: String // description
    public let musicNum: NSInteger // musicNum
    public let topic: String // topic
    public let playlistId: String // playlistId
    public init(playlistId: String, topic: String, musicNum: NSInteger = 0, description: String = "") {
        self.playlistId = playlistId
        self.topic = topic
        self.musicNum = musicNum
        popularDescription = description
    }

    // 推荐，json->model
    public static func jsonPopularInfo(_ json: [String: Any]) -> KaraokePopularInfo? {
        guard let topic = json["topic"] as? String else { return nil }
        guard let playlistId = json["playlistId"] as? String else { return nil }
        let info = KaraokePopularInfo(playlistId: playlistId, topic: topic)
        return info
    }
}

public class KaraokeMusicInfo: NSObject {
    // 只读属性
    public let musicName: String // title
    public let singers: [String] // singers
    public var userId: String // 点歌用户的ID
    public let performId: String // 表演ID，歌单中的一首歌叫一次表演
    private(set) var status: KaraokeMusicStatus = .wait // - status: 0 等待中  状态 1播放中  2播放完成，2就会在列表中移除
    public let coverUrl: String = "" // 封面
    private let musicId: String // 网络传输交互需要

    private(set) var playToken: String = "" // playToken 服务器播放资源token
    public var lyricsUrl: String = ""
    public init(musicId: String, musicName: String, singers: [String], userId: String = "", performId: String = "0", status: KaraokeMusicStatus = .wait) {
        self.musicId = musicId
        self.musicName = musicName
        self.singers = singers
        self.userId = userId
        self.performId = performId
        self.status = status
    }
    
    // set get 方法
    // 动态获取
    // 返回歌词,本地资源链接
    var _lrcLocalPath: String?
    public var lrcLocalPath: String {
        set {
            _lrcLocalPath = newValue
        }
        get {
            if let lrcLocalPath = _lrcLocalPath, lrcLocalPath.byteLength() > 1 {
                return _lrcLocalPath!
            } else {
                if downloadCreateDirectory() {
                    let localPath = lrcDonwloadLocalPath
                    if FileManager.default.fileExists(atPath: localPath) {
                        return localPath
                    }
                }
                if isContentReady {
                    return KaraokeMusicCacheDelegate.genMusicURI(musicId: musicId, bgmType: 2)
                } else {
                    return ""
                }
            }
        }
    }

    // 返回歌词,本地资源链接
    public var lrcDonwloadLocalPath: String {
        let downloadPath = KaraokeFileDirectoryPath.appending("/\(musicId).vtt")
        return downloadPath
    }

    // 返回原生,本地资源链接
    var _muscicLocalPath: String?
    public var muscicLocalPath: String {
        set {
            _muscicLocalPath = newValue
        }
        get {
            if let muscicLocalPath = _muscicLocalPath, muscicLocalPath.byteLength() > 1 {
                return _muscicLocalPath!
            } else {
                if isContentReady {
                    return KaraokeMusicCacheDelegate.genMusicURI(musicId: musicId, bgmType: 0)
                } else {
                    return ""
                }
            }
        }
    }

    // 返回伴奏,本地资源链接
    var _accompanyLocalPath: String?
    public var accompanyLocalPath: String {
        set {
            _accompanyLocalPath = newValue
        }
        get {
            if let accompanyLocalPath = _accompanyLocalPath, accompanyLocalPath.byteLength() > 1 {
                return _accompanyLocalPath!
            } else {
                if isContentReady {
                    return KaraokeMusicCacheDelegate.genMusicURI(musicId: musicId, bgmType: 1)
                } else {
                    return ""
                }
            }
        }
    }

    public func singer() -> String {
        return singers.joined(separator: ";")
    }

    // set get 方法
    public var isContentReady: Bool {
        return KaraokeMusicCacheDelegate.isMusicPreloaded(musicId: musicId)
    }

    public var isLyricsReady: Bool {
        if downloadCreateDirectory() {
            if FileManager.default.fileExists(atPath: lrcLocalPath) {
                return true
            }
        }
        return isContentReady
    }

    private func downloadCreateDirectory() -> Bool {
        if FileManager.default.fileExists(atPath: KaraokeFileDirectoryPath) == false {
            do {
                try FileManager.default.createDirectory(atPath: KaraokeFileDirectoryPath, withIntermediateDirectories: true, attributes: nil)
                return true
            } catch {
                print("failed to create")
                return false
            }
        }
        return true
    }

    public func updateToken(playToken: String) {
        self.playToken = playToken
    }

    public func getMusicId() -> String {
        return musicId
    }

    // 搜索歌曲，json->model
    public static func jsonSearchMusic(_ json: [String: Any]) -> KaraokeMusicInfo? {
        guard let musicId = json["musicId"] as? String else { return nil }
        guard let musicName = json["title"] as? String else { return nil }
        guard let singers = json["singers"] as? [String] else { return nil }
        let info = KaraokeMusicInfo(musicId: musicId, musicName: musicName, singers: singers)
        return info
    }

    // 热门推荐歌单，json->model
    public static func jsonPopularMusic(_ json: [String: Any]) -> KaraokeMusicInfo? {
        guard let musicId = json["musicId"] as? String else { return nil }
        guard let musicName = json["title"] as? String else { return nil }
        guard let singers = json["singerSet"] as? [String] else { return nil }
        let info = KaraokeMusicInfo(musicId: musicId, musicName: musicName, singers: singers)
        return info
    }

    // 已选歌曲，json->model
    public static func jsonSelectedMusic(_ json: [String: Any]) -> KaraokeMusicInfo? {
        guard let musicId = json["musicId"] as? String else { return nil }
        guard let userId = json["userId"] as? String else { return nil }
        guard let performId = json["performId"] as? String else { return nil }
        guard let musicName = json["title"] as? String else { return nil }
        guard let singers = json["singers"] as? [String] else { return nil }
        let status = json["status"] as? KaraokeMusicStatus
        let info = KaraokeMusicInfo(musicId: musicId, musicName: musicName, singers: singers, userId: userId, performId: performId, status: status ?? .wait)
        return info
    }
    
    // Copy
    public static func copyMusic(_ obj: KaraokeMusicInfo) -> KaraokeMusicInfo {
        let coyObj = KaraokeMusicInfo(musicId: obj.musicId, musicName: obj.musicName, singers: obj.singers, performId: obj.performId);
        coyObj.userId = obj.userId
        coyObj.lrcLocalPath = obj.lrcLocalPath
        coyObj.muscicLocalPath = obj.muscicLocalPath
        coyObj.accompanyLocalPath = obj.accompanyLocalPath
        return coyObj
    }
}

public class KaraokeMusicModel: NSObject {
    public let music: KaraokeMusicInfo

    public var isSelected: Bool = false

    public var seatIndex: Int = -1
    public var bookUserName: String = ""
    public var bookUserAvatar: String = ""
    public var userId: String = ""

    public var coverUrl: String {
        return music.coverUrl
    }

    public var musicName: String {
        return music.musicName
    }

    public var singer: String {
        return music.singer()
    }

    public var contentUrl: String {
        return music.muscicLocalPath
    }

    public var lrcUrl: String {
        return music.lrcLocalPath
    }

    public var musicID: Int32 {
        return Int32(music.performId) ?? 0
    }

    public init(sourceModel: KaraokeMusicInfo) {
        music = sourceModel
        super.init()
    }

    public var jsonDic: [String: Any] {
        var dic: Dictionary<String, Any> = [:]
        dic["musicId"] = music.getMusicId()
        dic["musicName"] = musicName
        dic["singers"] = music.singers
        dic["lrcUrl"] = lrcUrl
        dic["contentUrl"] = contentUrl
        dic["coverUrl"] = coverUrl
        dic["userId"] = userId
        dic["performId"] = music.performId
        return dic
    }

    public static func json(_ json: [String: Any]) -> KaraokeMusicModel? {
        guard let musicIDStr = json["musicId"] as? String else { return nil }
        guard let title = json["musicName"] as? String else { return nil }
        guard let singers = json["singers"] as? [String] else { return nil }
        guard let performId = json["performId"] as? String else { return nil }
        
        let info = KaraokeMusicInfo(musicId: musicIDStr, musicName: title, singers: singers, userId: "", performId: performId, status: .wait)
        let model = KaraokeMusicModel(sourceModel: info)
        guard let userId = json["userId"] as? String else { return nil }
        model.userId = userId
        info.userId = userId;
        return model
    }

    public func reset() {
        isSelected = false
        seatIndex = -1
        bookUserName = ""
        userId = ""
        bookUserAvatar = ""
    }
}

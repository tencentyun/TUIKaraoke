//
//  TRTCKaraokeMusicModel.swift
//  TUIKaraoke
//
//  Created by gg on 2021/6/29.
//  Copyright © 2022 Tencent. All rights reserved.

import Foundation

public enum KaraokeMusicStatus: NSInteger {
    case wait = 0
    case playing = 1
    case completePlay = 2
    case pause = 3
}

public class KaraokeMusicInfo: NSObject {
    // 歌曲相关字段
    public let musicId: String               // 网络传输交互需要
    public let musicName: String             // 歌曲名
    public let singers: [String]             // 演唱者
    public let coverUrl: String              // 歌曲封面
    public var performId: String = ""        // 表演ID，歌单中的一首歌叫一次表演
    private(set) var playToken: String = ""  // playToken 服务器播放资源token
    private(set) var status: KaraokeMusicStatus = .wait // - status: 0 等待中  状态 1播放中  2播放完成，2就会在列表中移除
    
    // 点歌状态记录
    public var isSelected: Bool = false     // 已选状态
    public var userId: String = ""          // 点歌用户的ID
    public var accompanyUrl: String?        // 歌曲伴奏URL
    public var originUrl: String = ""       // 歌曲原唱URL
    public var lyricsUrl: String = ""       // 歌曲歌词URL
    public var midiUrl: String = ""         // 歌曲音高URL
    
    public init(musicId: String,
                musicName: String,
                singers: [String],
                coverUrl: String = "",
                userId: String = "",
                performId: String = "",
                status: KaraokeMusicStatus = .wait) {
        self.musicId = musicId
        self.musicName = musicName
        self.singers = singers
        self.coverUrl = coverUrl
        self.userId = userId
        self.performId = performId
        self.status = status
    }
    
    public func singer() -> String {
        return singers.joined(separator: ";")
    }
    
    public func updateToken(playToken: String) {
        self.playToken = playToken
    }
    
    public func getMusicId() -> String {
        return musicId
    }
    
    public func isPreloaded() -> Bool {
        return originUrl.count > 0
    }
    
    // 歌曲Json转Model
    public static func convertJsonToMusicInfo(_ json: [String: Any]) -> KaraokeMusicInfo? {
        guard let musicId = json["MusicId"] as? String else { return nil }
        guard let musicName = json["Name"] as? String else { return nil }
        guard let singers = json["SingerSet"] as? [String] else { return nil }
        var coverUrl = ""
        if let albumInfo = json["AlbumInfo"] as? [String : Any],
           let coverInfoSet = albumInfo["CoverInfoSet"] as? [Any],
           let coverMiniInfo = coverInfoSet.first as? [String : String] {
            coverUrl = coverMiniInfo["Url"] ?? ""
        } else {
            coverUrl = json["AlbumInfoCoverUrl"] as? String ?? ""
        }
        let info = KaraokeMusicInfo(musicId: musicId, musicName: musicName, singers: singers, coverUrl: coverUrl)
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
        let coverUrl = json["albumInfoCoverUrl"] as? String ?? ""
        let info = KaraokeMusicInfo(musicId: musicId,
                                    musicName: musicName,
                                    singers: singers,
                                    coverUrl: coverUrl,
                                    userId: userId,
                                    performId: performId,
                                    status: status ?? .wait)
        return info
    }
    
    func addMusicToPlaylist(viewModel: TRTCKaraokeViewModel,
                            start: @escaping MusicStartCallback,
                            progress: @escaping MusicProgressCallback,
                            finish: @escaping MusicFinishCallback) {
        let finish: MusicFinishCallback = { musicInfo, errorCode, errorMessage in
            finish(musicInfo, errorCode, errorMessage)
            if errorCode == 0 {
                viewModel.showSelectedMusic(userId: musicInfo.userId, musicName: musicInfo.musicName)
                viewModel.sendSelectedMusic(musicInfo: musicInfo)
                if viewModel.currentMusicModel?.getMusicId() == musicInfo.getMusicId() {
                    viewModel.currentMusicModel = musicInfo
                    viewModel.effectViewModel.viewResponder?.updateMusicPanel(musicInfo: musicInfo)
                    viewModel.viewResponder?.updateChorusBtnStatus(musicId: musicInfo.getMusicId())
                    if viewModel.currentMusicModel?.userId == viewModel.loginUserId {
                        viewModel.effectViewModel.viewResponder?.onStartChorusBtnClick()
                    }
                }
            } else {
                viewModel.musicService?.deleteMusicFromPlaylist(musicInfo: musicInfo, callback: { code, message in
                    viewModel.notiMusicListChange()
                })
                viewModel.viewResponder?.showToast(message: localizeReplaceXX(.downloadFailedText, musicInfo.musicName))
            }
        }
        viewModel.musicService?.addMusicToPlaylist(musicInfo: self, callBack: KaraokeAddMusicCallback(start,progress,finish))
    }
}

public class KaraokeMusicTagModel: NSObject {
    public let tagName: String
    public let tagId: String
    
    public init(tagName: String, tagId: String) {
        self.tagName = tagName
        self.tagId = tagId
    }
    
    // 推荐，json->model
    public static func jsonTagModelInfo(_ json: [String: Any]) -> KaraokeMusicTagModel? {
        guard let tagName = json["Name"] as? String else { return nil }
        guard let tagId = json["TagId"] as? String else { return nil }
        let info = KaraokeMusicTagModel(tagName: tagName, tagId: tagId)
        return info
    }
}

fileprivate extension String {
    static var downloadFailedText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.xxxDownloadfailed")
    }
}

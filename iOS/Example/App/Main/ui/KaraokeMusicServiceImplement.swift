//
//  KaraokeMusicServiceImplement.swift
//  TRTCAPP_AppStore
//
//  Created by gg on 2021/7/9.
//

import TUIKaraoke
import ImSDK_Plus
import SwiftUI
import TUICore

public class KaraokeMusicServiceImplement: NSObject {
    
    public var roomInfo: KaraokeRoomInfo
    public weak var serviceObserver: KaraokeMusicServiceObserver?
    
    private var ownerID: String {
        return roomInfo.ownerId
    }
    
    public init(roomInfo: KaraokeRoomInfo) {
        self.roomInfo = roomInfo
        super.init()
        register()
    }
    
    deinit {
        debugPrint("___ music implement deinit")
    }
    
// MARK: - Test function
    
    private var getSelectedListCallback: MusicSelectedListCallback?
    
    private var ktvMusicSelectedList: [KaraokeMusicInfo] = []
    
    private lazy var ktvMusicList: [KaraokeMusicInfo] = {
        let model1 = KaraokeMusicInfo(musicId: "1001", musicName: "后来", singers: ["刘若英"], userId: "", performId: "1001", status: .wait)
        model1.lyricsUrl = karaokeBundle().path(forResource: "后来_歌词", ofType: "vtt") ?? ""
        model1.originUrl = karaokeBundle().path(forResource: "后来_原唱", ofType: "mp3") ?? ""
        model1.accompanyUrl = karaokeBundle().path(forResource: "后来_伴奏", ofType: "mp3") ?? ""
        
        
        let model2 = KaraokeMusicInfo(musicId: "1002", musicName: "情非得已", singers: ["庾澄庆"], userId: "", performId: "1002", status: .wait)
        model2.lyricsUrl = karaokeBundle().path(forResource: "情非得已_歌词", ofType: "vtt") ?? ""
        model2.originUrl = karaokeBundle().path(forResource: "情非得已_原唱", ofType: "mp3") ?? ""
        model2.accompanyUrl = karaokeBundle().path(forResource: "情非得已_伴奏", ofType: "mp3") ?? ""

        
        let model3 = KaraokeMusicInfo(musicId: "1003", musicName: "星晴", singers: ["周杰伦"], userId: "", performId: "1003", status: .wait)
        model3.lyricsUrl = karaokeBundle().path(forResource: "星晴_歌词", ofType: "vtt") ?? ""
        model3.originUrl = karaokeBundle().path(forResource: "星晴_原唱", ofType: "mp3") ?? ""
        model3.accompanyUrl = karaokeBundle().path(forResource: "星晴_伴奏", ofType: "mp3") ?? ""
  
        
        let model4 = KaraokeMusicInfo(musicId: "1004", musicName: "暖暖", singers: ["梁静茹"], userId: "", performId: "1004", status: .wait)
        model4.lyricsUrl = karaokeBundle().path(forResource: "暖暖_歌词", ofType: "vtt") ?? ""
        model4.originUrl = karaokeBundle().path(forResource: "暖暖_原唱", ofType: "mp3") ?? ""
        model4.accompanyUrl = karaokeBundle().path(forResource: "暖暖_伴奏", ofType: "mp3") ?? ""
        
        
        let model5 = KaraokeMusicInfo(musicId: "1005", musicName: "简单爱", singers: ["周杰伦"], userId: "", performId: "1005", status: .wait)
        model5.lyricsUrl = karaokeBundle().path(forResource: "简单爱_歌词", ofType: "vtt") ?? ""
        model5.originUrl = karaokeBundle().path(forResource: "简单爱_原唱", ofType: "mp3") ?? ""
        model5.accompanyUrl = karaokeBundle().path(forResource: "简单爱_伴奏", ofType: "mp3") ?? ""

        var ktvMusicList: [KaraokeMusicInfo] = []
        ktvMusicList.append(model1)
        ktvMusicList.append(model2)
        ktvMusicList.append(model3)
        ktvMusicList.append(model4)
        ktvMusicList.append(model5)
        return ktvMusicList
    }()

    
    private let mlock: NSLock = NSLock()
    
    private func lockSelectedList() {
        mlock.lock()
    }
    
    private func unlockSelectedList() {
        mlock.unlock()
    }
}

extension KaraokeMusicServiceImplement {
    // 发送已点歌曲列表发送变化通知
    func sendSelectedMusicListChange() {
        var selectedList: [KaraokeMusicInfo] = []
        lockSelectedList()
        selectedList = ktvMusicSelectedList
        unlockSelectedList()
        var list: [[String:String]] = []
        for model in selectedList {
            list.append(["musicId": model.musicId])
        }
        guard let data = try? JSONSerialization.data(withJSONObject: list, options: .prettyPrinted) else { return }
        guard let message = String(data: data, encoding: .utf8) else { return }
        sendNoti(instruction: gKaraoke_VALUE_CMD_INSTRUCTION_MLISTCHANGE, content: message)
    }
}

extension KaraokeMusicServiceImplement: V2TIMSimpleMsgListener {
    func register() {
        V2TIMManager.sharedInstance()?.addSimpleMsgListener(listener: self)
    }
    
    func unregister() {
        V2TIMManager.sharedInstance()?.removeSimpleMsgListener(listener: self)
    }
    
    private func getSignallingHeader() -> [String : Any] {
        return [
            gKaraoke_KEY_CMD_VERSION : gKaraoke_VALUE_CMD_VERSION,
            gKaraoke_KEY_CMD_BUSINESSID : gKaraoke_VALUE_CMD_BUSINESSID,
            gKaraoke_KEY_CMD_PLATFORM : gKaraoke_VALUE_CMD_PLATFORM,
        ]
    }
    
    private func makeInviteSignalling(instruction: String, musicID: String) -> [String : Any] {
        var header = getSignallingHeader()
        let data: [String : Any] = [
            gKaraoke_KEY_CMD_ROOMID : roomInfo.roomId,
            gKaraoke_KEY_CMD_INSTRUCTION : instruction,
            gKaraoke_KEY_CMD_CONTENT : musicID,
        ]
        header[gKaraoke_KEY_CMD_DATA] = data
        return header
    }
    
    private func makeSignalling(instruction: String, content: String) -> [String : Any] {
        var header = getSignallingHeader()
        let data: [String : Any] = [
            gKaraoke_KEY_CMD_ROOMID : roomInfo.roomId,
            gKaraoke_KEY_CMD_INSTRUCTION : instruction,
            gKaraoke_KEY_CMD_CONTENT : content,
        ]
        header[gKaraoke_KEY_CMD_DATA] = data
        return header
    }
    
    func sendNoti(instruction: String, content: String) {
        debugPrint("___ send noti: \(instruction)")
        let signal = makeSignalling(instruction: instruction, content: content)
        guard let data = try? JSONSerialization.data(withJSONObject: signal, options: .prettyPrinted) else { return }
        V2TIMManager.sharedInstance()?.sendGroupCustomMessage(data, to: roomInfo.roomId, priority: .PRIORITY_HIGH, succ: {
            
        }, fail: { (code, msg) in
            
        })
    }
    
    /// recv noti message
    public func onRecvGroupCustomMessage(_ msgID: String?, groupID: String?, sender info: V2TIMGroupMemberInfo?, customData data: Data) {
        debugPrint("___ recv noti")
        guard let dic = validateSignallingHeader(data: data) else {
            debugPrint("___ signalling validate failed")
            return
        }
        guard let instruction = dic[gKaraoke_KEY_CMD_INSTRUCTION] as? String else {
            debugPrint("___ not contains instruction key")
            return
        }
        debugPrint("___ recv noti: \(instruction)")
        guard let content = dic[gKaraoke_KEY_CMD_CONTENT] as? String else {
            debugPrint("___ content error")
            return
        }
        switch instruction {
      
        case gKaraoke_VALUE_CMD_INSTRUCTION_MLISTCHANGE:
            guard let data = content.data(using: .utf8) else { return }
            guard let list = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [ [String:Any] ] else {
                return
            }
            var selectedList: [KaraokeMusicInfo] = []
            for json in list {
                guard let musicID = json["musicId"] as? String else { break }
                for info in ktvMusicList where info.getMusicId() == musicID {
                    selectedList.append(info)
                }
            }
            lockSelectedList()
            ktvMusicSelectedList = selectedList
            unlockSelectedList()
            serviceObserver?.onMusicListChanged(musicInfoList: selectedList)
        default:
            break
        }
        
    }
    
    func validateSignallingHeader(data: Data) -> [String:Any]? {
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any] else { return nil }
        if obj.keys.contains(gKaraoke_KEY_CMD_VERSION) {
            guard let version = obj[gKaraoke_KEY_CMD_VERSION] as? Int else {
                return nil
            }
            if version < gKaraoke_VALUE_CMD_BASIC_VERSION {
                return nil
            }
        }
        if obj.keys.contains(gKaraoke_KEY_CMD_BUSINESSID) {
            guard let businessID = obj[gKaraoke_KEY_CMD_BUSINESSID] as? String, businessID == gKaraoke_VALUE_CMD_BUSINESSID else {
                return nil
            }
        }
        if obj.keys.contains(gKaraoke_KEY_CMD_DATA) {
            guard let data = obj[gKaraoke_KEY_CMD_DATA] as? [String : Any] else {
                return [:]
            }
            return data
        }
        return [:]
    }
}

extension KaraokeMusicServiceImplement: KaraokeMusicService {
    public func prepareMusicScore(musicInfo: TUIKaraoke.KaraokeMusicInfo) {
        
    }
    
    public func processMusicScore(buffer: UnsafeMutablePointer<CChar>, length: Int32, timeStamp: Double) {
        
    }
    
    public func finishMusicScore() {
        
    }
    
    public func addObserver(_ observer: TUIKaraoke.KaraokeMusicServiceObserver) {
        serviceObserver = observer
    }
    
    public func destroyService() {
        unregister()
    }
    
    public func getMusicTagList(callback: @escaping TUIKaraoke.MusicTagListCallback) {
        callback(0,"",[KaraokeMusicTagModel(tagName: "本地歌曲", tagId: "-10005")])
    }
    
    public func getMusicsByTagId(tagId: String, scrollToken: String, callback: @escaping TUIKaraoke.MusicListCallback) {
        if scrollToken == "-10005" {
            callback(0,"",[],"-10005")
        } else {
            callback(0,"",ktvMusicList,"-10005")
        }
    }
    
    public func getMusicsByKeywords(keyWord: String, limit: Int, scrollToken: String, callback: @escaping TUIKaraoke.MusicListCallback) {
        callback(0,"",[], "")
    }
    
    public func getPlaylist(_ callback: @escaping TUIKaraoke.MusicSelectedListCallback) {
        callback(0,"",ktvMusicSelectedList)
    }
    
    public func addMusicToPlaylist(musicInfo: TUIKaraoke.KaraokeMusicInfo, callBack: TUIKaraoke.KaraokeAddMusicCallback) {
        var musicInfoTemp: KaraokeMusicInfo?
        for tmpInfo in ktvMusicList where tmpInfo.musicId == musicInfo.musicId {
            musicInfoTemp = tmpInfo
        }
        guard let info = musicInfoTemp else { return }
        info.userId = TUILogin.getUserID() ?? ""
        lockSelectedList()
        ktvMusicSelectedList.append(info)
        unlockSelectedList()
        sendSelectedMusicListChange()
        callBack.start(info)
        callBack.progress(info,1.0)
        serviceObserver?.onMusicListChanged(musicInfoList: ktvMusicSelectedList)
        callBack.finish(info,0, "")
    }
    
    public func deleteMusicFromPlaylist(musicInfo: TUIKaraoke.KaraokeMusicInfo, callback: @escaping KaraokeCallback) {
        lockSelectedList()
        let list = ktvMusicSelectedList
        unlockSelectedList()
        for (i, model) in list.enumerated() where model.musicId == musicInfo.musicId {
            lockSelectedList()
            ktvMusicSelectedList.remove(at: i)
            unlockSelectedList()
            sendSelectedMusicListChange()
        }
        callback(0,"")
    }
    
    public func clearPlaylistByUserId(userID: String, callback: @escaping KaraokeCallback) {
        lockSelectedList()
        var index = IndexSet()
        for (i, music) in ktvMusicSelectedList.enumerated() where music.userId == ownerID {
            music.userId = ""
            index.insert(i)
        }
        ktvMusicSelectedList.remove(atOffsets: index)
        unlockSelectedList()
        sendSelectedMusicListChange()
        serviceObserver?.onMusicListChanged(musicInfoList: ktvMusicSelectedList)
        callback(0,"")
    }
    
    public func switchMusicFromPlaylist(musicInfo: TUIKaraoke.KaraokeMusicInfo, callback: @escaping KaraokeCallback) {
        deleteMusicFromPlaylist(musicInfo: musicInfo) { [weak self] errorCode, message in
            guard let self = self else { return }
            self.serviceObserver?.onMusicListChanged(musicInfoList: self.ktvMusicSelectedList)
            callback(errorCode, message)
        }
    }
    
    public func completePlaying(musicInfo: TUIKaraoke.KaraokeMusicInfo, callback: @escaping KaraokeCallback) {
        deleteMusicFromPlaylist(musicInfo: musicInfo) { [weak self] errorCode, message in
            guard let self = self else { return }
            self.serviceObserver?.onMusicListChanged(musicInfoList: self.ktvMusicSelectedList)
            callback(errorCode, message)
        }
    }
    
    public func topMusic(musicInfo: TUIKaraoke.KaraokeMusicInfo, callback: @escaping KaraokeCallback) {
        lockSelectedList()
        let list = ktvMusicSelectedList
        unlockSelectedList()
        guard list.count > 2 else { return }
        for (i, model) in list.enumerated() where model.musicId == musicInfo.musicId {
            lockSelectedList()
            let toped = ktvMusicSelectedList.remove(at: i)
            ktvMusicSelectedList.insert(toped, at: 1)
            unlockSelectedList()
            sendSelectedMusicListChange()
        }
        serviceObserver?.onMusicListChanged(musicInfoList: ktvMusicSelectedList)
        callback(0,"")
    }
}

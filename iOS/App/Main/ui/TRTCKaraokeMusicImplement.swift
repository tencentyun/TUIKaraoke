//
//  TRTCKaraokeMusicImplement.swift
//  TRTCAPP_AppStore
//
//  Created by gg on 2021/7/9.
//

import TUIKaraoke
import ImSDK_Plus

public class KaraokeMusicImplement: NSObject {
    
    public var roomInfo: RoomInfo = RoomInfo()
    public var serviceDelegate: KaraokeMusicServiceDelegate?
    
    private var ownerID: String {
        return roomInfo.ownerId
    }
    
    private var isOwner: Bool {
        return roomInfo.ownerId == TRTCKaraokeIMManager.shared.curUserID
    }
    
    public override init() {
        super.init()
        register()
    }
    
    deinit {
        debugPrint("___ music implement deinit")
    }
    
// MARK: - Test function
    
    private var getSelectedListCallback: MusicSelectedListCallback?
    
    private var ktvMusicSelectedList: [KaraokeMusicModel] = []
    
    private var currentLrc: String? = nil
    
    private var ktvMusicList: [KaraokeMusicInfo] = []
    private func loadKaraokeMusicList() {
        let t1 = KaraokeBundle().path(forResource: "后来_伴奏", ofType: "mp3") ?? ""
        let l1 = KaraokeBundle().path(forResource: "后来_歌词", ofType: "vtt") ?? ""
        let model1 = KaraokeMusicInfo(title: "后来_伴奏", coverUrl: "", author: "刘若英", path: t1, lrcPath: l1, musicID: 1001)
        
        let t2 = KaraokeBundle().path(forResource: "后来_原唱", ofType: "mp3") ?? ""
        let l2 = KaraokeBundle().path(forResource: "后来_歌词", ofType: "vtt") ?? ""
        let model2 = KaraokeMusicInfo(title: "后来_原唱", coverUrl: "", author: "刘若英", path: t2, lrcPath: l2, musicID: 1002)
        
        let t3 = KaraokeBundle().path(forResource: "情非得已_伴奏", ofType: "mp3") ?? ""
        let l3 = KaraokeBundle().path(forResource: "情非得已_歌词", ofType: "vtt") ?? ""
        let model3 = KaraokeMusicInfo(title: "情非得已_伴奏", coverUrl: "", author: "庾澄庆", path: t3, lrcPath: l3, musicID: 1003)
        
        let t4 = KaraokeBundle().path(forResource: "情非得已_原唱", ofType: "mp3") ?? ""
        let l4 = KaraokeBundle().path(forResource: "情非得已_歌词", ofType: "vtt") ?? ""
        let model4 = KaraokeMusicInfo(title: "情非得已_原唱", coverUrl: "", author: "庾澄庆", path: t4, lrcPath: l4, musicID: 1004)
        
        let t5 = KaraokeBundle().path(forResource: "星晴_伴奏", ofType: "mp3") ?? ""
        let l5 = KaraokeBundle().path(forResource: "星晴_歌词", ofType: "vtt") ?? ""
        let model5 = KaraokeMusicInfo(title: "星晴_伴奏", coverUrl: "", author: "周杰伦", path: t5, lrcPath: l5, musicID: 1005)
        
        let t6 = KaraokeBundle().path(forResource: "星晴_原唱", ofType: "mp3") ?? ""
        let l6 = KaraokeBundle().path(forResource: "星晴_歌词", ofType: "vtt") ?? ""
        let model6 = KaraokeMusicInfo(title: "星晴_原唱", coverUrl: "", author: "周杰伦", path: t6, lrcPath: l6, musicID: 1006)
        
        let t7 = KaraokeBundle().path(forResource: "暖暖_伴奏", ofType: "mp3") ?? ""
        let l7 = KaraokeBundle().path(forResource: "暖暖_歌词", ofType: "vtt") ?? ""
        let model7 = KaraokeMusicInfo(title: "暖暖_伴奏", coverUrl: "", author: "梁静茹", path: t7, lrcPath: l7, musicID: 1007)
        
        let t8 = KaraokeBundle().path(forResource: "暖暖_原唱", ofType: "mp3") ?? ""
        let l8 = KaraokeBundle().path(forResource: "暖暖_歌词", ofType: "vtt") ?? ""
        let model8 = KaraokeMusicInfo(title: "暖暖_原唱", coverUrl: "", author: "梁静茹", path: t8, lrcPath: l8, musicID: 1008)
        
        let t9 = KaraokeBundle().path(forResource: "简单爱_伴奏", ofType: "mp3") ?? ""
        let l9 = KaraokeBundle().path(forResource: "简单爱_歌词", ofType: "vtt") ?? ""
        let model9 = KaraokeMusicInfo(title: "简单爱_伴奏", coverUrl: "", author: "周杰伦", path: t9, lrcPath: l9, musicID: 1009)
        
        let t10 = KaraokeBundle().path(forResource: "简单爱_原唱", ofType: "mp3") ?? ""
        let l10 = KaraokeBundle().path(forResource: "简单爱_歌词", ofType: "vtt") ?? ""
        let model10 = KaraokeMusicInfo(title: "简单爱_原唱", coverUrl: "", author: "周杰伦", path: t10, lrcPath: l10, musicID: 1010)
        
        ktvMusicList.removeAll()
        
        ktvMusicList.append(model1)
        ktvMusicList.append(model2)
        ktvMusicList.append(model3)
        ktvMusicList.append(model4)
        ktvMusicList.append(model5)
        ktvMusicList.append(model6)
        ktvMusicList.append(model7)
        ktvMusicList.append(model8)
        ktvMusicList.append(model9)
        ktvMusicList.append(model10)
    }
    
    private let mlock: NSLock = NSLock()
    
    private func lockSelectedList() {
        mlock.lock()
    }
    
    private func unlockSelectedList() {
        mlock.unlock()
    }
}

extension KaraokeMusicImplement {
    
    // 准备播放，发通知，收到通知后应准备好歌词
    func notiPrepare(musicID: String) {
        sendNoti(instruction: Karaoke_VALUE_CMD_INSTRUCTION_MPREPARE, content: musicID)
    }
    
    // 播放完成时，应给房主发送complete消息
    func notiComplete(musicID: String) {
        serviceDelegate?.onShouldSetLyric(musicID: "0")
        sendNoti(instruction: Karaoke_VALUE_CMD_INSTRUCTION_MCOMPLETE, content: musicID)
    }
    
    // 给某人发送应该播放音乐了（下一个是你）
    func sendShouldPlay(userID: String, musicID: String) {
        sendInstruction(Karaoke_VALUE_CMD_INSTRUCTION_MPLAYMUSIC, userID: userID, musicID: musicID)
    }
    
    // 给某人发送应该停止了（被切歌了）
    func sendShouldStop(userID: String, musicID: String) {
        sendInstruction(Karaoke_VALUE_CMD_INSTRUCTION_MSTOP, userID: userID, musicID: musicID)
    }
    
    // 发送请求已点列表
    func sendRequestSelectedList() {
        sendInstruction(Karaoke_VALUE_CMD_INSTRUCTION_MGETLIST, userID: ownerID, musicID: "")
    }
    
    func sendDeleteAll() {
        sendInstruction(Karaoke_VALUE_CMD_INSTRUCTION_MDELETEALL, userID: ownerID, musicID: "")
    }
    
    // 广播通知列表发生变化
    func notiListChange() {
        var selectedList: [KaraokeMusicModel] = []
        
        lockSelectedList()
        selectedList = ktvMusicSelectedList
        unlockSelectedList()
        var list: [ [String:Any] ] = []
        for model in selectedList {
            list.append(model.jsonDic)
        }
        serviceDelegate?.onMusicListChange(musicInfoList: selectedList, reason: 0)
        
        guard let data = try? JSONSerialization.data(withJSONObject: list, options: .prettyPrinted) else { return }
        guard let message = String(data: data, encoding: .utf8) else { return }
        sendNoti(instruction: Karaoke_VALUE_CMD_INSTRUCTION_MLISTCHANGE, content: message)
    }
}

extension KaraokeMusicImplement: V2TIMSimpleMsgListener {
    func register() {
        V2TIMManager.sharedInstance()?.addSimpleMsgListener(listener: self)
    }
    
    func unregister() {
        V2TIMManager.sharedInstance()?.removeSimpleMsgListener(listener: self)
    }
    
    private func getSignallingHeader() -> [String : Any] {
        return [
            Karaoke_KEY_CMD_VERSION : Karaoke_VALUE_CMD_VERSION,
            Karaoke_KEY_CMD_BUSINESSID : Karaoke_VALUE_CMD_BUSINESSID,
            Karaoke_KEY_CMD_PLATFORM : Karaoke_VALUE_CMD_PLATFORM,
        ]
    }
    
    private func makeInviteSignalling(instruction: String, musicID: String) -> [String : Any] {
        var header = getSignallingHeader()
        let data: [String : Any] = [
            Karaoke_KEY_CMD_ROOMID : roomInfo.roomID,
            Karaoke_KEY_CMD_INSTRUCTION : instruction,
            Karaoke_KEY_CMD_CONTENT : musicID
        ]
        header[Karaoke_KEY_CMD_DATA] = data
        return header
    }
    
    private func makeSignalling(instruction: String, content: String) -> [String : Any] {
        var header = getSignallingHeader()
        let data: [String : Any] = [
            Karaoke_KEY_CMD_ROOMID : roomInfo.roomID,
            Karaoke_KEY_CMD_INSTRUCTION : instruction,
            Karaoke_KEY_CMD_CONTENT : content
        ]
        header[Karaoke_KEY_CMD_DATA] = data
        return header
    }
    
    func sendInstruction(_ instruction: String, userID: String, musicID: String) {
        debugPrint("___ send instruction: \(instruction)")
        let signal = makeInviteSignalling(instruction: instruction, musicID: musicID)
        guard let data = try? JSONSerialization.data(withJSONObject: signal, options: .prettyPrinted) else { return }
        V2TIMManager.sharedInstance()?.sendC2CCustomMessage(data, to: userID, succ: {
            
        }, fail: { (code, msg) in
            
        })
    }
    
    func sendNoti(instruction: String, content: String) {
        debugPrint("___ send noti: \(instruction)")
        let signal = makeSignalling(instruction: instruction, content: content)
        guard let data = try? JSONSerialization.data(withJSONObject: signal, options: .prettyPrinted) else { return }
        V2TIMManager.sharedInstance()?.sendGroupCustomMessage(data, to: String(roomInfo.roomID), priority: .PRIORITY_HIGH, succ: {
            
        }, fail: { (code, msg) in
            
        })
    }
    
    /// recv instruction
    public func onRecvC2CCustomMessage(_ msgID: String!, sender info: V2TIMUserInfo!, customData data: Data!) {
        debugPrint("___ recv instruction")
        guard let dic = validateSignallingHeader(data: data) else {
            debugPrint("___ signalling validate failed")
            return
        }
        guard let instruction = dic[Karaoke_KEY_CMD_INSTRUCTION] as? String else {
            debugPrint("___ not contains instruction key")
            return
        }
        debugPrint("___ recv instruction: \(instruction)")
        guard let musicID = dic[Karaoke_KEY_CMD_CONTENT] as? String else {
            debugPrint("___ music_id error")
            return
        }
        switch instruction {
        case Karaoke_VALUE_CMD_INSTRUCTION_MPICK:
            guard isOwner else { return }
            var music: KaraokeMusicModel?
            for m in ktvMusicList {
                if m.musicID == Int32(musicID) {
                    let model = KaraokeMusicModel(sourceModel: m)
                    music = model
                    break
                }
            }
            if let music = music {
                lockSelectedList()
                let list = ktvMusicSelectedList
                unlockSelectedList()
                debugPrint("___ current list count: \(list.count)")
                let shouldPlay = list.count == 0
                var haved = false
                for selectedMusic in list {
                    if selectedMusic.musicID == music.musicID {
                        haved = true
                        break
                    }
                }
                if !haved {
                    music.bookUserID = info.userID
                    music.bookUserName = info.nickName
                    music.isSelected = true
                    
                    lockSelectedList()
                    ktvMusicSelectedList.append(music)
                    unlockSelectedList()
                }
                notiListChange()
                serviceDelegate?.onShouldShowMessage(music)
                if shouldPlay {
                    sendShouldPlay(userID: music.bookUserID, musicID: String(music.musicID))
                }
            }
            else {
                debugPrint("___ not found music")
            }
        case Karaoke_VALUE_CMD_INSTRUCTION_MPLAYMUSIC:
            var model: KaraokeMusicModel?
            lockSelectedList()
            let list = ktvMusicSelectedList
            unlockSelectedList()
            for music in list {
                if music.musicID == Int32(musicID) {
                    model = music
                    break
                }
            }
            if model == nil {
                for music in ktvMusicList {
                    if music.musicID == Int32(musicID) {
                        model = KaraokeMusicModel(sourceModel: music)
                        break
                    }
                }
            }
            if let playModel = model {
                debugPrint("___ start play \(playModel.musicName)")
                serviceDelegate?.onShouldPlay(playModel)
            }
            else {
                debugPrint("___ not found music")
            }
        case Karaoke_VALUE_CMD_INSTRUCTION_MGETLIST:
            guard isOwner else { return }
            lockSelectedList()
            let list = ktvMusicSelectedList
            unlockSelectedList()
            if let action = getSelectedListCallback {
                action(list)
            }
            else {
                notiListChange()
            }
            if let first = list.first {
                notiPrepare(musicID: String(first.musicID))
            }
        case Karaoke_VALUE_CMD_INSTRUCTION_MSTOP:
            var model: KaraokeMusicModel?
            lockSelectedList()
            for selected in ktvMusicSelectedList {
                if selected.musicID == Int32(musicID) {
                    model = selected
                    break
                }
            }
            unlockSelectedList()
            guard let music = model else { return }
            serviceDelegate?.onShouldStopPlay(music)
        case Karaoke_VALUE_CMD_INSTRUCTION_MDELETE:
            lockSelectedList()
            let list = ktvMusicSelectedList
            unlockSelectedList()
            for (i, model) in list.enumerated() {
                if model.musicID == Int32(musicID) {
                    lockSelectedList()
                    ktvMusicSelectedList.remove(at: i)
                    unlockSelectedList()
                    notiListChange()
                    break
                }
            }
        case Karaoke_VALUE_CMD_INSTRUCTION_MDELETEALL:
            guard isOwner else { return }
            var index = IndexSet()
            lockSelectedList()
            for (i, music) in ktvMusicSelectedList.enumerated() {
                if music.bookUserID == info.userID {
                    music.reset()
                    index.insert(i)
                }
            }
            ktvMusicSelectedList.remove(atOffsets: index)
            unlockSelectedList()
            notiListChange()
        default:
            break
        }
    }
    
    /// recv noti message
    public func onRecvGroupCustomMessage(_ msgID: String!, groupID: String!, sender info: V2TIMGroupMemberInfo!, customData data: Data!) {
        debugPrint("___ recv noti")
        guard let dic = validateSignallingHeader(data: data) else {
            debugPrint("___ signalling validate failed")
            return
        }
        guard let instruction = dic[Karaoke_KEY_CMD_INSTRUCTION] as? String else {
            debugPrint("___ not contains instruction key")
            return
        }
        debugPrint("___ recv noti: \(instruction)")
        guard let content = dic[Karaoke_KEY_CMD_CONTENT] as? String else {
            debugPrint("___ content error")
            return
        }
        switch instruction {
        case Karaoke_VALUE_CMD_INSTRUCTION_MPREPARE:
            debugPrint("___ recv prepare content: \(content)")
            serviceDelegate?.onShouldSetLyric(musicID: content)
            currentLrc = content
        case Karaoke_VALUE_CMD_INSTRUCTION_MLISTCHANGE:
            guard let data = content.data(using: .utf8) else { return }
            guard let list = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [ [String:Any] ] else {
                return
            }
            var selectedList: [KaraokeMusicModel] = []
            for json in list {
                if let model = KaraokeMusicModel.json(json) {
                    for info in ktvMusicList {
                        if model.musicID == info.musicID {
                            model.music.contentUrl = info.contentUrl
                            model.music.lrcUrl = info.lrcUrl
                            break
                        }
                    }
                    selectedList.append(model)
                }
            }
            lockSelectedList()
            ktvMusicSelectedList = selectedList
            unlockSelectedList()
            serviceDelegate?.onMusicListChange(musicInfoList: selectedList, reason: 0)
        case Karaoke_VALUE_CMD_INSTRUCTION_MCOMPLETE:
            debugPrint("___ recv complete content: \(content)")
            if let current = currentLrc {
                if current == content {
                    serviceDelegate?.onShouldSetLyric(musicID: "0")
                }
            }
            else {
                serviceDelegate?.onShouldSetLyric(musicID: "0")
            }
            if isOwner {
                lockSelectedList()
                let list = ktvMusicSelectedList
                unlockSelectedList()
                for (i, music) in list.enumerated() {
                    if music.musicID == Int32(content) {
                        lockSelectedList()
                        let current = ktvMusicSelectedList.remove(at: i)
                        current.reset()
                        unlockSelectedList()
                        notiListChange()
                        break
                    }
                }
                lockSelectedList()
                let newList = ktvMusicSelectedList
                unlockSelectedList()
                if let next = newList.first {
                    if next.bookUserID == ownerID {
                        serviceDelegate?.onShouldPlay(next)
                    }
                    else {
                        sendShouldPlay(userID: next.bookUserID, musicID: String(next.musicID))
                    }
                }
            }
        default:
            break
        }
        
    }
    
    func validateSignallingHeader(data: Data) -> [String:Any]? {
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any] else { return nil }
        if obj.keys.contains(Karaoke_KEY_CMD_VERSION) {
            guard let version = obj[Karaoke_KEY_CMD_VERSION] as? Int else {
                return nil
            }
            if version < Karaoke_VALUE_CMD_BASIC_VERSION {
                return nil
            }
        }
        if obj.keys.contains(Karaoke_KEY_CMD_BUSINESSID) {
            guard let businessID = obj[Karaoke_KEY_CMD_BUSINESSID] as? String, businessID == Karaoke_VALUE_CMD_BUSINESSID else {
                return nil
            }
        }
        if obj.keys.contains(Karaoke_KEY_CMD_DATA) {
            guard let data = obj[Karaoke_KEY_CMD_DATA] as? [String : Any] else {
                return [:]
            }
            return data
        }
        return [:]
    }
}

extension KaraokeMusicImplement: KaraokeMusicService {
    
    public func ktvGetMusicPage(page: Int, pageSize: Int, callback: @escaping MusicListCallback) {
        loadKaraokeMusicList()
        callback(ktvMusicList)
    }
    
    public func ktvGetSelectedMusicList(_ callback: @escaping ([KaraokeMusicModel]) -> ()) {
        if isOwner {
            lockSelectedList()
            let list = ktvMusicSelectedList
            unlockSelectedList()
            callback(list)
            if let first = list.first {
                serviceDelegate?.onShouldSetLyric(musicID: String(first.musicID))
            }
        }
        else {
            getSelectedListCallback = callback
            sendRequestSelectedList()
        }
    }
    
    public func pickMusic(musicID: String, callback: (Int32, String) -> Void) {
        if isOwner {
            var minfo: KaraokeMusicInfo?
            for tmpInfo in ktvMusicList {
                if tmpInfo.musicID == Int32(musicID) {
                    minfo = tmpInfo
                    break
                }
            }
            guard let info = minfo else {
                return
            }
            let music = KaraokeMusicModel(sourceModel: info, isSelected: true)
            music.bookUserName = TRTCKaraokeIMManager.shared.curUserName
            music.bookUserID = TRTCKaraokeIMManager.shared.curUserID
            music.seatIndex = TRTCKaraokeIMManager.shared.seatIndex
            lockSelectedList()
            let shouldPlay = ktvMusicSelectedList.count == 0
            ktvMusicSelectedList.append(music)
            unlockSelectedList()
            notiListChange()
            serviceDelegate?.onShouldShowMessage(music)
            if shouldPlay {
                serviceDelegate?.onShouldPlay(music)
            }
        }
        else {
            sendInstruction(Karaoke_VALUE_CMD_INSTRUCTION_MPICK, userID: ownerID, musicID: musicID)
        }
    }
    
    public func deleteMusic(musicID: String, callback: (Int32, String) -> Void) {
        if isOwner {
            lockSelectedList()
            let list = ktvMusicSelectedList
            unlockSelectedList()
            for (i, model) in list.enumerated() {
                if model.musicID == Int32(musicID) {
                    lockSelectedList()
                    ktvMusicSelectedList.remove(at: i)
                    unlockSelectedList()
                    notiListChange()
                    break
                }
            }
        }
        else {
            sendInstruction(Karaoke_VALUE_CMD_INSTRUCTION_MDELETE, userID: ownerID, musicID: musicID)
        }
    }
    
    public func topMusic(musicID: String, callback: (Int32, String) -> Void) {
        guard isOwner else { return }
        lockSelectedList()
        let list = ktvMusicSelectedList
        unlockSelectedList()
        guard list.count > 2 else { return }
        for (i, model) in list.enumerated() {
            if model.musicID == Int32(musicID) {
                lockSelectedList()
                let toped = ktvMusicSelectedList.remove(at: i)
                ktvMusicSelectedList.insert(toped, at: 1)
                unlockSelectedList()
                notiListChange()
                break
            }
        }
    }
    
    public func nextMusic(callback: (Int32, String) -> Void) {
        guard isOwner else { return }
        lockSelectedList()
        let list = ktvMusicSelectedList
        unlockSelectedList()
        guard list.count > 0 else { return }
        guard let current = list.first else { return }
        if current.bookUserID == ownerID {
            serviceDelegate?.onShouldStopPlay(current)
        }
        else {
            sendShouldStop(userID: current.bookUserID, musicID: String(current.musicID))
        }
    }
    
    public func deleteAllMusic(userID: String, callback: @escaping ActionCallback) {
        if isOwner {
            lockSelectedList()
            var index = IndexSet()
            for (i, music) in ktvMusicSelectedList.enumerated() {
                if music.bookUserID == ownerID {
                    music.reset()
                    index.insert(i)
                }
            }
            ktvMusicSelectedList.remove(atOffsets: index)
            unlockSelectedList()
            notiListChange()
        }
        else {
            sendDeleteAll()
        }
    }
    
    public func prepareToPlay(musicID: String) {
        notiPrepare(musicID: musicID)
    }
    
    public func completePlaying(musicID: String) {
        if isOwner {
            lockSelectedList()
            let list = ktvMusicSelectedList
            unlockSelectedList()
            guard let first = list.first else {
                serviceDelegate?.onShouldSetLyric(musicID: "0")
                notiPrepare(musicID: "0")
                return
            }
            if first.musicID == Int32(musicID) {
                lockSelectedList()
                let first = ktvMusicSelectedList.removeFirst()
                first.reset()
                unlockSelectedList()
                notiComplete(musicID: musicID)
                notiListChange()
            }
            lockSelectedList()
            let newList = ktvMusicSelectedList
            unlockSelectedList()
            if let next = newList.first {
                if next.bookUserID == ownerID {
                    serviceDelegate?.onShouldPlay(next)
                }
                else {
                    sendShouldPlay(userID: next.bookUserID, musicID: String(next.musicID))
                }
            }
        }
        else {
            notiComplete(musicID: musicID)
        }
    }
    
    public func downloadMusic(musicID: String, progress: (Double) -> (), complete: (Int32, String) -> Void) {
        
    }
    
    public func downloadLRC(musicID: String, callback: (Int32, String) -> Void) {
        
    }
    
    public func setRoomInfo(roomInfo: RoomInfo) {
        self.roomInfo = roomInfo
    }
    
    public func setServiceDelegate(_ delegate: KaraokeMusicServiceDelegate) {
        self.serviceDelegate = delegate
    }
    
    public func onExitRoom() {
        unregister()
    }
}

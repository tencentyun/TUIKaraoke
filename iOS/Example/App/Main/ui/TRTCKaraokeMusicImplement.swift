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
    

    private lazy var ktvMusicList: [KaraokeMusicInfo] = {
        let model1 = KaraokeMusicInfo(musicId: "1001", musicName: "后来", singers: ["刘若英"], userId: "", performId: "1001", status: .wait)
        model1.lrcLocalPath = karaokeBundle().path(forResource: "后来_歌词", ofType: "vtt") ?? ""
        model1.muscicLocalPath = karaokeBundle().path(forResource: "后来_原唱", ofType: "mp3") ?? ""
        model1.accompanyLocalPath = karaokeBundle().path(forResource: "后来_伴奏", ofType: "mp3") ?? ""
        
        
        let model2 = KaraokeMusicInfo(musicId: "1002", musicName: "情非得已", singers: ["庾澄庆"], userId: "", performId: "1002", status: .wait)
        model2.lrcLocalPath = karaokeBundle().path(forResource: "情非得已_歌词", ofType: "vtt") ?? ""
        model2.muscicLocalPath = karaokeBundle().path(forResource: "情非得已_原唱", ofType: "mp3") ?? ""
        model2.accompanyLocalPath = karaokeBundle().path(forResource: "情非得已_伴奏", ofType: "mp3") ?? ""

        
        let model3 = KaraokeMusicInfo(musicId: "1003", musicName: "星晴", singers: ["周杰伦"], userId: "", performId: "1003", status: .wait)
        model3.lrcLocalPath = karaokeBundle().path(forResource: "星晴_歌词", ofType: "vtt") ?? ""
        model3.muscicLocalPath = karaokeBundle().path(forResource: "星晴_原唱", ofType: "mp3") ?? ""
        model3.accompanyLocalPath = karaokeBundle().path(forResource: "星晴_伴奏", ofType: "mp3") ?? ""
  
        
        let model4 = KaraokeMusicInfo(musicId: "1004", musicName: "暖暖", singers: ["梁静茹"], userId: "", performId: "1004", status: .wait)
        model4.lrcLocalPath = karaokeBundle().path(forResource: "暖暖_歌词", ofType: "vtt") ?? ""
        model4.muscicLocalPath = karaokeBundle().path(forResource: "暖暖_原唱", ofType: "mp3") ?? ""
        model4.accompanyLocalPath = karaokeBundle().path(forResource: "暖暖_伴奏", ofType: "mp3") ?? ""
        
        
        let model5 = KaraokeMusicInfo(musicId: "1005", musicName: "简单爱", singers: ["梁静茹"], userId: "", performId: "1005", status: .wait)
        model5.lrcLocalPath = karaokeBundle().path(forResource: "简单爱_歌词", ofType: "vtt") ?? ""
        model5.muscicLocalPath = karaokeBundle().path(forResource: "简单爱_原唱", ofType: "mp3") ?? ""
        model5.accompanyLocalPath = karaokeBundle().path(forResource: "简单爱_伴奏", ofType: "mp3") ?? ""

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

extension KaraokeMusicImplement {
    
    // 准备播放，发通知，收到通知后应准备好歌词
    func notiPrepare(musicID: String) {
        sendNoti(instruction: gKaraoke_VALUE_CMD_INSTRUCTION_MPREPARE, content: musicID)
    }
    
    // 播放完成时，应给房主发送complete消息
    func notiComplete(musicID: String) {
        serviceDelegate?.onShouldSetLyric(musicID: "0")
        sendNoti(instruction: gKaraoke_VALUE_CMD_INSTRUCTION_MCOMPLETE, content: musicID)
    }
    
    // 给某人发送应该播放音乐了（下一个是你）
    func sendShouldPlay(userID: String, musicID: String) {
        sendInstruction(gKaraoke_VALUE_CMD_INSTRUCTION_MPLAYMUSIC, userID: userID, musicID: musicID)
    }
    
    // 给某人发送应该停止了（被切歌了）
    func sendShouldStop(userID: String, musicID: String) {
        sendInstruction(gKaraoke_VALUE_CMD_INSTRUCTION_MSTOP, userID: userID, musicID: musicID)
    }
    
    // 发送请求已点列表
    func sendRequestSelectedList() {
        sendInstruction(gKaraoke_VALUE_CMD_INSTRUCTION_MGETLIST, userID: ownerID, musicID: "")
    }
    
    func sendDeleteAll() {
        sendInstruction(gKaraoke_VALUE_CMD_INSTRUCTION_MDELETEALL, userID: ownerID, musicID: "")
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
        sendNoti(instruction: gKaraoke_VALUE_CMD_INSTRUCTION_MLISTCHANGE, content: message)
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
            gKaraoke_KEY_CMD_VERSION : gKaraoke_VALUE_CMD_VERSION,
            gKaraoke_KEY_CMD_BUSINESSID : gKaraoke_VALUE_CMD_BUSINESSID,
            gKaraoke_KEY_CMD_PLATFORM : gKaraoke_VALUE_CMD_PLATFORM,
        ]
    }
    
    private func makeInviteSignalling(instruction: String, musicID: String) -> [String : Any] {
        var header = getSignallingHeader()
        let data: [String : Any] = [
            gKaraoke_KEY_CMD_ROOMID : roomInfo.roomID,
            gKaraoke_KEY_CMD_INSTRUCTION : instruction,
            gKaraoke_KEY_CMD_CONTENT : musicID,
        ]
        header[gKaraoke_KEY_CMD_DATA] = data
        return header
    }
    
    private func makeSignalling(instruction: String, content: String) -> [String : Any] {
        var header = getSignallingHeader()
        let data: [String : Any] = [
            gKaraoke_KEY_CMD_ROOMID : roomInfo.roomID,
            gKaraoke_KEY_CMD_INSTRUCTION : instruction,
            gKaraoke_KEY_CMD_CONTENT : content,
        ]
        header[gKaraoke_KEY_CMD_DATA] = data
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
        guard let instruction = dic[gKaraoke_KEY_CMD_INSTRUCTION] as? String else {
            debugPrint("___ not contains instruction key")
            return
        }
        debugPrint("___ recv instruction: \(instruction)")
        guard let musicID = dic[gKaraoke_KEY_CMD_CONTENT] as? String else {
            debugPrint("___ music_id error")
            return
        }
        switch instruction {
        case gKaraoke_VALUE_CMD_INSTRUCTION_MPICK:
            guard isOwner else { return }
            var music: KaraokeMusicModel?
            for m in ktvMusicList {
                if m.performId == musicID {
                    let model = KaraokeMusicModel(sourceModel: KaraokeMusicInfo.copyMusic(m))
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
                    music.userId = info.userID
                    music.bookUserName = info.nickName
                    music.isSelected = true
                    music.music.userId = info.userID;
                    lockSelectedList()
                    ktvMusicSelectedList.append(music)
                    unlockSelectedList()
                }
                notiListChange()
                serviceDelegate?.onShouldShowMessage(music)
                if shouldPlay {
                    sendShouldPlay(userID: music.userId, musicID: String(music.musicID))
                }
            }
            else {
                debugPrint("___ not found music")
            }
        case gKaraoke_VALUE_CMD_INSTRUCTION_MPLAYMUSIC:
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
                    if music.performId == musicID {
                        model = KaraokeMusicModel(sourceModel: music)
                        break
                    }
                }
            }
            if let playModel = model {
                debugPrint("___ start play \(playModel.musicName)")
                serviceDelegate?.onShouldPlay(playModel)
                serviceDelegate?.onShouldSetLyric(musicID: String(playModel.musicID))
            }
            else {
                debugPrint("___ not found music")
            }
        case gKaraoke_VALUE_CMD_INSTRUCTION_MGETLIST:
            guard isOwner else { return }
            lockSelectedList()
            let list = ktvMusicSelectedList
            unlockSelectedList()
            if let action = getSelectedListCallback {
                action(0,"",list)
            }
            else {
                notiListChange()
            }
            if let first = list.first {
                notiPrepare(musicID: String(first.musicID))
            }
        case gKaraoke_VALUE_CMD_INSTRUCTION_MSTOP:
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
        case gKaraoke_VALUE_CMD_INSTRUCTION_MDELETE:
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
        case gKaraoke_VALUE_CMD_INSTRUCTION_MDELETEALL:
            guard isOwner else { return }
            var index = IndexSet()
            lockSelectedList()
            for (i, music) in ktvMusicSelectedList.enumerated() {
                if music.userId == info.userID {
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
        case gKaraoke_VALUE_CMD_INSTRUCTION_MPREPARE:
            debugPrint("___ recv prepare content: \(content)")
            serviceDelegate?.onShouldSetLyric(musicID: content)
            currentLrc = content
        case gKaraoke_VALUE_CMD_INSTRUCTION_MLISTCHANGE:
            guard let data = content.data(using: .utf8) else { return }
            guard let list = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [ [String:Any] ] else {
                return
            }
            var selectedList: [KaraokeMusicModel] = []
            for json in list {
                guard let musicID = json["musicId"] as? String else { break }
                if let model = KaraokeMusicModel.json(json) {
                    for info in ktvMusicList {
                        if musicID == info.getMusicId() {
                            model.music.lrcLocalPath = info.lrcLocalPath
                            model.music.accompanyLocalPath = info.accompanyLocalPath
                            model.music.lrcLocalPath = info.lrcLocalPath
                            selectedList.append(model)
                            break;
                        }
                    }
                }
            }
            lockSelectedList()
            ktvMusicSelectedList = selectedList
            unlockSelectedList()
            serviceDelegate?.onMusicListChange(musicInfoList: selectedList, reason: 0)
        case gKaraoke_VALUE_CMD_INSTRUCTION_MCOMPLETE:
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
                    if next.userId == ownerID {
                        serviceDelegate?.onShouldPlay(next)
                        serviceDelegate?.onShouldSetLyric(musicID: String(next.musicID))
                    }
                    else {
                        sendShouldPlay(userID: next.userId, musicID: String(next.musicID))
                    }
                }
            }
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

extension KaraokeMusicImplement: KaraokeMusicService {
    public func ktvGetPopularMusic(callback: @escaping PopularMusicListCallback) {
        callback(0,"",[KaraokePopularInfo(playlistId: "", topic: "", musicNum: 0, description: "")])
    }
    
    public func ktvSearchMusicByKeyWords(offset: Int, pageSize:Int, keyWords: String, callback: @escaping MusicListCallback) {
        callback(0,"",[])
    }
    
    public func downloadMusic(_ musicInfo: KaraokeMusicInfo, progress: @escaping MusicProgressCallback, complete: @escaping MusicFinishCallback) {
        progress(musicInfo.getMusicId(),1.0)
        complete(musicInfo.getMusicId(),0,"")
    }
    
    public func isMusicPreloaded(musicId: String) -> Bool {
        return true
    }
    
    public func genMusicURI(musicId: String, bgmType: Int32) -> String {
        for tmpInfo in ktvMusicList {//0：原唱，1：伴奏  2:  歌词
            if tmpInfo.performId == musicId {
                if bgmType == 0 {
                    return tmpInfo.muscicLocalPath
                }else if bgmType == 1 {
                    return tmpInfo.accompanyLocalPath
                }else if bgmType == 2 {
                    return tmpInfo.lrcLocalPath
                }
            }
        }
        return ""
    }
    
    public func ktvGetMusicPage(playlistId: String, offset: Int, pageSize:Int, callback: @escaping MusicListCallback){
        callback(0,"",ktvMusicList)
    }
    
    public func ktvGetSelectedMusicList(_ callback: @escaping MusicSelectedListCallback) {
        lockSelectedList()
        let list = ktvMusicSelectedList
        unlockSelectedList()
        callback(0,"",list)
        if let first = list.first {
            serviceDelegate?.onShouldSetLyric(musicID: String(first.musicID))
        }
        if !isOwner {
            getSelectedListCallback = callback
            sendRequestSelectedList()
        }
    }
    
    public func pickMusic(musicInfo: KaraokeMusicInfo, callback: @escaping ActionCallback) {
        let  musicID = musicInfo.getMusicId()
        if isOwner {
            var minfo: KaraokeMusicInfo?
            for tmpInfo in ktvMusicList {
                if tmpInfo.performId == musicID {
                    minfo = tmpInfo
                    break
                }
            }
            guard let info = minfo else {
                return
            }
            let music = KaraokeMusicModel(sourceModel: KaraokeMusicInfo.copyMusic(info))
            music.isSelected = true
            music.bookUserName = TRTCKaraokeIMManager.shared.curUserName
            music.userId = TRTCKaraokeIMManager.shared.curUserID
            music.music.userId = TRTCKaraokeIMManager.shared.curUserID
            music.seatIndex = TRTCKaraokeIMManager.shared.seatIndex
            lockSelectedList()
            let shouldPlay = ktvMusicSelectedList.count == 0
            ktvMusicSelectedList.append(music)
            unlockSelectedList()
            notiListChange()
            serviceDelegate?.onShouldShowMessage(music)
            if shouldPlay {
                serviceDelegate?.onShouldPlay(music)
                serviceDelegate?.onShouldSetLyric(musicID: String(music.musicID))
            }
            callback(0,"")
        }
        else {
            sendInstruction(gKaraoke_VALUE_CMD_INSTRUCTION_MPICK, userID: ownerID, musicID: musicID)
            callback(0,"")
        }
    }
    
    
    public func deleteMusic(musicInfo: KaraokeMusicInfo, callback: @escaping ActionCallback) {
        let musicID: String = musicInfo.getMusicId()
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
            callback(0,"")
        }
        else {
            sendInstruction(gKaraoke_VALUE_CMD_INSTRUCTION_MDELETE, userID: ownerID, musicID: musicID)
        }
    }
    public func topMusic(musicInfo: KaraokeMusicInfo, callback: @escaping ActionCallback) {
        let musicID: String = musicInfo.getMusicId()
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
        callback(0,"")
    }
    
    public func nextMusic(musicInfo: KaraokeMusicInfo, callback: @escaping ActionCallback) {
        guard isOwner else { return }
        lockSelectedList()
        let list = ktvMusicSelectedList
        unlockSelectedList()
        guard list.count > 0 else { return }
        guard let current = list.first else { return }
        if current.userId == ownerID {
            serviceDelegate?.onShouldStopPlay(current)
            callback(0,"")
        }
        else {
            sendShouldStop(userID: current.userId, musicID: String(current.musicID))
            callback(0,"")
        }
    }
    
    public func deleteAllMusic(userID: String, callback: @escaping ActionCallback) {
        if isOwner {
            lockSelectedList()
            var index = IndexSet()
            for (i, music) in ktvMusicSelectedList.enumerated() {
                if music.userId == ownerID {
                    music.reset()
                    index.insert(i)
                }
            }
            ktvMusicSelectedList.remove(atOffsets: index)
            unlockSelectedList()
            notiListChange()
            callback(0,"")
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
                if next.userId == ownerID {
                    serviceDelegate?.onShouldPlay(next)
                }
                else {
                    sendShouldPlay(userID: next.userId, musicID: String(next.musicID))
                }
            }
        }
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

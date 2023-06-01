//
//  TRTCKaraokeViewModel.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

import Foundation
import TUICore

public enum RoomUserType {
    case anchor//主播
    case audience//观众
}

protocol TRTCKaraokeViewResponder: AnyObject {
    func showToast(message: String)
    func showToastActivity()
    func hiddenToastActivity()
    func popToPrevious()
    func switchView(type: RoomUserType)
    func changeRoom(info: KaraokeRoomInfo)
    func refreshAnchorInfos()
    func onSeatMute(isMute: Bool)
    func onAnchorMute()
    func showAlert(info: (title: String, message: String), sureAction: @escaping () -> Void, cancelAction: (() -> Void)?)
    func showActionSheet(actionTitles:[String], actions: @escaping (Int) -> Void)
    func refreshMsgView()
    func msgInput(show: Bool)
    func audienceListRefresh()
    func stopPlayBGM() // 停止播放音乐
    func showGiftAnimation(giftInfo: TUIGiftInfo)
    func updateChorusBtnStatus(musicId: String)
    func showUpdateNetworkAlert(info: (isUpdateSuccessed: Bool, message: String), retryAction: (() -> Void)?, cancelAction: @escaping (() -> Void))
    func onDashboardButtonPress()
    func refreshDashboard()
    func onShowSongSelectorAlert()
    func onManageSongBtnClick()
    func onSongSelectorAlertMusicListChanged()
    func onSongSelectorAlertSelectedMusicListChanged()
}

class TRTCKaraokeViewModel: NSObject {
    var muteItem: IconTuple?
    private let kSendGiftCmd = "0"
    private let dependencyContainer: TRTCKaraokeEnteryControl
    private let giftManager = TUIGiftManager.sharedManager()
    private var roomType: KaraokeViewType = .audience
    public weak var viewResponder: TRTCKaraokeViewResponder?
    var currentMusicModel: KaraokeMusicInfo? = nil
    var musicService: KaraokeMusicService?
    public weak var rootVC: TRTCKaraokeViewController?
    var isOwner: Bool {
        return TUILogin.getUserID() == roomInfo.ownerId
    }
    var ownerID: String {
        return roomInfo.ownerId
    }
    private(set) var isSelfMute: Bool = false
    // 防止多次退房
    private var isExitingRoom: Bool = false
    
    private var isTakeSeat: Bool = false
    
    private(set) var roomInfo: KaraokeRoomInfo
    private(set) var isSeatInitSuccess: Bool = false
    private(set) var mSelfSeatIndex: Int = -1
    
    // UI相关属性
    private(set) var anchorSeatList: [SeatInfoModel] = []
    /// 观众信息记录
    private(set) var memberAudienceList: [AudienceInfoModel] = []
    private(set) var memberAudienceDic: [String: AudienceInfoModel] = [:]
    public func getRealMemberAudienceList() -> [AudienceInfoModel] {
        var res : [AudienceInfoModel] = []
        for audience in memberAudienceList {
            if memberAudienceDic.keys.contains(audience.userInfo.userId) {
                res.append(audience)
            }
        }
        return res
    }
    
    public var userType: RoomUserType = .audience
    
    private(set) var msgEntityList: [MsgEntity] = []
    /// 当前邀请操作的座位号记录
    private var currentInvitateSeatIndex: Int = -1 // -1 表示没有操作
    /// 上麦信息记录(观众端)
    private var mInvitationSeatDic: [String: Int] = [:]
    /// 上麦信息记录(主播端)
    private var mTakeSeatInvitationDic: [String: String] = [:]
    /// 抱麦信息记录
    private var mPickSeatInvitationDic: [String: SeatInvitation] = [:]
    
    var trtcStatisics: TRTCStatistics?
    
    var userVolumeDic : [String : UInt] = [:]
    
    private var userNetworkMap : [String : Int] = [:]

    /// NTP网络校时是否成功
    var updateNetworkSuccessed: Bool = false
    
    var loginUserName: String {
        TUILogin.getNickName() ?? ""
    }
    
    var loginUserFaceUrl: String {
        TUILogin.getFaceUrl() ?? ""
    }
    
    var loginUserId: String {
        TUILogin.getUserID() ?? ""
    }
    
    lazy var effectViewModel: TRTCKaraokeSoundEffectViewModel = {
        return TRTCKaraokeSoundEffectViewModel(self)
    }()
    
    /// 初始化方法
    /// - Parameter container: 依赖管理容器，负责Karaoke模块的依赖管理
    init(container: TRTCKaraokeEnteryControl, roomInfo: KaraokeRoomInfo, roomType: KaraokeViewType) {
        self.dependencyContainer = container
        self.roomType = roomType
        self.roomInfo = roomInfo
        self.musicService = container.getMusicService(roomInfo: roomInfo)
        super.init()
        Karaoke.setObserver(observer: self)
        self.musicService?.addObserver(self)
        initAnchorListData()
    }
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
        dependencyContainer.clearKaraoke()
    }
    
    var Karaoke: TRTCKaraokeRoom {
        return dependencyContainer.getKaraoke()
    }
    
    func getNetworkLevel(userId:String) -> Int {
        if !userNetworkMap.keys.contains(userId) {
            return 0
        }
        if let networklevel = userNetworkMap[userId] {
            return networklevel
        }
        return 0
    }

    func getCurrentNetworkLevel() -> Int {
        return getNetworkLevel(userId: loginUserId)
    }

    public func getSeatIndexByUserId(userId:String) -> NSInteger {
        // 修改座位列表的user信息
        for index in 0..<self.anchorSeatList.count {
            let seatInfo = anchorSeatList[index]
            if seatInfo.seatInfo?.user == userId {
                return seatInfo.seatIndex
            }
        }
        return 0
    }
    
    func getSeatUserByUserId(userId:String) -> KaraokeUserInfo? {
        // 修改座位列表的user信息
        for index in 0..<self.anchorSeatList.count {
            let seatInfo = anchorSeatList[index]
            if seatInfo.seatInfo?.user == userId {
                return seatInfo.seatUser
            }
        }
        return nil
    }
    
    func exitRoom(completion: @escaping (() -> ())) {
        guard !isExitingRoom else { return }
        musicService?.destroyService()
        if isOwner {
            musicService?.clearPlaylistByUserId(userID: loginUserId, callback: { (code, msg) in
                
            })
        }
        viewResponder?.popToPrevious()
        isExitingRoom = true
        Karaoke.exitRoom { [weak self] (code, message) in
            guard let self = self else { return }
            if self.isOwner && self.roomType == .owner {
                self.dependencyContainer.destroyRoom(roomID: self.roomInfo.roomId, success: {
                    TRTCLog.out("---deinit room success")
                }) { (code, message) in
                    TRTCLog.out("---deinit room failed")
                }
                self.Karaoke.destroyRoom { [weak self] (code, message) in
                    guard let self = self else { return }
                    self.isExitingRoom = false
                    completion()
                }
            } else {
                self.isExitingRoom = false
                completion()
            }
        }
        updateNetworkSuccessed = false
    }
    
    var voiceEarMonitor: Bool = false {
        willSet {
            self.Karaoke.enableVoiceEarMonitor(enable: newValue)
        }
    }
    
    public func refreshView() {
        viewResponder?.switchView(type: userType)
    }
    
    public func openMessageTextInput() {
        viewResponder?.msgInput(show: true)
    }
    
    public func muteAction(isMute: Bool) -> Bool {
        if let userSeatInfo = getUserSeatInfo(userId: loginUserId)?.seatInfo, userSeatInfo.mute {
            viewResponder?.showToast(message: .seatmutedText)
            return false
        }
        isSelfMute = isMute
        Karaoke.muteLocalAudio(mute: isMute)
        let userSeatInfo = getUserSeatInfo(userId: loginUserId)
        userSeatInfo?.seatUser?.mute = isMute
        viewResponder?.onAnchorMute()
        if isMute {
            viewResponder?.showToast(message: .micmutedText)
        } else {
            viewResponder?.showToast(message: .micunmutedText)
        }
        return true
    }
    
    public func spechAction(isMute: Bool) {
        Karaoke.muteAllRemoteAudio(isMute: isMute)
        if isMute {
            viewResponder?.showToast(message: .mutedText)
        } else {
            viewResponder?.showToast(message: .unmutedText)
        }
    }
    
    public func clickSeat(model: SeatInfoModel) {
        guard isSeatInitSuccess else {
            viewResponder?.showToast(message: .seatuninitText)
            return
        }
        if isOwner {
            ownerClickItem(model: model)
        }
        else {
            audienceClickItem(model: model)
        }
    }
    
    public func clickAudienceAgree(model: AudienceInfoModel) {
        
    }
    
    public func clickSeatLock(isLock: Bool, model: SeatInfoModel) {
        self.Karaoke.closeSeat(seatIndex: model.seatIndex, isClose: isLock, callback: nil)
    }
    
    func enterRoom() {
        guard let intRoomId = Int32(roomInfo.roomId) else { return }
        Karaoke.enterRoom(roomID: intRoomId) { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                self.Karaoke.updateNetworkTime()
                self.viewResponder?.showToast(message: .enterSuccessText)
                self.getAudienceList()
                if self.isOwner {
                    // 房主自己进房更新UI信息
                    self.viewResponder?.changeRoom(info: self.roomInfo)
                    self.roomType = .owner
                    self.userType = .anchor
                    self.refreshView()
                } else {
                    self.roomType = .audience
                }
            } else {
                self.viewResponder?.showToast(message: .enterFailedText)
                self.viewResponder?.popToPrevious()
            }
        }
    }
    
    func createRoom() {
        let faceUrl = TUILogin.getFaceUrl() ?? ""
        Karaoke.setSelfProfile(userName: roomInfo.ownerName, avatarURL: faceUrl) { [weak self] (code, message) in
            guard let `self` = self else { return }
            TRTCLog.out("setSelfProfile\(code):\(message)")
            self.dependencyContainer.createRoom(roomID: self.roomInfo.roomId) {  [weak self] in
                guard let `self` = self else { return }
                self.internalCreateRoom()
            } failed: { [weak self] code, message in
                guard let `self` = self else { return }
                if code == -1301 {
                    self.internalCreateRoom()
                } else {
                    self.viewResponder?.showToast(message: .createRoomFailedText)
                    self.viewResponder?.popToPrevious()
                }
            }
        }
    }
    
    public func onTextMsgSend(message: String) {
        if message.count == 0 {
            return
        }
        // 消息回显示
        let entity = MsgEntity(userId: loginUserId, userName: .meText, content: message, invitedId: "", type: .normal)
        notifyMsg(entity: entity)
        Karaoke.sendRoomTextMsg(message: message) { [weak self] (code, message) in
            guard let `self` = self else { return }
            self.viewResponder?.showToast(message: code == 0 ? .sendSuccessText :  localizeReplaceXX(.sendFailedText, message))
        }
    }
    
    public func acceptTakeSeat(identifier: String) {
        if let audience = memberAudienceDic[identifier] {
            acceptTakeSeatInvitation(userInfo: audience.userInfo)
        }
    }
    
    func sendGift(giftId: String, callback: KaraokeCallback?) {
        let giftMsgInfo = TUIGiftMsgInfo(giftId: giftId, sendUser: TUILogin.getNickName() ?? "", sendUserHeadIcon: TUILogin.getFaceUrl() ?? "")
        do {
            let encoder = JSONEncoder.init()
            let data = try encoder.encode(giftMsgInfo)
            let message = String.init(decoding: data, as: UTF8.self)
            Karaoke.sendRoomCustomMsg(cmd: kSendGiftCmd, message: message, callback: callback)
        } catch {
            
        }
    }
    
    func sendSelectedMusic(musicInfo: KaraokeMusicInfo) {
        let userId = musicInfo.userId
        let musicName = musicInfo.musicName
        guard let data = try? JSONSerialization.data(withJSONObject: [gKaraoke_VALUE_CMD_MUSICNAME: musicName,
                                                                         gKaraoke_VALUE_CMD_USERID: userId,],
                                                     options: .prettyPrinted) else { return }
        guard let message = String(data: data, encoding: .utf8) else { return }
        Karaoke.sendRoomCustomMsg(cmd: gKaraoke_KEY_CMD_SELECTED_MUSIC, message: message)
    }
    
    func showSelectedMusic(userId: String, musicName: String) {
        let action = { [weak self] in
            guard let `self` = self else { return }
            if self.isOwner {
                self.viewResponder?.onManageSongBtnClick()
            } else {
                self.viewResponder?.showToast(message: .onlyOwnerText)
            }
        }
        let userInfo = getSeatUserByUserId(userId: userId)
        let seatIndex = getSeatIndexByUserId(userId: userId)
        showNotifyMsg(messsage: localizeReplaceThreeCharacter(.xxSeatSelectzzSongText, "\(seatIndex + 1)", "xxx", musicName),
                      userName: userInfo?.userName ?? "",
                      type: .manage_song,
                      action: action)
    }
    
    func showSongSelectorAlert() {
        viewResponder?.onShowSongSelectorAlert()
    }
    
    func notiMusicListChange() {
        viewResponder?.onSongSelectorAlertMusicListChanged()
    }
    
    func notiSelectedMusicListChange() {
        viewResponder?.onSongSelectorAlertSelectedMusicListChanged()
    }
}

// MARK: - private method
extension TRTCKaraokeViewModel {
    
    private func internalCreateRoom() {
        guard let intRoomId = Int32(roomInfo.roomId) else { return }
        let param = KaraokeRoomParam()
        param.roomName = roomInfo.roomName
        param.needRequest = roomInfo.needRequest == 1
        param.coverUrl = roomInfo.cover
        param.seatCount = 8
        param.seatInfoList = []
        for _ in 0..<param.seatCount {
            let seatInfo = KaraokeSeatInfo()
            param.seatInfoList.append(seatInfo)
        }
        Karaoke.createRoom(roomID: intRoomId, roomParam: param) { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                self.Karaoke.enterRoom(roomID: intRoomId) { [weak self] code, message in
                    guard let self = self else { return }
                    if code == 0 {
                        self.Karaoke.updateNetworkTime()
                        self.viewResponder?.changeRoom(info: self.roomInfo)
                        self.getAudienceList()
                        self.roomType = self.isOwner ? .owner : .audience
                        if self.isOwner && self.mSelfSeatIndex == -1 {
                            self.startTakeSeat(seatIndex: 0)
                        }
                    } else {
                        self.viewResponder?.showToast(message: .enterFailedText)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            guard let `self` = self else { return }
                            self.viewResponder?.popToPrevious()
                        }
                    }
                }
            } else {
                self.viewResponder?.showToast(message: .createRoomFailedText)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let `self` = self else { return }
                    self.viewResponder?.popToPrevious()
                }
            }
        }
    }
    
    private func getAudienceList() {
        Karaoke.getUserInfoList(userIDList: nil) { [weak self] (code, message, infos) in
            guard let `self` = self else { return }
            if code == 0 {
                self.memberAudienceList.removeAll()
                let audienceInfoModels = infos.map { (userInfo) -> AudienceInfoModel in
                    return AudienceInfoModel.init(userInfo: userInfo) { [weak self] (index) in
                        // 点击邀请上麦事件，以及接受邀请事件
                        guard let `self` = self else { return }
                        if index == 0 {
                            self.sendInvitation(userInfo: userInfo)
                        } else {
                            self.acceptTakeSeatInvitation(userInfo: userInfo)
                        }
                    }
                }
                self.memberAudienceList.append(contentsOf: audienceInfoModels)
                audienceInfoModels.forEach { (info) in
                    self.memberAudienceDic[info.userInfo.userId] = info
                }
                self.viewResponder?.audienceListRefresh()
            }
        }
    }
    
    private func initAnchorListData() {
        for _ in 0...7 {
            var model = SeatInfoModel.init { [weak self] (seatIndex) in
                guard let `self` = self else { return }
                if seatIndex >= 0 && seatIndex <= self.anchorSeatList.count {
                    let model = self.anchorSeatList[seatIndex]
                    self.clickSeat(model: model)
                }
            }
            model.isOwner = isOwner
            model.isClosed = false
            model.isUsed = false
            anchorSeatList.append(model)
        }
    }
    
    private func audienceClickItem(model: SeatInfoModel) {
        guard !model.isClosed else {
            viewResponder?.showToast(message: .seatLockedText)
            return
        }
        let networklevel = getCurrentNetworkLevel()
        if networklevel > 2 {
            if networklevel == 6 {
                viewResponder?.showToast(message: .audienceCheckNetworkText)
            } else {
                viewResponder?.showToast(message: .handupCheckNetworkText)
            }
            return
        }

        if model.isUsed {
            if loginUserId == model.seatUser?.userId ?? "" {
                viewResponder?.showAlert(info: (title: .sureToLeaveSeatText, message: ""), sureAction: { [weak self] in
                    guard let `self` = self else { return }
                    self.leaveSeat()
                }, cancelAction: {
                    
                })
            }
            else {
                viewResponder?.showToast(message: "\(model.seatUser?.userName ?? .otherAnchorText)")
            }
        }
        else {
            if mSelfSeatIndex != -1 {
                viewResponder?.showToast(message: localizeReplaceXX(.isInxxSeatText, String(mSelfSeatIndex + 1)))
                return
            }
            guard model.seatIndex != -1 else {
                viewResponder?.showToast(message: .notInitText)
                return
            }
            viewResponder?.showActionSheet(actionTitles: [.handsupText], actions: { [weak self] (index) in
                guard let `self` = self else { return }
                self.startTakeSeat(seatIndex: model.seatIndex)
            })
        }
    }
    
    private func ownerClickItem(model: SeatInfoModel) {
        var model = model
        if model.isUsed {
            if model.seatUser?.userId == loginUserId {
                viewResponder?.showAlert(info: (title: .sureToLeaveSeatText, message: ""), sureAction: { [weak self] in
                    guard let `self` = self else { return }
                    self.leaveSeat()
                }, cancelAction: {
                    
                })
            }
            else {
                let isMute = model.seatInfo?.mute ?? false
                viewResponder?.showActionSheet(actionTitles: [localizeReplaceXX(.totaxxText, (isMute ? String.unmuteOneText : String.muteOneText)), .makeAudienceText], actions: { [weak self] (index) in
                    guard let `self` = self else { return }
                    if index == 0 {
                        // 禁言
                        self.Karaoke.muteSeat(seatIndex: model.seatIndex, isMute: !isMute, callback: nil)
                    } else {
                        // 下麦
                        self.Karaoke.kickSeat(seatIndex: model.seatIndex, callback: nil)
                    }
                })
            }
        }
        else {

            var title: [String] = []
            if model.isClosed {
                title = [.unlockSeatText]
            }
            else {
                title = [.takeSeatText, .lockSeatText]
                if mSelfSeatIndex >= 0 {
                    title.removeFirst()
                }
            }
            viewResponder?.showActionSheet(actionTitles: title, actions: { [weak self] (index) in
                guard let `self` = self else { return }
                if index == 0 {
                    if model.isClosed {
                        model.isClosed = !model.isClosed
                        self.clickSeatLock(isLock: model.isClosed, model: model)
                    }
                    else {
                        if self.mSelfSeatIndex >= 0 {
                            model.isClosed = !model.isClosed
                            self.clickSeatLock(isLock: model.isClosed, model: model)
                        }
                        else {
                            self.startTakeSeat(seatIndex: model.seatIndex)
                        }
                    }
                }
                else {
                    model.isClosed = !model.isClosed
                    self.clickSeatLock(isLock: model.isClosed, model: model)
                }
            })
        }
    }
    
    private func sendInvitation(userInfo: KaraokeUserInfo) {
        guard currentInvitateSeatIndex != -1 else { return }
        // 邀请
        let seatEntity = anchorSeatList[currentInvitateSeatIndex]
        if seatEntity.isUsed {
            viewResponder?.showToast(message: .seatBusyText)
            return
        }
        let seatInvitation = SeatInvitation.init(seatIndex: currentInvitateSeatIndex, inviteUserId: userInfo.userId)
        let inviteId = Karaoke.sendInvitation(cmd: KaraokeConstants.CMD_PICK_UP_SEAT,
                                                userId: seatInvitation.inviteUserId,
                                                content: "\(seatInvitation.seatIndex)") { [weak self] (code, message) in
                                                    guard let `self` = self else { return }
                                                    if code == 0 {
                                                        self.viewResponder?.showToast(message: .sendInviteSuccessText)
                                                    }
        }
        mPickSeatInvitationDic[inviteId] = seatInvitation
    }
    
    private func acceptTakeSeatInvitation(userInfo: KaraokeUserInfo) {
        // 接受
        guard let inviteID = mTakeSeatInvitationDic[userInfo.userId] else {
            viewResponder?.showToast(message: .reqExpiredText)
            return
        }
        Karaoke.acceptInvitation(identifier: inviteID) { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                // 接受请求成功，刷新外部对话列表
                if let index = self.msgEntityList.firstIndex(where: { (msg) -> Bool in
                    return msg.invitedId == inviteID
                }) {
                    var msg = self.msgEntityList[index]
                    msg.type = .agreed
                    self.msgEntityList[index] = msg
                    self.viewResponder?.refreshMsgView()
                }
            } else {
                self.viewResponder?.showToast(message: .acceptReqFailedText)
            }
        }
    }
    
    public func leaveSeat() {
        Karaoke.leaveSeat { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                self.viewResponder?.showToast(message: .audienceSuccessText)
            } else {
                self.viewResponder?.showToast(message: localizeReplaceXX(.audienceFailedxxText, message))
            }
        }
    }
    
    /// 观众开始上麦
    /// - Parameter seatIndex: 上的作为号
    private func startTakeSeat(seatIndex: Int) {
        if isOwner {
            // 不需要的情况下自动上麦
            if self.isTakeSeat {
                return
            }
            self.isTakeSeat = true
            Karaoke.enterSeat(seatIndex: seatIndex) { [weak self] (code, message) in
                guard let `self` = self else { return }
                if code == 0 {
                    self.viewResponder?.showToast(message: .handsupSuccessText)
                } else {
                    self.viewResponder?.showToast(message: .handsupFailedText)
                }
                self.isTakeSeat = false
            }
        }
        else {
            // 观众端上麦，检查NTP校时是否成功
            if !updateNetworkSuccessed {
                viewResponder?.showUpdateNetworkAlert(info: (isUpdateSuccessed: false,
                                                             message: .updateNetworkFailedDonotEnterSeatText),
                                                      retryAction: { [weak self] in
                    guard let self = self else { return }
                    self.Karaoke.updateNetworkTime()
                }, cancelAction: {
                    
                })
                return
            }
            guard roomInfo.ownerId != "" else {
                viewResponder?.showToast(message: .roomNotReadyText)
                return
            }
            let cmd = KaraokeConstants.CMD_REQUEST_TAKE_SEAT
            let targetUserId = roomInfo.ownerId
            let inviteId = Karaoke.sendInvitation(cmd: cmd, userId: targetUserId, content: "\(seatIndex)") { [weak self] (code, message) in
                guard let `self` = self else { return }
                if code == 0 {
                    self.viewResponder?.showToast(message: .reqSentText)
                } else {
                    self.viewResponder?.showToast(message: localizeReplaceXX(.reqSendFailedxxText, message))
                }
            }
            currentInvitateSeatIndex = seatIndex
            mInvitationSeatDic[inviteId] = seatIndex
        }
    }
    
    private func recvPickSeat(identifier: String, cmd: String, content: String) {
        guard let seatIndex = Int.init(content) else { return }
        viewResponder?.showAlert(info: (title: .alertText, message: localizeReplaceXX(.invitexxSeatText, String(seatIndex))), sureAction: { [weak self] in
            guard let `self` = self else { return }
            self.Karaoke.acceptInvitation(identifier: identifier) { [weak self] (code, message) in
                guard let `self` = self else { return }
                if code != 0 {
                    self.viewResponder?.showToast(message: .acceptReqFailedText)
                }
            }
        }, cancelAction: { [weak self] in
            guard let `self` = self else { return }
            self.Karaoke.rejectInvitation(identifier: identifier) { [weak self] (code, message) in
                guard let `self` = self else { return }
                self.viewResponder?.showToast(message: .refuseHandsupText)
            }
        })
    }
    
    private func recvTakeSeat(identifier: String, inviter: String, content: String) {
        // 收到新的邀请后，更新列表,其他的信息
        if let index = msgEntityList.firstIndex(where: { (msg) -> Bool in
            return msg.userId == inviter && msg.type == .wait_agree
        }) {
            var msg = msgEntityList[index]
            msg.type = .agreed
            msgEntityList[index] = msg
        }
        // 显示到通知栏
        let audinece = memberAudienceDic[inviter]
        let seatIndex = (Int.init(content) ?? 0)
        let content = localizeReplaceXX(.applyxxSeatText, String(seatIndex + 1))
        let msgEntity = MsgEntity.init(userId: inviter, userName: audinece?.userInfo.userName ?? inviter, content: content, invitedId: identifier, type: .wait_agree)
        msgEntityList.append(msgEntity)
        viewResponder?.refreshMsgView()
        if var audienceModel = audinece {
            audienceModel.type = AudienceInfoModel.TYPE_WAIT_AGREE
            memberAudienceDic[audienceModel.userInfo.userId] = audienceModel
            if let index = memberAudienceList.firstIndex(where: { (model) -> Bool in
                return model.userInfo.userId == audienceModel.userInfo.userId
            }) {
                memberAudienceList[index] = audienceModel
            }
            viewResponder?.audienceListRefresh()
        }
        mTakeSeatInvitationDic[inviter] = identifier
    }
    
    private func notifyMsg(entity: MsgEntity) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            if self.msgEntityList.count > 1000 {
                self.msgEntityList.removeSubrange(0...99)
            }
            self.msgEntityList.append(entity)
            self.viewResponder?.refreshMsgView()
        }
    }
    
    private func showNotifyMsg(messsage: String, userName: String, type: MsgEntityType = .normal, action: (() -> ())? = nil) {
        let msgEntity = MsgEntity.init(userId: "", userName: userName, content: messsage, invitedId: "", type: type, action: action)
        if msgEntityList.count > 1000 {
            msgEntityList.removeSubrange(0...99)
        }
        msgEntityList.append(msgEntity)
        viewResponder?.refreshMsgView()
    }
    
    private func changeAudience(status: Int, user: KaraokeUserInfo) {
        guard [AudienceInfoModel.TYPE_IDEL, AudienceInfoModel.TYPE_IN_SEAT, AudienceInfoModel.TYPE_WAIT_AGREE].contains(status) else { return }
        if isOwner && roomType == .owner {
            let audience = memberAudienceDic[user.userId]
            if var audienceModel = audience {
                if audienceModel.type == status { return }
                audienceModel.type = status
                memberAudienceDic[audienceModel.userInfo.userId] = audienceModel
                if let index = memberAudienceList.firstIndex(where: { (model) -> Bool in
                    return model.userInfo.userId == audienceModel.userInfo.userId
                }) {
                    memberAudienceList[index] = audienceModel
                }
            }
        }
        viewResponder?.audienceListRefresh()
    }
    
    /// 根据userId查询用户的麦位信息
    /// - Parameter userId: 需要查询的用户id
    /// - Returns: 查询到的用户麦位信息 SeatInfoModel， 找不到返回nil
    private func getUserSeatInfo(userId:String) -> SeatInfoModel? {
        if userId.isEmpty {
            return nil
        }
        for item in anchorSeatList {
            if let seatInfo = item.seatInfo, seatInfo.user == userId {
                return item
            }
        }
        return nil
    }
}

// MARK: - TRTCKaraokeRoomObserver
extension TRTCKaraokeViewModel: TRTCKaraokeRoomObserver {
    
    func genUserSign(userId: String, completion: @escaping (String) -> Void) {
        self.dependencyContainer.genUserSign(userId: userId, completion: completion)
    }
    
    func onNetWorkQuality(trtcQuality: TRTCQualityInfo, arrayList: [TRTCQualityInfo]) {
        self.userNetworkMap[loginUserId] = trtcQuality.quality.rawValue
        for quality in arrayList {
            if let userId = quality.userId {
                self.userNetworkMap[userId] = quality.quality.rawValue
            }
        }
        self.viewResponder?.refreshAnchorInfos()
    }

    func onUpdateNetworkTime(errCode: Int32, message errMsg: String, retryHandler: @escaping (Bool) -> Void) {
        /*
         errCode 0 为合适参与合唱；
                 1 建议 UI 提醒当前网络不够好，可能会影响合唱效果；（同样建议 UI 提醒）
                -1 需要重新校时（同样建议 UI 提醒）
         */
        if errCode == 0 {
            updateNetworkSuccessed = true
            viewResponder?.showUpdateNetworkAlert(info: (isUpdateSuccessed: true,
                                                         message: .updateNetworkSuccessedText),
                                                  retryAction: {
            }, cancelAction: {
                retryHandler(false)
            })
        } else {
            updateNetworkSuccessed = false
            viewResponder?.showUpdateNetworkAlert(info: (isUpdateSuccessed: false,
                                                         message: .updateNetworkFailedText),
                                                  retryAction: {
                retryHandler(true)
            }, cancelAction: {
                retryHandler(false)
            })
        }
    }
    
    func onReceiveAnchorSendChorusMsg(musicId: String, startDelay: Int) {
        if userType == .audience { return }
        effectViewModel.musicSelectedList.forEach { [weak self] musicInfo in
            guard let self = self else { return }
            if musicInfo.performId == musicId {
                self.effectViewModel.viewResponder?.onReceiveStartChorusCmd(musicId: musicId)
                self.effectViewModel.setVolume(music: self.effectViewModel.musicVolume)
                self.Karaoke.startPlayMusic(musicID: Int32(musicInfo.performId) ?? 0,
                                            originalUrl: musicInfo.originUrl,
                                            accompanyUrl: musicInfo.accompanyUrl ?? "")
                return
            }
        }
    }
    
    func onError(code: Int32, message: String) {
        
    }
    
    func onWarning(code: Int32, message: String) {
        
    }
    
    func onDebugLog(message: String) {
        
    }
    
    func onStatistics(statistics: TRTCStatistics) {
        trtcStatisics = statistics
        viewResponder?.refreshDashboard()
    }
    
    func onRoomDestroy(message: String) {
        if TRTCKaraokeFloatingWindowManager.shared().windowIsShowing {
            TRTCKaraokeFloatingWindowManager.shared().closeWindowAndExitRoom {
                if let window = UIApplication.shared.windows.first {
                    window.makeToast(.closeRoomText)
                }
            }
        }
        else {
            if let window = UIApplication.shared.windows.first {
                window.makeToast(.closeRoomText)
            }
            viewResponder?.showToast(message: .closeRoomText)
            Karaoke.exitRoom(callback: nil)
            viewResponder?.popToPrevious()
        }
#if RTCube_APPSTORE
        guard isOwner else { return }
        let selector = NSSelectorFromString("showAlertUserLiveTimeOut")
        if UIViewController.responds(to: selector) {
            UIViewController.perform(selector)
        }
#endif
    }
    
    func onRoomInfoChange(roomInfo: KaraokeRoomInfo) {
        // 值为-1表示该接口没有返回数量信息
        if roomInfo.memberCount == -1 {
            roomInfo.memberCount = self.roomInfo.memberCount
        }
        self.roomInfo = roomInfo
        viewResponder?.changeRoom(info: self.roomInfo)
    }
    
    func onSeatListChange(seatInfoList: [KaraokeSeatInfo]) {
        TRTCLog.out("roomLog: onSeatListChange: \(seatInfoList)")
        isSeatInitSuccess = true
        seatInfoList.enumerated().forEach { (item) in
            let seatIndex = item.offset
            let seatInfo = item.element
            var anchorSeatInfo = SeatInfoModel.init { [weak self] (seatIndex) in
                guard let `self` = self else { return }
                if seatIndex >= 0 && seatIndex <= self.anchorSeatList.count {
                    let model = self.anchorSeatList[seatIndex]
                    self.clickSeat(model: model)
                }
            }
            anchorSeatInfo.seatInfo = seatInfo
            let mute = anchorSeatList[seatIndex].seatInfo?.mute ?? false
            anchorSeatInfo.seatInfo?.mute = mute
            anchorSeatInfo.isUsed = seatInfo.status == 1
            anchorSeatInfo.isClosed = seatInfo.status == 2
            anchorSeatInfo.seatIndex = seatIndex
            anchorSeatInfo.isOwner = isOwner
            let listIndex = seatIndex
            if anchorSeatList.count == seatInfoList.count {
                // 说明有数据
                let anchorSeatModel = anchorSeatList[listIndex]
                anchorSeatInfo.seatUser = anchorSeatModel.seatUser
                if !anchorSeatInfo.isUsed {
                    anchorSeatInfo.seatUser = nil
                }
                anchorSeatList[listIndex] = anchorSeatInfo
            } else {
                // 说明没数据
                anchorSeatList.append(anchorSeatInfo)
            }
        }
        let seatUserIds = seatInfoList.filter({ (seat) -> Bool in
            return seat.user != ""
        }).map { (seatInfo) -> String in
            return seatInfo.user
        }
        guard seatUserIds.count > 0 else {
            viewResponder?.refreshAnchorInfos()
            return
        }
        Karaoke.getUserInfoList(userIDList: seatUserIds) { [weak self] (code, message, userInfos) in
            guard let `self` = self else { return }
            guard code == 0 else { return }
            var userdic: [String : KaraokeUserInfo] = [:]
            userInfos.forEach { (info) in
                userdic[info.userId] = info
            }
            if seatInfoList.count == 0 {
                return
            }
            if self.anchorSeatList.count != seatInfoList.count {
                TRTCLog.out(String.seatlistWrongText)
                return
            }
            // 修改座位列表的user信息
            for index in 0..<self.anchorSeatList.count {
                let seatInfo = seatInfoList[index] // 从观众开始更新
                if let seatUser = userdic[seatInfo.user] {
                    seatUser.mute = seatInfo.mute
                    self.anchorSeatList[index].seatUser = seatUser
                }
            }
            self.viewResponder?.refreshAnchorInfos()
            self.viewResponder?.onAnchorMute()
        }
    }
    
    func onAnchorEnterSeat(index: Int, user: KaraokeUserInfo) {
        showNotifyMsg(messsage: localizeReplace(.beyySeatText, "xxx", String(index + 1)), userName: user.userName)
        if user.userId == loginUserId {
            userType = .anchor
            refreshView()
            mSelfSeatIndex = index
        }
        changeAudience(status: AudienceInfoModel.TYPE_IN_SEAT, user: user)
    }
    
    func onAnchorLeaveSeat(index: Int, user: KaraokeUserInfo) {
        showNotifyMsg(messsage: localizeReplace(.audienceyySeatText, "xxx", String(index + 1)), userName: user.userName)
        if user.userId == loginUserId {
            userType = .audience
            refreshView()
            mSelfSeatIndex = -1
            // 自己下麦，停止音效播放
            effectViewModel.stopPlay()
            musicService?.clearPlaylistByUserId(userID: loginUserId, callback: { (code, msg) in
                
            })
        }
        if !memberAudienceDic.keys.contains(user.userId) {
            for model in memberAudienceList {
                if model.userInfo.userId == user.userId {
                    memberAudienceDic[user.userId] = model
                    break
                }
            }
        }
        changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: user)
    }
    
    func onSeatMute(index: Int, isMute: Bool) {
        if isMute {
            showNotifyMsg(messsage: localizeReplaceXX(.bemutedxxText, String(index)), userName: "")
        } else {
            showNotifyMsg(messsage: localizeReplaceXX(.beunmutedxxText, String(index)), userName: "")
        }
        if index >= 0 && index <= anchorSeatList.count {
            anchorSeatList[index].seatInfo?.mute = isMute
        }
        if let userSeatInfo = getUserSeatInfo(userId: loginUserId),
            userSeatInfo.seatIndex == index {
            userSeatInfo.seatInfo?.mute = isMute
            isSelfMute = isMute
            viewResponder?.onSeatMute(isMute: isMute)
        }
        viewResponder?.onAnchorMute()
    }
    
    func onUserMicrophoneMute(userId: String, mute: Bool) {
        let userSeatInfo = getUserSeatInfo(userId: userId)
        userSeatInfo?.seatUser?.mute = mute
        viewResponder?.onAnchorMute()
    }
    
    func onSeatClose(index: Int, isClose: Bool) {
        showNotifyMsg(messsage: localizeReplace(.ownerxxSeatText, isClose ? .banSeatText : .unmuteOneText, String(index + 1)), userName: "")
    }
    
    func onAudienceEnter(userInfo: KaraokeUserInfo) {
        showNotifyMsg(messsage: localizeReplaceXX(.inRoomText, "xxx"), userName: userInfo.userName)
        // 主播端(房主)
        let memberEntityModel = AudienceInfoModel.init(type: 0, userInfo: userInfo) { [weak self] (index) in
            guard let `self` = self else { return }
            if index == 0 {
                self.sendInvitation(userInfo: userInfo)
            } else {
                self.acceptTakeSeatInvitation(userInfo: userInfo)
            }
        }
        if !memberAudienceDic.keys.contains(userInfo.userId) {
            memberAudienceDic[userInfo.userId] = memberEntityModel
            memberAudienceList.append(memberEntityModel)
        }
        viewResponder?.audienceListRefresh()
        changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: userInfo)
    }
    
    func onAudienceExit(userInfo: KaraokeUserInfo) {
        showNotifyMsg(messsage: localizeReplaceXX(.exitRoomText, "xxx"), userName: userInfo.userName)
        memberAudienceList.removeAll { (model) -> Bool in
            return model.userInfo.userId == userInfo.userId
        }
        memberAudienceDic.removeValue(forKey: userInfo.userId)
        viewResponder?.refreshAnchorInfos()
        viewResponder?.audienceListRefresh()
        changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: userInfo)
    }
    
    func onUserVolumeUpdate(userVolumes: [TRTCVolumeInfo], totalVolume: Int) {
        var volumeDic: [String: UInt] = [:]
        userVolumes.forEach { (info) in
            if let userId = info.userId {
                volumeDic[userId] = info.volume
            } else {
                volumeDic[loginUserId] = info.volume
            }
        }
        userVolumeDic = volumeDic
        var needRefreshUI = false
        for (index, seat) in self.anchorSeatList.enumerated() {
            if let user = seat.seatUser {
                let isTalking = (userVolumeDic[user.userId] ?? 0) > 25
                if seat.isTalking != isTalking {
                    self.anchorSeatList[index].isTalking = isTalking
                    needRefreshUI = true
                }
            }
        }
        
        if needRefreshUI {
            viewResponder?.refreshAnchorInfos()
        }
    }
    
    func onRecvRoomTextMsg(message: String, userInfo: KaraokeUserInfo) {
        let msgEntity = MsgEntity.init(userId: userInfo.userId,
                                       userName: userInfo.userName,
                                       content: message,
                                       invitedId: "",
                                       type: .normal)
        notifyMsg(entity: msgEntity)
    }
    
    func onRecvRoomCustomMsg(cmd: String, message: String, userInfo: KaraokeUserInfo) {
        if cmd == kSendGiftCmd {
            // 收到发送礼物的自定义消息
            guard let data = message.data(using: .utf8) else { return }
            let decoder = JSONDecoder.init()
            if let giftMsgInfo = try? decoder.decode(TUIGiftMsgInfo.self, from: data) {
                if let responder = viewResponder {
                    if let giftModel = giftManager.getGiftModel(giftId: giftMsgInfo.giftId) {
                        responder.showGiftAnimation(giftInfo: TUIGiftInfo.init(giftModel: giftModel, sendUser: giftMsgInfo.sendUser, sendUserHeadIcon: giftMsgInfo.sendUserHeadIcon))
                    }
                }
            } else {
                if let responder = viewResponder {
                    if let giftModel = giftManager.getGiftModel(giftId: message) {
                        responder.showGiftAnimation(giftInfo: TUIGiftInfo.init(giftModel: giftModel, sendUser: "", sendUserHeadIcon: ""))
                    }
                }
            }
        } else if cmd == gKaraoke_KEY_CMD_SELECTED_MUSIC {
            guard let data = message.data(using: .utf8) else { return }
            guard let obj = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: String] else { return }
            guard let musicName = obj[gKaraoke_VALUE_CMD_MUSICNAME] else { return }
            guard let userId = obj[gKaraoke_VALUE_CMD_USERID] else { return }
            showSelectedMusic(userId: userId, musicName: musicName)
        }
    }
    
    func onReceiveNewInvitation(identifier: String, inviter: String, cmd: String, content: String) {
        TRTCLog.out("receive message: \(cmd) : \(content)")
        if roomType == .audience {
            if cmd == KaraokeConstants.CMD_PICK_UP_SEAT {
                recvPickSeat(identifier: identifier, cmd: cmd, content: content)
            }
        }
        if roomType == .owner && isOwner {
            if cmd == KaraokeConstants.CMD_REQUEST_TAKE_SEAT {
                recvTakeSeat(identifier: identifier, inviter: inviter, content: content)
            }
        }
    }
    
    func onInviteeAccepted(identifier: String, invitee: String) {
        if roomType == .audience {
            guard let seatIndex = mInvitationSeatDic.removeValue(forKey: identifier) else {
                return
            }
            guard let seatModel = anchorSeatList.filter({ (seatInfo) -> Bool in
                return seatInfo.seatIndex == seatIndex
            }).first else {
                return
            }
            if !seatModel.isUsed {
                // 显示Loading指示框， 回调结束消失
                self.viewResponder?.showToastActivity()
                Karaoke.enterSeat(seatIndex: seatIndex) { [weak self] (code, message) in
                    guard let `self` = self else { return }
                    // 隐藏loading指示器
                    self.viewResponder?.hiddenToastActivity()
                    if code == 0 {
                        self.viewResponder?.showToast(message: .handsupSuccessText)
                    } else {
                        self.viewResponder?.showToast(message: .handsupFailedText)
                    }
                }
            }
        }
        if roomType == .owner && isOwner {
            guard let seatInvitation = mPickSeatInvitationDic.removeValue(forKey: identifier) else {
                return
            }
            guard let seatModel = anchorSeatList.filter({ (model) -> Bool in
                return model.seatIndex == seatInvitation.seatIndex
            }).first else {
                return
            }
            if !seatModel.isUsed {
                Karaoke.pickSeat(seatIndex: seatInvitation.seatIndex, userId: seatInvitation.inviteUserId) { [weak self] (code, message) in
                    guard let `self` = self else { return }
                    if code == 0 {
                        guard let audience = self.memberAudienceDic[seatInvitation.inviteUserId] else { return }
                        self.viewResponder?.showToast(message: localizeReplaceXX(.hugHandsupSuccessText, audience.userInfo.userName))
                    }
                }
            }
        }
    }
    
    func onInviteeRejected(identifier: String, invitee: String) {
        if let seatInvitation = mPickSeatInvitationDic.removeValue(forKey: identifier) {
            guard let audience = memberAudienceDic[seatInvitation.inviteUserId] else { return }
            viewResponder?.showToast(message: localizeReplaceXX(.refuseBespeakerText, audience.userInfo.userName))
            changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: audience.userInfo)
        }
    }
    
    func onInvitationCancelled(identifier: String, invitee: String) {
        
    }
    
    func onMusicPlayCompleted(musicID: Int32) {
        effectViewModel.viewResponder?.updateMusicPanel(musicInfo: nil)
        effectViewModel.musicSelectedList.forEach { musicInfo in
            if musicInfo.performId == String(musicID) {
                musicService?.completePlaying(musicInfo: musicInfo, callback: { [weak self] _, _ in
                    guard let self = self else { return }
                    self.notiMusicListChange()
                })
            }
        }
    }
    
    func onMusicProgressUpdate(musicID: Int32, progress: Int, total: Int) {
        effectViewModel.viewResponder?.bgmOnPlaying(musicId: musicID,
                                                    current: Double(progress) / 1_000.0,
                                                    total: Double(total) / 1_000.0)
    }
    
    func onMusicAccompanimentModeChanged(musicId: String, isOrigin: Bool) {
        effectViewModel.viewResponder?.onMusicAccompanimentModeChanged(musicId: musicId,
                                                                       isOrigin: isOrigin)
    }
}

extension TRTCKaraokeViewModel: KaraokeMusicServiceObserver {
    func onMusicListChanged(musicInfoList: [KaraokeMusicInfo]) {
        effectViewModel.musicSelectedList = musicInfoList
        
        var userSelectedSong: [String:Bool] = [:]
        for musicModel in musicInfoList where musicModel.userId == loginUserId {
            userSelectedSong[musicModel.getMusicId()] = true
        }
        effectViewModel.userSelectedSong = userSelectedSong
        currentMusicModel = musicInfoList.first
        effectViewModel.viewResponder?.updateMusicPanel(musicInfo: currentMusicModel)
        if currentMusicModel?.userId == loginUserId {
            effectViewModel.viewResponder?.onStartChorusBtnClick()
        }
        effectViewModel.viewResponder?.onSelectedMusicListChanged()
    }
}

/// MARK: - internationalization string
fileprivate extension String {
    static var seatmutedText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.onseatmuted")
    }
    static var micmutedText: String {
        karaokeLocalize("Demo.TRTC.Salon.micmuted")
    }
    static var micunmutedText: String {
        karaokeLocalize("Demo.TRTC.Salon.micunmuted")
    }
    static var mutedText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.ismuted")
    }
    static var unmutedText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.isunmuted")
    }
    static var seatuninitText: String {
        karaokeLocalize("Demo.TRTC.Salon.seatlistnotinit")
    }
    static var enterSuccessText: String {
        karaokeLocalize("Demo.TRTC.Salon.enterroomsuccess")
    }
    static var enterFailedText: String {
        karaokeLocalize("Demo.TRTC.Salon.enterroomfailed")
    }
    static var createRoomFailedText: String {
        karaokeLocalize("Demo.TRTC.LiveRoom.createroomfailed")
    }
    static var meText: String {
        karaokeLocalize("Demo.TRTC.LiveRoom.me")
    }
    static var sendSuccessText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.sendsuccess")
    }
    static var sendFailedText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.sendfailedxx")
    }
    static var cupySeatSuccessText: String {
        karaokeLocalize("Demo.TRTC.Salon.hostoccupyseatsuccess")
    }
    static var cupySeatFailedText: String {
        karaokeLocalize("Demo.TRTC.Salon.hostoccupyseatfailed")
    }
    static var onlyAnchorOperationText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.onlyanchorcanoperation")
    }
    static var seatLockedText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.seatislockedandcanthandup")
    }
    static var audienceText: String {
        karaokeLocalize("Demo.TRTC.Salon.audience")
    }
    static var otherAnchorText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.otheranchor")
    }
    static var isInxxSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.isinxxseat")
    }
    static var notInitText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.seatisnotinittocanthandsup")
    }
    static var handsupText: String {
        karaokeLocalize("Demo.TRTC.Salon.handsup")
    }
    static var totaxxText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.totaxx")
    }
    static var unmuteOneText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.unmuteone")
    }
    static var muteOneText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.muteone")
    }
    static var makeAudienceText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.makeoneaudience")
    }
    static var inviteHandsupText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.invitehandsup")
    }
    static var banSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.banseat")
    }
    static var liftbanSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.liftbanseat")
    }
    static var seatBusyText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.seatisbusy")
    }
    static var sendInviteSuccessText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.sendinvitesuccess")
    }
    static var reqExpiredText: String {
        karaokeLocalize("Demo.TRTC.Salon.reqisexpired")
    }
    static var acceptReqFailedText: String {
        karaokeLocalize("Demo.TRTC.Salon.acceptreqfailed")
    }
    static var audienceSuccessText: String {
        karaokeLocalize("Demo.TRTC.Salon.audiencesuccess")
    }
    static var audienceFailedxxText: String {
        karaokeLocalize("Demo.TRTC.Salon.audiencefailedxx")
    }
    static var beingArchonText: String {
        karaokeLocalize("Demo.TRTC.Salon.isbeingarchon")
    }
    static var roomNotReadyText: String {
        karaokeLocalize("Demo.TRTC.Salon.roomnotready")
    }
    static var reqSentText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.reqsentandwaitforarchondeal")
    }
    static var reqSendFailedxxText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.reqsendfailedxx")
    }
    static var handsupSuccessText: String {
        karaokeLocalize("Demo.TRTC.Salon.successbecomespaker")
    }
    static var handsupFailedText: String {
        karaokeLocalize("Demo.TRTC.Salon.failedbecomespaker")
    }
    
    static var alertText: String {
        karaokeLocalize("Demo.TRTC.LiveRoom.prompt")
    }
    static var invitexxSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.anchorinvitexxseat")
    }
    static var refuseHandsupText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.refusehandsupreq")
    }
    static var applyxxSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.applyforxxseat")
    }
    static var closeRoomText: String {
        karaokeLocalize("Demo.TRTC.Salon.archonclosedroom")
    }
    static var seatlistWrongText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.seatlistwentwrong")
    }
    static var beyySeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.xxbeyyseat")
    }
    static var audienceyySeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.xxaudienceyyseat")
    }
    static var bemutedxxText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.xxisbemuted")
    }
    static var beunmutedxxText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.xxisbeunmuted")
    }
    static var ownerxxSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.ownerxxyyseat")
    }
    static var banText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.ban")
    }
    static var inRoomText: String {
        karaokeLocalize("Demo.TRTC.LiveRoom.xxinroom")
    }
    static var exitRoomText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.xxexitroom")
    }
    static var hugHandsupSuccessText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.hugxxhandsupsuccess")
    }
    static var refuseBespeakerText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.refusebespeaker")
    }
    static var sureToLeaveSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.alertdeleteallmusic")
    }
    static var takeSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.micon")
    }
    static var lockSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.lockseat")
    }
    static var unlockSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.unlockseat")
    }
    static var xxSeatSelectzzSongText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.xxmicyyselectzz")
    }
    static var updateNetworkSuccessedText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.updateNetworkSuccessed")
    }
    static var updateNetworkFailedText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.updateNetworkFailed")
    }
    static var updateNetworkFailedDonotEnterSeatText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.updateNetworkFailedDonotEnterSeat")
    }
    static var handupCheckNetworkText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.handupCheckNetwork")
    }
    static var audienceCheckNetworkText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.audienceCheckNetwork")
    }
    static var onlyOwnerText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.onlyownercanoperation")
    }
}

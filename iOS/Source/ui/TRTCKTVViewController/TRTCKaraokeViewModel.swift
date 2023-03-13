//
//  TRTCKaraokeViewModel.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

import Foundation
import ImSDK_Plus

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
    func changeRoom(info: RoomInfo)
    func refreshAnchorInfos()
    func onSeatMute(isMute: Bool)
    func onAnchorMute(isMute: Bool)
    func showAlert(info: (title: String, message: String), sureAction: @escaping () -> Void, cancelAction: (() -> Void)?)
    func showActionSheet(actionTitles:[String], actions: @escaping (Int) -> Void)
    func refreshMsgView()
    func msgInput(show: Bool)
    func audiceneList(show: Bool)
    func audienceListRefresh()
    func stopPlayBGM() // 停止播放音乐
    func recoveryVoiceSetting() // 恢复音效设置
    func showAudienceAlert(seat: SeatInfoModel)
    func showGiftAnimation(giftInfo: TUIGiftInfo)
    func onUpdateDownloadMusic(musicId: String)
    func showUpdateNetworkAlert(info: (isUpdateSuccessed: Bool, message: String), retryAction: (() -> Void)?, cancelAction: @escaping (() -> Void))
}

class TRTCKaraokeViewModel: NSObject {
    public var cacheSelectd: NSCache<NSString,NSString> = NSCache<NSString,NSString>()
    private let kSendGiftCmd = "0"
    private let dependencyContainer: TRTCKaraokeEnteryControl
    private let giftManager = TUIGiftManager.sharedManager()
    private var roomType: KaraokeViewType = .audience
    public weak var viewResponder: TRTCKaraokeViewResponder?
    var currentMusicModel: KaraokeMusicModel? = nil
    public weak var musicDataSource: KaraokeMusicService? {
        didSet {
            musicDataSource?.setRoomInfo(roomInfo: roomInfo)
            musicDataSource?.setServiceDelegate(self)
        }
    }
    public weak var rootVC: TRTCKaraokeViewController?
    var isOwner: Bool {
        return TRTCKaraokeIMManager.shared.curUserID == roomInfo.ownerId
    }
    var ownerID: String {
        return roomInfo.ownerId
    }
    private(set) var isSelfMute: Bool = false
    // 防止多次退房
    private var isExitingRoom: Bool = false
    
    private var isTakeSeat: Bool = false
    
    private(set) var roomInfo: RoomInfo
    private(set) var isSeatInitSuccess: Bool = false
    private(set) var mSelfSeatIndex: Int = -1
    private(set) var isOwnerMute: Bool = false
    
    // UI相关属性
    private(set) var roomOwnerID: UserInfo?
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
    
    public var userMuteMap : [String : Bool] = [:]
    
    /// NTP网络校时是否成功
    var updateNetworkSuccessed: Bool = false
    
    /// 初始化方法
    /// - Parameter container: 依赖管理容器，负责Karaoke模块的依赖管理
    init(container: TRTCKaraokeEnteryControl, roomInfo: RoomInfo, roomType: KaraokeViewType) {
        self.dependencyContainer = container
        self.roomType = roomType
        self.roomInfo = roomInfo
        super.init()
        Karaoke.setDelegate(delegate: self)
        initAnchorListData()
    }
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
    }
    
    public var Karaoke: TRTCKaraokeRoom {
        return dependencyContainer.getKaraoke()
    }
    
    public func getSeatIndexByUserId(userId:String) -> NSInteger {
        // 修改座位列表的user信息
        for index in 0..<self.anchorSeatList.count {
            let seatInfo = anchorSeatList[index]
            if seatInfo.seatInfo?.userId == userId {
                return seatInfo.seatIndex
            }
        }
        return 0
    }
    public func getSeatUserByUserId(userId:String) -> UserInfo? {
        // 修改座位列表的user信息
        for index in 0..<self.anchorSeatList.count {
            let seatInfo = anchorSeatList[index]
            if seatInfo.seatInfo?.userId == userId {
                return seatInfo.seatUser
            }
        }
        return nil
    }
    
    lazy var effectViewModel: TRTCKaraokeSoundEffectViewModel = {
        return TRTCKaraokeSoundEffectViewModel(self)
    }()
    
    func exitRoom(completion: @escaping (() -> ())) {
        guard !isExitingRoom else { return }
        musicDataSource?.onExitRoom()
        viewResponder?.popToPrevious()
        isExitingRoom = true
        if isOwner && roomType == .owner {
            dependencyContainer.destroyRoom(roomID: "\(roomInfo.roomID)", success: {
                TRTCLog.out("---deinit room success")
            }) { (code, message) in
                TRTCLog.out("---deinit room failed")
            }
            Karaoke.destroyRoom { [weak self] (code, message) in
                guard let self = self else { return }
                self.isExitingRoom = false
                completion()
            }
            return
        }
        Karaoke.exitRoom { [weak self] (code, message) in
            guard let self = self else { return }
            self.isExitingRoom = false
            completion()
        }
        updateNetworkSuccessed = false
    }
    
    public var voiceEarMonitor: Bool = false {
        willSet {
            self.Karaoke.setVoiceEarMonitor(enable: newValue)
        }
    }
    
    public func refreshView() {
        viewResponder?.switchView(type: userType)
    }
    
    public func openMessageTextInput() {
        viewResponder?.msgInput(show: true)
    }
    
    public var muteItem: IconTuple?
    
    public func muteAction(isMute: Bool) -> Bool {
        if mSelfSeatIndex > 0, mSelfSeatIndex < anchorSeatList.count, let user = anchorSeatList[mSelfSeatIndex].seatUser, !(anchorSeatList[mSelfSeatIndex].seatInfo?.mute ?? true) {
            userMuteMap[user.userId] = isMute
            viewResponder?.onAnchorMute(isMute: isMute)
        }
        guard !isOwnerMute else {
            viewResponder?.showToast(message: .seatmutedText)
            return false
        }
        isSelfMute = isMute
        Karaoke.muteLocalAudio(mute: isMute)
        if isMute {
            viewResponder?.showToast(message: .micmutedText)
        } else {
            viewResponder?.recoveryVoiceSetting()
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
    
    public func enterRoom(toneQuality: Int = KaraokeToneQuality.defaultQuality.rawValue) {
        Karaoke.enterRoom(roomID: roomInfo.roomID) { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                self.viewResponder?.showToast(message: .enterSuccessText)
                self.Karaoke.setAuidoQuality(quality: toneQuality)
                self.getAudienceList()
            } else {
                self.viewResponder?.showToast(message: .enterFailedText)
                self.viewResponder?.popToPrevious()
            }
        }
    }
    public func createRoom(toneQuality: Int = 0) {
        let faceUrl = TRTCKaraokeIMManager.shared.curUserAvatar
        Karaoke.setAuidoQuality(quality: toneQuality)
        Karaoke.setSelfProfile(userName: roomInfo.ownerName, avatarURL: faceUrl) { [weak self] (code, message) in
            guard let `self` = self else { return }
            TRTCLog.out("setSelfProfile\(code):\(message)")
            self.dependencyContainer.createRoom(roomID: "\(self.roomInfo.roomID)") {  [weak self] in
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
        let entity = MsgEntity.init(userId: TRTCKaraokeIMManager.shared.curUserID, userName: .meText, content: message, invitedId: "", type: .normal)
        notifyMsg(entity: entity)
        Karaoke.sendRoomTextMsg(message: message) { [weak self] (code, message) in
            guard let `self` = self else { return }
            self.viewResponder?.showToast(message: code == 0 ? .sendSuccessText :  localizeReplaceXX(.sendFailedText, message))
        }
    }
    
    public func acceptTakeSeat(identifier: String) {
        if let audience = memberAudienceDic[identifier] {
            acceptTakeSeatInviattion(userInfo: audience.userInfo)
        }
    }
    public func sendGift(giftId: String, callback: ActionCallback?) {
        let giftMsgInfo = TUIGiftMsgInfo.init(giftId: giftId, sendUser: TRTCKaraokeIMManager.shared.curUserName, sendUserHeadIcon: TRTCKaraokeIMManager.shared.curUserAvatar)
        do {
            let encoder = JSONEncoder.init()
            let data = try encoder.encode(giftMsgInfo)
            let message = String.init(decoding: data, as: UTF8.self)
            Karaoke.sendRoomCustomMsg(cmd: kSendGiftCmd, message: message, callback: callback)
        } catch {
            
        }
    }
    
    public func showSelectedMusic(music: KaraokeMusicModel) {
        var action: (() -> ())? = nil
        if isOwner {
            action = { [weak self] in
                guard let `self` = self else { return }
                self.effectViewModel.viewResponder?.onManageSongBtnClick()
            }
        }
        showNotifyMsg(messsage: localizeReplaceThreeCharacter(.xxSeatSelectzzSongText, "\(music.seatIndex + 1)", "xxx", music.musicName), userName: music.bookUserName, type: isOwner ? .manage_song : .normal, action: action)
    }
}

// MARK: - private method
extension TRTCKaraokeViewModel {
    
    private func internalCreateRoom() {
        let param = RoomParam.init()
        param.roomName = roomInfo.roomName
        param.needRequest = roomInfo.needRequest
        param.seatCount = roomInfo.memberCount
        param.coverUrl = roomInfo.coverUrl
        param.seatCount = 8
        param.seatInfoList = []
        for _ in 0..<param.seatCount {
            let seatInfo = SeatInfo.init()
            param.seatInfoList.append(seatInfo)
        }
        Karaoke.createRoom(roomID: Int32(roomInfo.roomID), roomParam: param) { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                self.viewResponder?.changeRoom(info: self.roomInfo)
                self.getAudienceList()
                if self.isOwner {
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
                            self.acceptTakeSeatInviattion(userInfo: userInfo)
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
                    print("=====\(model.seatIndex)")
                    self.clickSeat(model: model)
                }
            }
            model.isOwner = TRTCKaraokeIMManager.shared.curUserID == roomInfo.ownerId
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
        if model.isUsed {
            if TRTCKaraokeIMManager.shared.curUserID == model.seatUser?.userId ?? "" {
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
            if model.seatUser?.userId == TRTCKaraokeIMManager.shared.curUserID {
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
    
    private func sendInvitation(userInfo: UserInfo) {
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
        viewResponder?.audiceneList(show: false)
    }
    
    private func acceptTakeSeatInviattion(userInfo: UserInfo) {
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
            // 需要申请上麦
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
    
    private func changeAudience(status: Int, user: UserInfo) {
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
}

// MARK:- room delegate
extension TRTCKaraokeViewModel: TRTCKaraokeRoomDelegate {
    func genUserSign(userId: String, completion: @escaping (String) -> Void) {
        if let delegate = dependencyContainer.delegate {
            delegate.genUserSign(userId: userId, completion: completion)
        }
    }
    
    func onUpdateNetworkTime(errCode: Int32, message errMsg: String, retryHandler: @escaping (Bool) -> Void) {
        /*
         errCode 0 为合适参与合唱；
                 1 建议 UI 提醒当前网络不够好，可能会影响合唱效果；
                -1 需要重新校时（同样建议 UI 提醒）
         */
        if errCode == 0 || errCode == 1 {
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
        guard let musicID = Int32(musicId) else {
            return
        }
        if userType == .audience { return }
        musicDataSource?.ktvGetSelectedMusicList({ [weak self] errorCode, errorMessage, list in
            list.forEach { [weak self] musicModel in
                guard let self = self else { return }
                if musicModel.musicID == musicID {
                    self.effectViewModel.viewResponder?.showStartAnimationAndPlay(startDelay: startDelay)
                    self.effectViewModel.setVolume(music: self.effectViewModel.musicVolume)
                    self.Karaoke.startPlayMusic(musicID: musicModel.musicID,
                                                originalUrl: musicModel.contentUrl,
                                                accompanyUrl: musicModel.accompanyUrl)
                    return
                }
            }
        })
    }
    
    func onError(code: Int32, message: String) {
        
    }
    
    func onWarning(code: Int32, message: String) {
        
    }
    
    func onDebugLog(message: String) {
        
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
    
    func onRoomInfoChange(roomInfo: RoomInfo) {
        // 值为-1表示该接口没有返回数量信息
        if roomInfo.memberCount == -1 {
            roomInfo.memberCount = self.roomInfo.memberCount
        }
        self.roomInfo = roomInfo
        viewResponder?.changeRoom(info: self.roomInfo)
        musicDataSource?.setRoomInfo(roomInfo: roomInfo)
    }
    
    func onSeatListChange(seatInfoList: [SeatInfo]) {
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
            anchorSeatInfo.isOwner = roomInfo.ownerId == TRTCKaraokeIMManager.shared.curUserID
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
            return seat.userId != ""
        }).map { (seatInfo) -> String in
            return seatInfo.userId
        }
        guard seatUserIds.count > 0 else {
            viewResponder?.refreshAnchorInfos()
            return
        }
        Karaoke.getUserInfoList(userIDList: seatUserIds) { [weak self] (code, message, userInfos) in
            guard let `self` = self else { return }
            guard code == 0 else { return }
            var userdic: [String : UserInfo] = [:]
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
                if self.anchorSeatList[index].seatUser == nil, let user = userdic[seatInfo.userId], !self.userMuteMap.keys.contains(user.userId) {
                    self.userMuteMap[user.userId] = true
                }
                self.anchorSeatList[index].seatUser = userdic[seatInfo.userId]
            }
            self.viewResponder?.refreshAnchorInfos()
            self.viewResponder?.onAnchorMute(isMute: false)
        }
    }
    
    func onAnchorEnterSeat(index: Int, user: UserInfo) {
        showNotifyMsg(messsage: localizeReplace(.beyySeatText, "xxx", String(index + 1)), userName: user.userName)
        if user.userId == TRTCKaraokeIMManager.shared.curUserID {
            userType = .anchor
            refreshView()
            mSelfSeatIndex = index
            TRTCKaraokeIMManager.shared.seatIndex = index
            viewResponder?.recoveryVoiceSetting() // 自己上麦，恢复音效设置
        }
        userMuteMap[user.userId] = false
        changeAudience(status: AudienceInfoModel.TYPE_IN_SEAT, user: user)
    }
    
    func onAnchorLeaveSeat(index: Int, user: UserInfo) {
        showNotifyMsg(messsage: localizeReplace(.audienceyySeatText, "xxx", String(index + 1)), userName: user.userName)
        if user.userId == TRTCKaraokeIMManager.shared.curUserID {
            userType = .audience
            refreshView()
            mSelfSeatIndex = -1
            isOwnerMute = false
            TRTCKaraokeIMManager.shared.seatIndex = index
            // 自己下麦，停止音效播放
            effectViewModel.stopPlay()
            musicDataSource?.deleteAllMusic(userID: TRTCKaraokeIMManager.shared.curUserID, callback: { (code, msg) in
                
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
        debugPrint("seat \(index) is mute : \(isMute ? "true" : "false")")
        if isMute {
            showNotifyMsg(messsage: localizeReplaceXX(.bemutedxxText, String(index)), userName: "")
        } else {
            showNotifyMsg(messsage: localizeReplaceXX(.beunmutedxxText, String(index)), userName: "")
        }
        if index >= 0 && index <= anchorSeatList.count {
            anchorSeatList[index].seatInfo?.mute = isMute
        }
        if mSelfSeatIndex == index {
            isOwnerMute = isMute
            viewResponder?.onSeatMute(isMute: isMute)
        }
        viewResponder?.onAnchorMute(isMute: isMute)
    }
    
    func onUserMicrophoneMute(userId: String, mute: Bool) {
        userMuteMap[userId] = mute
        viewResponder?.onAnchorMute(isMute: mute)
    }
    
    func onSeatClose(index: Int, isClose: Bool) {
        showNotifyMsg(messsage: localizeReplace(.ownerxxSeatText, isClose ? .banSeatText : .unmuteOneText, String(index + 1)), userName: "")
    }
    
    func onAudienceEnter(userInfo: UserInfo) {
        showNotifyMsg(messsage: localizeReplaceXX(.inRoomText, "xxx"), userName: userInfo.userName)
        // 主播端(房主)
        let memberEntityModel = AudienceInfoModel.init(type: 0, userInfo: userInfo) { [weak self] (index) in
            guard let `self` = self else { return }
            if index == 0 {
                self.sendInvitation(userInfo: userInfo)
            } else {
                self.acceptTakeSeatInviattion(userInfo: userInfo)
                self.viewResponder?.audiceneList(show: false)
            }
        }
        if !memberAudienceDic.keys.contains(userInfo.userId) {
            memberAudienceDic[userInfo.userId] = memberEntityModel
            memberAudienceList.append(memberEntityModel)
        }
        viewResponder?.audienceListRefresh()
        changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: userInfo)
    }
    
    func onAudienceExit(userInfo: UserInfo) {
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
                volumeDic[TRTCKaraokeIMManager.shared.curUserID] = info.volume
            }
        }
        var needRefreshUI = false
        for (index, seat) in self.anchorSeatList.enumerated() {
            if let user = seat.seatUser {
                let isTalking = (volumeDic[user.userId] ?? 0) > 25
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
    
    func onRecvRoomTextMsg(message: String, userInfo: UserInfo) {
        let msgEntity = MsgEntity.init(userId: userInfo.userId,
                                       userName: userInfo.userName,
                                       content: message,
                                       invitedId: "",
                                       type: .normal)
        notifyMsg(entity: msgEntity)
    }
    
    func onRecvRoomCustomMsg(cmd: String, message: String, userInfo: UserInfo) {
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
    
    func onMusicPrepareToPlay(musicID: Int32) {
        effectViewModel.viewResponder?.bgmOnPrepareToPlay(musicId: musicID)
        musicDataSource?.prepareToPlay(musicID: String(musicID))
    }
    
    func onMusicProgressUpdate(musicID: Int32, progress: Int, total: Int) {
        effectViewModel.viewResponder?.bgmOnPlaying(musicId: musicID,
                                                    current: Double(progress) / 1_000.0,
                                                    total: Double(total) / 1_000.0)
    }
    
    func onMusicCompletePlaying(musicID: Int32) {
        effectViewModel.currentPlayingModel = nil
        musicDataSource?.completePlaying(musicID: String(musicID))
        effectViewModel.viewResponder?.bgmOnPrepareToPlay(musicId: 0)
    }
}

extension TRTCKaraokeViewModel: KaraokeMusicServiceDelegate {
    func onMusicListChange(musicInfoList: [KaraokeMusicModel], reason: Int) {
        effectViewModel.musicSelectedList = musicInfoList
        var userSelectedSong: [String:Bool] = [:]
        for musicModel in musicInfoList {
            if musicModel.music.userId == TRTCKaraokeIMManager.shared.curUserID {
                userSelectedSong[musicModel.music.getMusicId()] = true
            }
        }
        effectViewModel.userSelectedSong = userSelectedSong;
        effectViewModel.viewResponder?.onSelectedMusicListChanged()
        effectViewModel.viewResponder?.onMusicListChanged()
    }
    
    func onShouldSetLyric(musicID: String) {
        effectViewModel.viewResponder?.bgmOnPrepareToPlay(musicId: Int32(musicID) ?? 0)
    }
    
    func onShouldPlay(_ music: KaraokeMusicModel) -> Bool {
        if mSelfSeatIndex >= 0 {
            currentMusicModel = music
            effectViewModel.viewResponder?.onStartChorusBtnClick()
            return true
        }
        return false
    }
    
    func onShouldStopPlay(_ music: KaraokeMusicModel?) {
        effectViewModel.stopPlay()
    }
    
    func onShouldShowMessage(_ music: KaraokeMusicModel) {
        for seat in anchorSeatList {
            if let user = seat.seatUser, user.userId == music.music.userId {
                music.seatIndex = seat.seatIndex
                music.bookUserName = user.userName
                music.bookUserAvatar = user.userAvatar
                break
            }
        }
        showSelectedMusic(music: music)
    }
    
    func onDownloadMusicComplete(_ musicId: String) {
        TRTCLog.out("____ onDownloadMusicComplete \(musicId)")
        if let viewResponder = self.viewResponder {
            viewResponder.onUpdateDownloadMusic(musicId: musicId)
        }
    }
}

/// MARK: - internationalization string
fileprivate extension String {
    static let seatmutedText = karaokeLocalize("Demo.TRTC.Karaoke.onseatmuted")
    static let micmutedText = karaokeLocalize("Demo.TRTC.Salon.micmuted")
    static let micunmutedText = karaokeLocalize("Demo.TRTC.Salon.micunmuted")
    static let mutedText = karaokeLocalize("Demo.TRTC.Karaoke.ismuted")
    static let unmutedText = karaokeLocalize("Demo.TRTC.Karaoke.isunmuted")
    static let seatuninitText = karaokeLocalize("Demo.TRTC.Salon.seatlistnotinit")
    static let enterSuccessText = karaokeLocalize("Demo.TRTC.Salon.enterroomsuccess")
    static let enterFailedText = karaokeLocalize("Demo.TRTC.Salon.enterroomfailed")
    static let createRoomFailedText = karaokeLocalize("Demo.TRTC.LiveRoom.createroomfailed")
    static let meText = karaokeLocalize("Demo.TRTC.LiveRoom.me")
    static let sendSuccessText = karaokeLocalize("Demo.TRTC.Karaoke.sendsuccess")
    static let sendFailedText = karaokeLocalize("Demo.TRTC.Karaoke.sendfailedxx")
    static let cupySeatSuccessText = karaokeLocalize("Demo.TRTC.Salon.hostoccupyseatsuccess")
    static let cupySeatFailedText = karaokeLocalize("Demo.TRTC.Salon.hostoccupyseatfailed")
    static let onlyAnchorOperationText = karaokeLocalize("Demo.TRTC.Karaoke.onlyanchorcanoperation")
    static let seatLockedText = karaokeLocalize("Demo.TRTC.Karaoke.seatislockedandcanthandup")
    static let audienceText = karaokeLocalize("Demo.TRTC.Salon.audience")
    static let otherAnchorText = karaokeLocalize("Demo.TRTC.Karaoke.otheranchor")
    static let isInxxSeatText = karaokeLocalize("Demo.TRTC.Karaoke.isinxxseat")
    static let notInitText = karaokeLocalize("Demo.TRTC.Karaoke.seatisnotinittocanthandsup")
    static let handsupText = karaokeLocalize("Demo.TRTC.Salon.handsup")
    static let totaxxText = karaokeLocalize("Demo.TRTC.Karaoke.totaxx")
    static let unmuteOneText = karaokeLocalize("Demo.TRTC.Karaoke.unmuteone")
    static let muteOneText = karaokeLocalize("Demo.TRTC.Karaoke.muteone")
    static let makeAudienceText = karaokeLocalize("Demo.TRTC.Karaoke.makeoneaudience")
    static let inviteHandsupText = karaokeLocalize("Demo.TRTC.Karaoke.invitehandsup")
    static let banSeatText = karaokeLocalize("Demo.TRTC.Karaoke.banseat")
    static let liftbanSeatText = karaokeLocalize("Demo.TRTC.Karaoke.liftbanseat")
    static let seatBusyText = karaokeLocalize("Demo.TRTC.Karaoke.seatisbusy")
    static let sendInviteSuccessText = karaokeLocalize("Demo.TRTC.Karaoke.sendinvitesuccess")
    static let reqExpiredText = karaokeLocalize("Demo.TRTC.Salon.reqisexpired")
    static let acceptReqFailedText = karaokeLocalize("Demo.TRTC.Salon.acceptreqfailed")
    static let audienceSuccessText = karaokeLocalize("Demo.TRTC.Salon.audiencesuccess")
    static let audienceFailedxxText = karaokeLocalize("Demo.TRTC.Salon.audiencefailedxx")
    static let beingArchonText = karaokeLocalize("Demo.TRTC.Salon.isbeingarchon")
    static let roomNotReadyText = karaokeLocalize("Demo.TRTC.Salon.roomnotready")
    static let reqSentText = karaokeLocalize("Demo.TRTC.Karaoke.reqsentandwaitforarchondeal")
    static let reqSendFailedxxText = karaokeLocalize("Demo.TRTC.Karaoke.reqsendfailedxx")
    static let handsupSuccessText = karaokeLocalize("Demo.TRTC.Salon.successbecomespaker")
    static let handsupFailedText = karaokeLocalize("Demo.TRTC.Salon.failedbecomespaker")
    
    static let alertText = karaokeLocalize("Demo.TRTC.LiveRoom.prompt")
    static let invitexxSeatText = karaokeLocalize("Demo.TRTC.Karaoke.anchorinvitexxseat")
    static let refuseHandsupText = karaokeLocalize("Demo.TRTC.Karaoke.refusehandsupreq")
    static let applyxxSeatText = karaokeLocalize("Demo.TRTC.Karaoke.applyforxxseat")
    static let closeRoomText = karaokeLocalize("Demo.TRTC.Salon.archonclosedroom")
    static let seatlistWrongText = karaokeLocalize("Demo.TRTC.Karaoke.seatlistwentwrong")
    static let beyySeatText = karaokeLocalize("Demo.TRTC.Karaoke.xxbeyyseat")
    static let audienceyySeatText = karaokeLocalize("Demo.TRTC.Karaoke.xxaudienceyyseat")
    static let bemutedxxText = karaokeLocalize("Demo.TRTC.Karaoke.xxisbemuted")
    static let beunmutedxxText = karaokeLocalize("Demo.TRTC.Karaoke.xxisbeunmuted")
    static let ownerxxSeatText = karaokeLocalize("Demo.TRTC.Karaoke.ownerxxyyseat")
    static let banText = karaokeLocalize("Demo.TRTC.Karaoke.ban")
    static let inRoomText = karaokeLocalize("Demo.TRTC.LiveRoom.xxinroom")
    static let exitRoomText = karaokeLocalize("Demo.TRTC.Karaoke.xxexitroom")
    static let hugHandsupSuccessText = karaokeLocalize("Demo.TRTC.Karaoke.hugxxhandsupsuccess")
    static let refuseBespeakerText = karaokeLocalize("Demo.TRTC.Karaoke.refusebespeaker")
    static let sureToLeaveSeatText = karaokeLocalize("Demo.TRTC.Karaoke.alertdeleteallmusic")
    static let takeSeatText = karaokeLocalize("Demo.TRTC.Karaoke.micon")
    static let lockSeatText = karaokeLocalize("Demo.TRTC.Karaoke.lockseat")
    static let unlockSeatText = karaokeLocalize("Demo.TRTC.Karaoke.unlockseat")
    static let xxSeatSelectzzSongText = karaokeLocalize("Demo.TRTC.Karaoke.xxmicyyselectzz")
    static let updateNetworkSuccessedText = karaokeLocalize("Demo.TRTC.Karaoke.updateNetworkSuccessed")
    static let updateNetworkFailedText = karaokeLocalize("Demo.TRTC.Karaoke.updateNetworkFailed")
}

//
//  TRTCCreateKaraokeViewModel.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

import TUICore
import UIKit

public enum KaraokeRole {
    case anchor // 主播
    case audience // 观众
}

public enum KaraokeToneQuality: Int {
    case speech = 1
    case defaultQuality
    case music
}

protocol TRTCCreateKaraokeViewResponder: AnyObject {
    func showToast(message: String)
}

protocol TRTCCreateKaraokeNavigator: NSObject {
    func push(viewController: UIViewController)
    func popViewController()
}

class TRTCCreateKaraokeViewModel {
    private let dependencyContainer: TRTCKaraokeEnteryControl
    
    weak var viewResponder: TRTCCreateKaraokeViewResponder?
    weak var navigator: TRTCCreateKaraokeNavigator?
    
    var Karaoke: TRTCKaraokeRoom {
        return dependencyContainer.getKaraoke()
    }
    
    var screenShot: UIView?
    
    var roomName: String = ""
    
    var userID: String {
        return TUILogin.getUserID() ?? ""
    }
    
    var userSign: String {
        return TUILogin.getUserSig() ?? ""
    }
    
    var userName: String {
        return TUILogin.getNickName() ?? ""
    }
    
    var sdkAppId: Int32 {
        return TUILogin.getSdkAppID()
    }
    
    var needRequest: Bool = true
    
    /// 初始化方法
    /// - Parameter container: 依赖管理容器，负责Karaoke模块的依赖管理
    init(container: TRTCKaraokeEnteryControl) {
        dependencyContainer = container
    }
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
    }
    
    private func randomBgImageLink() -> String {
        let random = arc4random() % 12 + 1
        return "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover\(random).png"
    }
    
    func createRoom() {
        let userId = userID
        let coverAvatar = randomBgImageLink()
        let roomId = getRoomId()
        let roomInfo = KaraokeRoomInfo(roomID: "\(roomId)", ownerId: userId, memberCount: 8)
        roomInfo.ownerName = userName
        roomInfo.cover = coverAvatar
        roomInfo.roomName = roomName
        roomInfo.needRequest = needRequest ? 1 : 0
        if TRTCKaraokeFloatingWindowManager.shared().windowIsShowing {
            TRTCKaraokeFloatingWindowManager.shared().closeWindowAndExitRoom { [weak self] in
                guard let `self` = self else { return }
                self.loginAndCreateKaraokeRoom(roomInfo: roomInfo)
            }
        } else {
            self.loginAndCreateKaraokeRoom(roomInfo: roomInfo)
        }
    }
    
    func loginAndCreateKaraokeRoom(roomInfo: KaraokeRoomInfo) {
        Karaoke.login(sdkAppID: sdkAppId, userId: userID, userSig: userSign) { [weak self] code, message in
            guard let self = self else { return }
            if code == 0 {
                let vc = self.dependencyContainer.makeKaraokeViewController(roomInfo: roomInfo,
                                                                            role: .owner)
                self.navigator?.push(viewController: vc)
            } else {
                self.viewResponder?.showToast(message: karaokeLocalize("Demo.TRTC.LiveRoom.createroomfailed"))
            }
        }
    }
    
    func getRoomId() -> Int {
        let userId = userID
        let result = "\(userId)_karaoke_room".hash & 0x7FFFFFFF
        TRTCLog.out("hashValue:room id:\(result), userId: \(userId)")
        return result
    }
    
    func popViewController() {
        navigator?.popViewController()
    }
}

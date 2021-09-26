//
//  TRTCCreateKaraokeViewModel.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

import ImSDK_Plus
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
    func push(viewController: UIViewController)
}

class TRTCCreateKaraokeViewModel {
    private let dependencyContainer: TRTCKaraokeEnteryControl

    public weak var viewResponder: TRTCCreateKaraokeViewResponder?

    public weak var musicDataSource: KaraokeMusicService?

    var Karaoke: TRTCKaraokeRoom {
        return dependencyContainer.getKaraoke()
    }

    var screenShot: UIView?

    var roomName: String = ""
    var userName: String {
        return TRTCKaraokeIMManager.shared.curUserName
    }

    var userID: String {
        return V2TIMManager.sharedInstance()?.getLoginUser() ?? ""
    }

    var needRequest: Bool = true
    var toneQuality: KaraokeToneQuality = .defaultQuality

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
        let roomInfo = RoomInfo(roomID: roomId, ownerId: userId, memberCount: 8)
        roomInfo.ownerName = userName
        roomInfo.coverUrl = coverAvatar
        roomInfo.roomName = roomName
        roomInfo.needRequest = needRequest
        guard let musicDataSource = musicDataSource else {
            return
        }
        if TRTCKaraokeFloatingWindowManager.shared().windowIsShowing {
            TRTCKaraokeFloatingWindowManager.shared().closeWindowAndExitRoom { [weak self] in
                guard let `self` = self else { return }
                let vc = self.dependencyContainer.makeKaraokeViewController(roomInfo: roomInfo, role: .owner, toneQuality: self.toneQuality, musicDataSource: musicDataSource)
                self.viewResponder?.push(viewController: vc)
            }
        } else {
            let vc = dependencyContainer.makeKaraokeViewController(roomInfo: roomInfo, role: .owner, toneQuality: toneQuality, musicDataSource: musicDataSource)
            viewResponder?.push(viewController: vc)
        }
    }

    func getRoomId() -> Int {
        let userId = userID
        let result = "\(userId)_voice_room".hash & 0x7FFFFFFF
        TRTCLog.out("hashValue:room id:\(result), userId: \(userId)")
        return result
    }
}

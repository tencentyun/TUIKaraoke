//
//  TRTCKaraokeEnteryControl.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

import UIKit

public protocol TRTCKaraokeEnteryControlDelegate: NSObject {
    func ktvCreateRoom(roomId: String, success: @escaping () -> Void, failed: @escaping (Int32, String) -> Void)
    func ktvDestroyRoom(roomId: String, success: @escaping () -> Void, failed: @escaping (Int32, String) -> Void)
}

/// ViewModel可视为MVC架构中的Controller层
/// 负责语音聊天室控制器和ViewModel依赖注入，以及公用参数的传递
/// ViewModel、ViewController
/// 注意：该类负责生成所有UI层的ViewController、ViewModel。慎重持有ui层的成员变量，否则很容易发生循环引用。持有成员变量时要慎重！！！！
public class TRTCKaraokeEnteryControl: NSObject {
    
    public weak var delegate: TRTCKaraokeEnteryControlDelegate?
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
    }
    
    /*
     TRTCKaraoke为可销毁单例。
     在Demo中，可以通过shardInstance（OC）shared（swift）获取或生成单例对象
     销毁单例对象后，需要再次调用sharedInstance接口重新生成实例。
     该方法在KaraokeListRoomViewModel、CreateKaraokeViewModel、KaraokeViewModel中调用。
     由于是可销毁单例，将对象生成防止在这里的目的为统一管理单例生成路径，方便维护
     */
    private var Karaoke: TRTCKaraokeRoom?
    /// 获取Karaoke
    /// - Returns: 返回Karaoke单例
    public func getKaraoke() -> TRTCKaraokeRoom {
        if let room = Karaoke {
            return room
        }
        Karaoke = TRTCKaraokeRoom.shared()
        return Karaoke!
    }
    /*
     在无需使用Karaoke的场景，可以将单例对象销毁。
     例如：退出登录时。
     在本Demo中没有调用到改销毁方法。
    */
    /// 销毁Karaoke单例
    func clearKaraoke() {
        TRTCKaraokeRoom.destroyShared()
        Karaoke = nil
    }
    
    /// 创建语聊房页面
    /// - Returns: 创建语聊房VC
    public func makeCreateKaraokeViewController(musicDataSource: KaraokeMusicService) -> UIViewController {
        let vc = TRTCCreateKaraokeViewController.init(dependencyContainer: self, musicDataSource: musicDataSource)
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
    
    /// Karaoke
    /// - Parameters:
    ///   - roomInfo: 要进入或者创建的房间参数
    ///   - role: 角色：观众 主播
    /// - Returns: 返回语聊房控制器
    public func makeKaraokeViewController(roomInfo: RoomInfo, role: KaraokeViewType, toneQuality:KaraokeToneQuality = .music, musicDataSource: KaraokeMusicService) -> UIViewController {
        return TRTCKaraokeViewController.init(viewModelFactory: self, roomInfo: roomInfo, role: role, toneQuality: toneQuality, musicDataSource: musicDataSource)
    }
}

extension TRTCKaraokeEnteryControl: TRTCKaraokeViewModelFactory {
    
    /// 创建语聊房视图逻辑层（MVC中的C，MVVM中的ViewModel）
    /// - Returns: 创建语聊房页面的ViewModel
    func makeCreateKaraokeViewModel() -> TRTCCreateKaraokeViewModel {
        return TRTCCreateKaraokeViewModel.init(container: self)
    }
    
    /// 语聊房视图逻辑层（MVC中的C，MVVM中的ViewModel）
    /// - Parameters:
    ///   - roomInfo: 语聊房信息
    ///   - roomType: 角色
    /// - Returns: 语聊房页面的ViewModel
    func makeKaraokeViewModel(roomInfo: RoomInfo, roomType: KaraokeViewType) -> TRTCKaraokeViewModel {
        return TRTCKaraokeViewModel.init(container: self, roomInfo: roomInfo, roomType: roomType)
    }
}

extension TRTCKaraokeEnteryControl {

    public func createRoom(roomID: String, success: @escaping () -> Void, failed: @escaping (Int32, String) -> Void) {
        if let delegate = self.delegate {
            delegate.ktvCreateRoom(roomId: roomID, success: success, failed: failed)
        }
    }

    public func destroyRoom(roomID: String, success: @escaping () -> Void, failed: @escaping (Int32, String) -> Void) {
        if let delegate = self.delegate {
            delegate.ktvDestroyRoom(roomId: roomID, success: success, failed: failed)
        }
    }

}

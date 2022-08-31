//
//  KaraokeMainViewController.swift
//  TUIKaraokeApp
//
//  Created by gg on 2021/7/20.
//

import UIKit
import ImSDK_Plus
import Toast_Swift
import TUIKaraoke

class KaraokeMainViewController: UIViewController {
    
    let rootView = KaraokeMainRootView.init(frame: .zero)
    
    let dependencyContainer = TRTCKaraokeEnteryControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = .naviTitleText
        navigationController?.navigationBar.barTintColor = .white
        setupViewHierarchy()
        initNavigationItemTitleView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

}

extension KaraokeMainViewController {
    private func setupViewHierarchy() {
        rootView.frame = view.bounds
        rootView.backgroundColor = .white
        rootView.delegate = self
        view = rootView
    }
    
    private func initNavigationItemTitleView() {
        let titleView = UILabel()
        titleView.text = .videoInteractionText
        titleView.textColor = .black
        titleView.textAlignment = .center
        titleView.font = UIFont.boldSystemFont(ofSize: 17)
        titleView.adjustsFontSizeToFitWidth = true
        let width = titleView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
        titleView.frame = CGRect(origin:CGPoint.zero, size:CGSize(width: width, height: 500))
        self.navigationItem.titleView = titleView
        
        let isCdnMode = ((UserDefaults.standard.object(forKey: "liveRoomConfig_useCDNFirst") as? Bool) ?? false)
        let rightCDN = UIBarButtonItem()
        if isCdnMode {
            rightCDN.title = "CDN模式"
        } else {
            rightCDN.title = ""
        }
        
        let helpBtn = UIButton(type: .custom)
        helpBtn.setImage(UIImage.init(named: "help_small"), for: .normal)
        helpBtn.addTarget(self, action: #selector(connectWeb), for: .touchUpInside)
        helpBtn.sizeToFit()
        let rightItem = UIBarButtonItem(customView: helpBtn)
        rightItem.tintColor = .black
        navigationItem.rightBarButtonItems = [rightItem, rightCDN]
        
        let backBtn = UIButton(type: .custom)
        backBtn.setImage(UIImage.init(named: "liveroom_back"), for: .normal)
        backBtn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        backBtn.sizeToFit()
        let backItem = UIBarButtonItem(customView: backBtn)
        backItem.tintColor = .black
        navigationItem.leftBarButtonItem = backItem
    }
    
}

extension KaraokeMainViewController {
    @objc func backBtnClick() {
        let alertVC = UIAlertController.init(title:
         TRTCKaraokeLocalize("App.PortalViewController.areyousureloginout"), message: nil,
         preferredStyle: .alert)
        let cancelAction = UIAlertAction.init(title: TRTCKaraokeLocalize("App.PortalViewController.cancel"), style: .cancel, handler: nil)
        let sureAction = UIAlertAction.init(title: TRTCKaraokeLocalize("App.PortalViewController.determine"), style: .default) { (action) in
            ProfileManager.shared.removeLoginCache()
            TRTCKaraokeRoom.shared().logout { (code, desc) in
                if code == 0 {
                    AppUtils.shared.appDelegate.showLoginViewController()
                } else {
                    debugPrint("logout error code: \(code) desc: \(desc)")
                }
            }
        }
        alertVC.addAction(cancelAction)
        alertVC.addAction(sureAction)
        present(alertVC, animated: true, completion: nil)
    }
    
    @objc func connectWeb() {
        if let url = URL(string: "https://cloud.tencent.com/document/product/647/59402") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension KaraokeMainViewController: KaraokeMainRootViewDelegate {
    func enterRoom(roomId: String) {
        V2TIMManager.sharedInstance().getGroupsInfo([roomId]) { [weak self] groupInfos in
            guard let `self` = self else { return }
            guard let groupInfo = groupInfos?.first else { return }
            if groupInfo.resultCode == 0 {
                guard let introduction = groupInfo.info.introduction else { return }
                let info = RoomInfo.init(roomID: Int(roomId) ?? 0, ownerId: introduction, memberCount: 0)
                let vc = self.dependencyContainer.makeKaraokeViewController(roomInfo: info, role:
                 .audience, toneQuality: .music, musicDataSource: KaraokeMusicImplement())
                self.navigationController?.pushViewController(vc, animated: false)
            } else {
                DispatchQueue.main.async {
                    let alertVC = UIAlertController.init(title: .promptText, message: .roomdoesnotexistText, preferredStyle: .alert)
                    let alertAction = UIAlertAction.init(title: .okText, style: .default, handler: nil)
                    alertVC.addAction(alertAction)
                    self.present(alertVC, animated: true, completion: nil)
                }
            }
        } fail: { code, message in
            debugPrint("code = \(code), message = \(message ?? "")")
        }
    }
    
    func createRoom() {
        dependencyContainer.delegate = self
        let viewController = dependencyContainer.makeCreateKaraokeViewController(musicDataSource: KaraokeMusicImplement())
        if viewController is TRTCCreateKaraokeViewController {
            let vc = viewController as! TRTCCreateKaraokeViewController
            vc.screenShot = view.snapshotView(afterScreenUpdates: false)
        }
        navigationController?.pushViewController(viewController, animated: false)
    }
    
    private func alert(roomId: String, handle: @escaping () -> Void) {
        let alertVC = UIAlertController.init(title: .promptText, message: .roomNumberisText + roomId, preferredStyle: .alert)
        let alertAction = UIAlertAction.init(title: .okText, style: .default) { _ in
            handle()
        }
        alertVC.addAction(alertAction)
        if let keyWindow = SceneDelegate.getCurrentWindow() {
            keyWindow.rootViewController?.present(alertVC, animated: true, completion: nil)
        }
    }
}

extension KaraokeMainViewController: TRTCKaraokeEnteryControlDelegate {
    func ktvCreateRoom(roomId: String, success: @escaping () -> Void, failed: @escaping (Int32, String) -> Void) {
        alert(roomId: roomId) {
            success()
        }
    }
    
    func ktvDestroyRoom(roomId: String, success: @escaping () -> Void, failed: @escaping (Int32, String) -> Void) {
        success()
    }
}

extension String {
    static let naviTitleText = TRTCKaraokeLocalize("Demo.TRTC.Karaoke.voicechatroom")
    static let videoInteractionText = TRTCKaraokeLocalize("Demo.TRTC.Karaoke.voicechatroom")
    static let promptText = TRTCKaraokeLocalize("Demo.TRTC.LiveRoom.prompt")
    static let okText = TRTCKaraokeLocalize("Demo.TRTC.LiveRoom.ok")
    static let roomNumberisText = TRTCKaraokeLocalize("Demo.TRTC.LiveRoom.roomNumberis:")
    static let roomdoesnotexistText = TRTCKaraokeLocalize("Demo.TRTC.LiveRoom.roomdoesnotexist")
}

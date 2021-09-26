//
//  TRTCKaraokeViewController.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/8.
//Copyright © 2020 tencent. All rights reserved.
//
import UIKit

protocol TRTCKaraokeViewModelFactory {
   func makeKaraokeViewModel(roomInfo: RoomInfo, roomType: KaraokeViewType) -> TRTCKaraokeViewModel
}

/// TRTC voice room 聊天室
public class TRTCKaraokeViewController: UIViewController {
    // MARK: - properties:
    let viewModelFactory: TRTCKaraokeViewModelFactory
    let roomInfo: RoomInfo
    let role: KaraokeViewType
    var viewModel: TRTCKaraokeViewModel?
    let toneQuality: KaraokeToneQuality
    let musicDataSource: KaraokeMusicService
    // MARK: - Methods:
    init(viewModelFactory: TRTCKaraokeViewModelFactory, roomInfo: RoomInfo, role: KaraokeViewType, toneQuality: KaraokeToneQuality = .music, musicDataSource: KaraokeMusicService) {
        self.viewModelFactory = viewModelFactory
        self.roomInfo = roomInfo
        self.role = role
        self.toneQuality = toneQuality
        self.musicDataSource = musicDataSource
        KaraokeMusicCacheDelegate.musicDataSource = musicDataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - life cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let model = viewModel else { return }
        if model.isOwner {
            model.createRoom(toneQuality: toneQuality.rawValue)
        } else {
            model.enterRoom()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.refreshView()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    public override func loadView() {
        // Reload view in this function
        let viewModel = viewModelFactory.makeKaraokeViewModel(roomInfo: roomInfo, roomType: role)
        let rootView = TRTCKaraokeRootView.init(viewModel: viewModel)
        rootView.rootViewController = self
        viewModel.viewResponder = rootView
        viewModel.rootVC = self
        viewModel.musicDataSource = musicDataSource
        self.viewModel = viewModel
        view = rootView
    }
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
    }
}

extension TRTCKaraokeViewController {
    func presentAlert(title: String, message: String, sureAction:@escaping () -> Void) {
        let alertVC = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let alertOKAction = UIAlertAction.init(title: .confirmText, style: .default) { (action) in
            alertVC.dismiss(animated: true, completion: nil)
            sureAction()
        }
        let alertCancelAction = UIAlertAction.init(title: .cancelText, style: .cancel) { (action) in
            alertVC.dismiss(animated: true, completion: nil)
        }
        alertVC.addAction(alertCancelAction)
        alertVC.addAction(alertOKAction)
        present(alertVC, animated: true, completion: nil)
    }
}

private extension String {
    static let exitText = KaraokeLocalize("Demo.TRTC.Karaoke.exit")
    static let sureToExitText = KaraokeLocalize("Demo.TRTC.Karaoke.isvoicingandsuretoexit")
    static let confirmText = KaraokeLocalize("Demo.TRTC.LiveRoom.confirm")
    static let cancelText = KaraokeLocalize("Demo.TRTC.LiveRoom.cancel")
}



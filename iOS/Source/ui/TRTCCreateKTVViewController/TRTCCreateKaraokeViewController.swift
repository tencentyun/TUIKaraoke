//
//  TRTCCreateKaraokeViewController.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

import UIKit
import SnapKit

public class TRTCCreateKaraokeViewController: UIViewController {
    // 依赖管理者
    let dependencyContainer: TRTCKaraokeEnteryControl
    let musicDataSource: KaraokeMusicService
    init(dependencyContainer: TRTCKaraokeEnteryControl, musicDataSource: KaraokeMusicService) {
        self.dependencyContainer = dependencyContainer
        self.musicDataSource = musicDataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
    }
    
    public var screenShot : UIView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = .controllerTitle
        
        let backBtn = UIButton(type: .custom)
        backBtn.setImage(UIImage(named: "navigationbar_back", in: karaokeBundle(), compatibleWith: nil), for: .normal)
        backBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        backBtn.sizeToFit()
        let backItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = backItem
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    public override func loadView() {
        let KaraokeModel = dependencyContainer.makeCreateKaraokeViewModel()
        KaraokeModel.screenShot = screenShot
        let rootView = TRTCCreateKaraokeRootView.init(viewModel: KaraokeModel)
        KaraokeModel.viewResponder = rootView
        KaraokeModel.musicDataSource = musicDataSource
        rootView.rootViewController = self
        view = rootView
        
    }
    
    /// 取消
    @objc func cancel() {
        navigationController?.popViewController(animated: true)
    }
}

private extension String {
    static let controllerTitle = karaokeLocalize("Demo.TRTC.Karaoke.createvoicechatroom")
}


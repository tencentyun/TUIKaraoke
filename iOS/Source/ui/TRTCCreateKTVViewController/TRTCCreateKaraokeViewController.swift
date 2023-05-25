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
    init(dependencyContainer: TRTCKaraokeEnteryControl) {
        self.dependencyContainer = dependencyContainer
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
        KaraokeModel.navigator = self
        view = rootView
    }
    
    /// 取消
    @objc func cancel() {
        navigationController?.popViewController(animated: true)
    }
}

extension TRTCCreateKaraokeViewController: TRTCCreateKaraokeNavigator {
    func push(viewController: UIViewController) {
        navigationController?.popViewController(animated: false)
        if let mainNavi = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController as? UINavigationController {
            mainNavi.pushViewController(viewController, animated: true)
        }
    }
    
    func popViewController() {
        navigationController?.popViewController(animated: false)
    }
}

private extension String {
    static var controllerTitle: String {
        karaokeLocalize("Demo.TRTC.Karaoke.createvoicechatroom")
    }
}


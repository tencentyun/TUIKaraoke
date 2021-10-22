//
//  TRTCLoginViewController.swift
//  TXLiteAVDemo
//
//  Created by gg on 2021/4/7.
//  Copyright © 2021 Tencent. All rights reserved.
//

import Foundation
import Toast_Swift
import WebKit

class TRTCLoginViewController: UIViewController {
    
    let loading = UIActivityIndicatorView.init(style: .large)
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(loading)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ToastManager.shared.position = .center
        view.addSubview(loading)
        loading.snp.makeConstraints { (make) in
            make.width.height.equalTo(40)
            make.centerX.centerY.equalTo(view)
        }
        loginToken()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    var verifySuccessBlock: ((_ ticket: String, _ random: String) -> ())?
    var verifyFailedBlock: ((_ message: String) -> ())?
    func login(phone: String) {
        loading.startAnimating()
        HttpLogicRequest.oauthSignature(phone: phone,success:{  [weak self] (userModel) in
            guard let self = self else { return }
            ProfileManager.sharedManager().updateUserModel(userModel)
            self.loginSucc()
        } ,failed: { [weak self] (errorCode,errorMessage) in
            guard let self = self else { return }
            self.loading.stopAnimating()
            self.view.makeToast(errorMessage)
        })
    }
    
    func loginToken() {
        if let userModel = ProfileManager.sharedManager().currentUserModel {
            loading.startAnimating()
            HttpLogicRequest.userLoginToken(userId: userModel.userId, token: userModel.token, success: { data in
                AppUtils.shared.appDelegate.showMainViewController()
            } ,failed: { [weak self] (errorCode,errorMessage) in
                guard let self = self else { return }
                self.loading.stopAnimating()
                self.view.makeToast(errorMessage)
            })
        }
    }
    
    func loginSucc() {
        if ProfileManager.sharedManager().currentUserModel?.name.count == 0 {
            self.loading.stopAnimating()
            showRegisterVC()
        } else {
            view.makeToast(TRTCKaraokeLocalize("V2.Live.LinkMicNew.loginsuccess"))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loading.stopAnimating()
                AppUtils.shared.appDelegate.showMainViewController()
            }
        }
    }
    
    func showRegisterVC() {
        let vc = TRTCRegisterViewController.init()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func loadView() {
        super.loadView()
        let rootView = TRTCLoginRootView()
        rootView.rootVC = self
        view = rootView
    }
}


extension String {
    static let verifySuccessStr = "verifySuccess"
    static let verifyCancelStr = "verifyCancel"
    static let verifyErrorStr = "verifyError"
}

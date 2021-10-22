//
//  TRTCRegisterRootView.swift
//  TXLiteAVDemo
//
//  Created by gg on 2021/4/8.
//  Copyright © 2021 Tencent. All rights reserved.
//

import UIKit
import TXAppBasic

class TRTCRegisterRootView: UIView {
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = UIColor(hex: "333333") ?? .black
        label.text = .titleText
        return label
    }()
    
    lazy var headImageViewBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 50
        btn.clipsToBounds = true
        btn.adjustsImageWhenHighlighted = false
        return btn
    }()
    
    lazy var textField: UITextField = {
        let textField = createTextField(.nicknamePlaceholderText)
        return textField
    }()
    
    lazy var textFieldSpacingLine: UIView = {
        let view = createSpacingLine()
        return view
    }()
    
    lazy var descLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 16)
        label.textColor = .darkGray
        label.text = .descText
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var registBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(.registText, for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.setBackgroundImage(UIColor(hex: "006EFF")?.trans2Image(), for: .normal)
        btn.titleLabel?.font = UIFont(name: "PingFangSC-Medium", size: 18)
        btn.layer.shadowColor = UIColor(hex: "006EFF")?.cgColor ?? UIColor.blue.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 6)
        btn.layer.shadowRadius = 16
        btn.layer.shadowOpacity = 0.4
        btn.layer.masksToBounds = true
        btn.isEnabled = false
        return btn
    }()
    
    private var nickNameArray: [String] = [TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.Martijn"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.irfan"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.Rosanna"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.Franklyn"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.Maren"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.bartel"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.Marianita"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.Anneke"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.elmira"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.ivet"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.clinton"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.virelai"),
                                           TRTCKaraokeLocalize("Demo.TRTC.LoginMock.nickname.Ace")]
    
    private func createTextField(_ placeholder: String) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.backgroundColor = .white
        textField.font = UIFont(name: "PingFangSC-Regular", size: 16)
        textField.textColor = UIColor(hex: "333333")
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.font : UIFont(name: "PingFangSC-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : UIColor(hex: "BBBBBB") ?? .gray])
        textField.delegate = self
        textField.text = nickNameArray.randomElement()!
        return textField
    }
    
    private func createSpacingLine() -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor(hex: "EEEEEE")
        return view
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        registBtn.layer.cornerRadius = registBtn.frame.height * 0.5
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        textField.resignFirstResponder()
        UIView.animate(withDuration: 0.3) {
            self.transform = .identity
        }
        checkRegistBtnState()
    }
    
    public weak var rootVC: TRTCRegisterViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameChange(noti:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardFrameChange(noti : Notification) {
        guard let info = noti.userInfo else {
            return
        }
        guard let value = info[UIResponder.keyboardFrameEndUserInfoKey], value is CGRect else {
            return
        }
        guard let superview = textField.superview else {
            return
        }
        let rect = value as! CGRect
        let converted = superview.convert(textField.frame, to: self)
        if rect.intersects(converted) {
            transform = CGAffineTransform(translationX: 0, y: -converted.maxY+rect.minY)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var isViewReady = false
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else {
            return
        }
        isViewReady = true
        constructViewHierarchy()
        activateConstraints()
        bindInteraction()
        
        if let url = URL.init(string: ProfileManager.sharedManager().currentUserModel?.avatar ?? "") {
            headImageViewBtn.kf.setImage(with: .network(url), for: .normal)
        }
        else {
            let model = TRTCAlertViewModel()
            let randomAvatar = model.avatarListDataSource[Int(arc4random())%model.avatarListDataSource.count]
            
            if  let userModel = ProfileManager.sharedManager().currentUserModel {
                IMLogicRequest.synchronizUserInfo(currentUserModel: userModel, avatar: randomAvatar.url,success: { (user) in
                    debugPrint("set IM avatar success")
                } ,failed: { (code, message) in
                    debugPrint("set IM avatar errorStr: \(message ?? ""), errorCode: \(code)")
                })
            }
            if let url = URL.init(string: randomAvatar.url) {
                headImageViewBtn.kf.setImage(with: .network(url), for: .normal)
            }
        }
    }
    
    func constructViewHierarchy() {
        addSubview(titleLabel)
        addSubview(headImageViewBtn)
        addSubview(textField)
        addSubview(textFieldSpacingLine)
        addSubview(descLabel)
        addSubview(registBtn)
        checkRegistBtnState(textField.text?.count ?? -1)
    }
    func activateConstraints() {
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(kDeviceSafeTopHeight+10)
        }
        headImageViewBtn.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.size.equalTo(CGSize(width: 100, height: 100))
        }
        textField.snp.makeConstraints { (make) in
            make.top.equalTo(headImageViewBtn.snp.bottom).offset(convertPixel(h: 40))
            make.leading.equalToSuperview().offset(convertPixel(w: 40))
            make.trailing.equalToSuperview().offset(-convertPixel(w: 40))
            make.height.equalTo(convertPixel(h: 57))
        }
        textFieldSpacingLine.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalTo(textField)
            make.height.equalTo(1)
        }
        descLabel.snp.makeConstraints { (make) in
            make.top.equalTo(textField.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(convertPixel(w: 40))
            make.trailing.lessThanOrEqualToSuperview().offset(convertPixel(w: -40))
        }
        registBtn.snp.makeConstraints { (make) in
            make.top.equalTo(descLabel.snp.bottom).offset(convertPixel(h: 40))
            make.leading.equalToSuperview().offset(convertPixel(w: 20))
            make.trailing.equalToSuperview().offset(-convertPixel(w: 20))
            make.height.equalTo(convertPixel(h: 52))
        }
    }
    func bindInteraction() {
        registBtn.addTarget(self, action: #selector(registBtnClick), for: .touchUpInside)
        headImageViewBtn.addTarget(self, action: #selector(headBtnClick), for: .touchUpInside)
    }
    
    @objc func headBtnClick() {
        textField.resignFirstResponder()
        UIView.animate(withDuration: 0.3) {
            self.transform = .identity
        }
        
        let model = TRTCAlertViewModel()
        let alert = TRTCAvatarListAlertView(viewModel: model)
        addSubview(alert)
        alert.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        alert.layoutIfNeeded()
        alert.show()
        alert.didClickConfirmBtn = { [weak self] in
            guard let `self` = self else { return }
            if let url = URL.init(string: ProfileManager.sharedManager().currentUserModel?.avatar ?? "") {
                self.headImageViewBtn.kf.setImage(with: .network(url), for: .normal)
            }
        }
    }
    
    @objc func registBtnClick() {
        textField.resignFirstResponder()
        guard let name = textField.text else { return }
        if  let userModel = ProfileManager.sharedManager().currentUserModel {
            IMLogicRequest.synchronizUserInfo(currentUserModel: userModel, name: name,success: { (user) in
                debugPrint("set IM name success")
            } ,failed: { (code, message) in
                debugPrint("set IM avatar errorStr: \(message ?? ""), errorCode: \(code)")
            })
        }
        
        //        ProfileManager.sharedManager().setIMUser(name: name) {
        //            debugPrint("set IM name success")
        //        } fail: { (code, message) in
        //            debugPrint("set IM name errorStr: \(message ?? ""), errorCode: \(code)")
        //        }
        
        rootVC?.regist(name)
    }
    
    var canUse = true
    let enableColor = UIColor(hex: "BBBBBB") ?? UIColor.gray
    let disableColor = UIColor(hex: "FA585E") ?? UIColor.red
    
    func checkRegistBtnState(_ count: Int = -1) {
        var ctt = textField.text?.count ?? 0
        if count > -1 {
            ctt = count
        }
        registBtn.isEnabled = canUse && ctt > 0
    }
}

extension TRTCRegisterRootView : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        UIView.animate(withDuration: 0.3) {
            self.transform = .identity
        }
        checkRegistBtnState()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        checkRegistBtnState()
        return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxCount = 20
        guard let textFieldText = textField.text,
              let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                  return false
              }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        let res = count <= maxCount
        if res {
            let newText = (textFieldText as NSString).replacingCharacters(in: range, with: string)
            
            checkAlertTitleLState(newText)
            checkRegistBtnState(count)
        }
        return res
    }
    
    func checkAlertTitleLState(_ text: String = "") {
        if text == "" {
            if let str = textField.text {
                canUse = validate(userName: str)
                descLabel.textColor = canUse ? enableColor : disableColor
            }
            else {
                canUse = false
                descLabel.textColor = disableColor
            }
        }
        else {
            canUse = validate(userName: text)
            descLabel.textColor = canUse ? enableColor : disableColor
        }
    }
    
    func validate(userName: String) -> Bool {
        let reg = "^[a-z0-9A-Z\\u4e00-\\u9fa5\\_]{2,20}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", reg)
        return predicate.evaluate(with: userName)
    }
}

/// MARK: - internationalization string
fileprivate extension String {
    static let titleText = TRTCKaraokeLocalize("Demo.TRTC.Login.regist")
    static let nicknamePlaceholderText = TRTCKaraokeLocalize("Demo.TRTC.LoginMock.fillinusernickname")
    static let descText = TRTCKaraokeLocalize("Demo.TRTC.Login.limit20count")
    static let registText = TRTCKaraokeLocalize("Demo.TRTC.Login.regist")
}

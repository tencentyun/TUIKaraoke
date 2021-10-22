//
//  TRTCLoginRootView.swift
//  TXLiteAVDemo
//
//  Created by gg on 2021/4/7.
//  Copyright © 2021 Tencent. All rights reserved.
//

import WebKit
import TXAppBasic

class TRTCAgreementButton: UIButton {
        open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            if (bounds.size.width <= 16) && (bounds.size.height <= 16){
                let expandSize:CGFloat = 16.0;
                let buttonRect = CGRect(x: bounds.origin.x - expandSize, y: bounds.origin.y - expandSize, width: bounds.size.width + 2*expandSize, height: bounds.size.height + 2*expandSize);
                return buttonRect.contains(point)
            }else{
                return super.point(inside: point, with: event)
            }
        }
}

class TRTCLoginRootView: UIView {

    lazy var bgView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "login_bg"))
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 32)
        label.textColor = UIColor(hex: "333333") ?? .black
        label.text = .titleText
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    lazy var contentView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        return view
    }()

    lazy var phoneNumTextField: UITextField = {
        let textField = createTextField(.phoneNumPlaceholderText)
        textField.keyboardType = .phonePad
        return textField
    }()
    
   
    lazy var phoneNumBottomLine: UIView = {
        let view = createSpacingLine()
        return view
    }()
    
    
    lazy var loginBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitle(.loginText, for: .normal)
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
   
    
    lazy var agreementBtn: TRTCAgreementButton = {
        let btn = TRTCAgreementButton(type: .custom)
        btn.setImage(UIImage(named: "checkbox_nor"), for: .normal)
        btn.setImage(UIImage(named: "checkbox_sel"), for: .selected)
        btn.sizeToFit()
        return btn
    }()
    
    lazy var agreementTextView: TRTCLoginAgreementTextView = {
        let textView = TRTCLoginAgreementTextView(frame: .zero, textContainer: nil)
        textView.delegate = self
        textView.backgroundColor = .white
        textView.isEditable = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = .link
        textView.textAlignment = .left
        let totalStr = localizeReplaceTwoCharacter(origin: .agreementText, xxx_replace: .privacyRegulationsText, yyy_replace: .userProtocolText)
        let privaStr = String.privacyRegulationsText
        let protoStr = String.userProtocolText
        
        guard let privaR = totalStr.range(of: privaStr), let protoR = totalStr.range(of: protoStr) else {
            return textView
        }
        
        let totalRange = NSRange(location: 0, length: totalStr.count)
        let privaRange = totalStr.nsrange(fromRange: privaR)
        let protoRange = totalStr.nsrange(fromRange: protoR)
        
        let attr = NSMutableAttributedString(string: totalStr)
        
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        attr.addAttribute(.paragraphStyle, value: style, range: totalRange)
        
        attr.addAttribute(.font, value: UIFont(name: "PingFangSC-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10), range: totalRange)
        attr.addAttribute(.foregroundColor, value: UIColor.lightGray, range: totalRange)
        
        attr.addAttribute(.link, value: "privacy", range: privaRange)
        attr.addAttribute(.link, value: "protocol", range: protoRange)
        
        attr.addAttribute(.foregroundColor, value: UIColor.blue, range: privaRange)
        attr.addAttribute(.foregroundColor, value: UIColor.blue, range: protoRange)
        
        textView.attributedText = attr
        return textView
    }()
    
    let versionTipLabel: UILabel = {
        let tip = UILabel()
        tip.textAlignment = .center
        tip.font = UIFont.systemFont(ofSize: 14)
        tip.textColor = UIColor(hex: "BBBBBB")?.withAlphaComponent(0.8)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "0.1.1"
        let sdvVersionStr =  "1.0.0"
        tip.text = "TRTC v\(sdvVersionStr)(\(version))"
        tip.adjustsFontSizeToFitWidth = true
        return tip
    }()
    
    private func createSpacingLine() -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor(hex: "EEEEEE")
        return view
    }
    
    private func createTextField(_ placeholder: String) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.backgroundColor = .white
        textField.font = UIFont(name: "PingFangSC-Regular", size: 16)
        textField.textColor = UIColor(hex: "333333")
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.font : UIFont(name: "PingFangSC-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor : UIColor(hex: "BBBBBB") ?? .gray])
        textField.delegate = self
        return textField
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        contentView.roundedRect(rect: contentView.bounds, byRoundingCorners: .topRight, cornerRadii: CGSize(width: 40, height: 40))
        loginBtn.layer.cornerRadius = loginBtn.frame.height * 0.5
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        if let current = currentTextField {
            current.resignFirstResponder()
            currentTextField = nil
        }
        UIView.animate(withDuration: 0.3) {
            self.transform = .identity
        }
        checkLoginBtnState()
    }
    
    weak var currentTextField: UITextField?
    
    public weak var rootVC: TRTCLoginViewController?
    
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
        guard let superview = loginBtn.superview else {
            return
        }
        let rect = value as! CGRect
        let converted = superview.convert(loginBtn.frame, to: self)
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
        constructViewHierarchy() // 视图层级布局
        activateConstraints() // 生成约束（此时有可能拿不到父视图正确的frame）
        bindInteraction()
        if checkPrivacyAlertShouldShow() {
            showPrivacyAlert()
        }
    }
    
    func constructViewHierarchy() {
        addSubview(bgView)
        addSubview(titleLabel)
        addSubview(contentView)
        contentView.addSubview(phoneNumTextField)
        contentView.addSubview(phoneNumBottomLine)
        contentView.addSubview(loginBtn)
        contentView.addSubview(agreementBtn)
        contentView.addSubview(agreementTextView)
        contentView.bringSubviewToFront(agreementBtn)
        contentView.addSubview(versionTipLabel)
    }
    func activateConstraints() {
        bgView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(bgView.snp.width)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(convertPixel(h: 86) + kDeviceSafeTopHeight)
            make.leading.equalToSuperview().offset(convertPixel(w: 40))
            make.trailing.lessThanOrEqualToSuperview().offset(-convertPixel(w: 40))
        }
        contentView.snp.makeConstraints { (make) in
            make.top.equalTo(bgView.snp.bottom).offset(-convertPixel(h: 64))
            make.leading.trailing.bottom.equalToSuperview()
        }
        phoneNumTextField.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(convertPixel(h: 40))
            make.leading.equalToSuperview().offset(convertPixel(w: 40))
            make.trailing.equalToSuperview().offset(-convertPixel(w: 40))
            make.height.equalTo(convertPixel(h: 57))
        }

        
     
        phoneNumBottomLine.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalTo(phoneNumTextField)
            make.height.equalTo(convertPixel(h: 1))
        }
        
        agreementBtn.snp.makeConstraints { (make) in
            make.top.equalTo(phoneNumTextField.snp.bottom).offset(6)
            make.leading.equalTo(phoneNumTextField)
            make.size.equalTo(CGSize(width: 12, height: 12))
        }
        agreementTextView.snp.makeConstraints { (make) in
            make.leading.equalTo(agreementBtn.snp.trailing)
            make.top.equalTo(agreementBtn)
            make.trailing.equalTo(phoneNumTextField)
            make.height.equalTo(60)
        }
        
        loginBtn.snp.makeConstraints { (make) in
            make.top.equalTo(agreementTextView.snp.bottom).offset(convertPixel(h: 10))
            make.leading.equalToSuperview().offset(convertPixel(w: 20))
            make.trailing.equalToSuperview().offset(-convertPixel(w: 20))
            make.height.equalTo(convertPixel(h: 52))
        }
        versionTipLabel.snp.makeConstraints { (make) in
            make.bottomMargin.equalTo(contentView).offset(-12)
            make.leading.trailing.equalTo(contentView)
            make.height.equalTo(30)
        }
    }
    func bindInteraction() {
        loginBtn.addTarget(self, action: #selector(loginBtnClick), for: .touchUpInside)
        agreementBtn.addTarget(self, action: #selector(agreementCheckboxBtnClick), for: .touchUpInside)
    }
    
    @objc func agreementCheckboxBtnClick() {
        agreementBtn.isSelected = !agreementBtn.isSelected
    }
    
    private var countryModel: TRTCLoginCountryModel?
    
    @objc func loginBtnClick() {
        phoneNumTextField.resignFirstResponder()
        guard agreementBtn.isSelected else {
            makeToast(.noagreeAlertText)
            return
        }
        if let current = currentTextField {
            current.resignFirstResponder()
        }
        guard let phone = phoneNumTextField.text else {
            return
        }

        rootVC?.login(phone:phone)
    }
    
    
    
    func checkPrivacyAlertShouldShow() -> Bool {
        let res = UserDefaults.standard.bool(forKey: "_kPrivacyHasShowedk_")
        return !res
    }
    
    func showPrivacyAlert() {
        guard let vc = rootVC else {
            return
        }
        let alert = TRTCPrivacyAlertView(superVC: vc)
        addSubview(alert)
        alert.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        layoutIfNeeded()
        alert.didClickConfirmBtn = { [weak self] in
            guard let `self` = self else { return }
            self.agreementCheckboxBtnClick()
        }
        alert.didDismiss = {
            UserDefaults.standard.setValue(true, forKey: "_kPrivacyHasShowedk_")
        }
    }
}

extension TRTCLoginRootView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let last = currentTextField {
            last.resignFirstResponder()
        }
        currentTextField = textField
        textField.becomeFirstResponder()
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        currentTextField = nil
        UIView.animate(withDuration: 0.3) {
            self.transform = .identity
        }
        checkLoginBtnState()
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == phoneNumTextField {
            checkLoginBtnState()
        }
        return true
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        checkLoginBtnState()
        return true
    }
    
    func checkLoginBtnState() {
        if (phoneNumTextField.text?.count ?? 0) > 5 {
            loginBtn.isEnabled = true
        }else{
            loginBtn.isEnabled = false
        }
    }
}

extension TRTCLoginRootView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.absoluteString == "privacy" {
            showPrivacy()
        }
        else if URL.absoluteString == "protocol" {
            showProtocol()
        }
        return true
    }
    func showPrivacy() {
        guard let url = URL(string: "https://web.sdk.qcloud.com/document/Tencent-RTC-Privacy-Protection-Guidelines.html") else {
            return
        }
        let vc = TRTCWebViewController(url: url, title: .privacyTitleText)
        rootVC?.navigationController?.pushViewController(vc, animated: true)
    }
    func showProtocol() {
        guard let url = URL(string: "https://web.sdk.qcloud.com/document/Tencent-RTC-User-Agreement.html") else {
            return
        }
        let vc = TRTCWebViewController(url: url, title: .protocolTitleText)
        rootVC?.navigationController?.pushViewController(vc, animated: true)
    }
}

class TRTCLoginAgreementTextView: UITextView {
    override var canBecomeFirstResponder: Bool {
        get {
            return false
        }
    }
}

extension String {
    func nsrange(fromRange range : Range<String.Index>) -> NSRange {
        return NSRange(range, in: self)
    }
}

/// MARK: - internationalization string
fileprivate extension String {
    static let titleText = TRTCKaraokeLocalize("Demo.TRTC.Login.welcome")
    static let phoneNumPlaceholderText = TRTCKaraokeLocalize("V2.Live.LinkMicNew.enterphonenumber")
    static let verifyCodePlaceholderText = TRTCKaraokeLocalize("V2.Live.LinkMicNew.enterverificationcode")
    static let getVerifyCodeText = TRTCKaraokeLocalize("V2.Live.LinkMicNew.getverificationcode")
    static let loginText = TRTCKaraokeLocalize("V2.Live.LoginMock.login")
    
    static let agreementText = TRTCKaraokeLocalize("Demo.TRTC.Portal.privateandagreement")
    static let privacyRegulationsText = TRTCKaraokeLocalize("Demo.TRTC.Portal.<private>")
    static let userProtocolText = TRTCKaraokeLocalize("Demo.TRTC.Portal.<agreement>")
    static let noagreeAlertText = TRTCKaraokeLocalize("Demo.TRTC.Portal.agreeprivatefirst")
    static let privacyTitleText = TRTCKaraokeLocalize("Demo.TRTC.Portal.private")
    static let protocolTitleText = TRTCKaraokeLocalize("Demo.TRTC.Portal.agreement")
}

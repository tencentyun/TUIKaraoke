//
//  TRTCKaraokeTipsTableCell.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

import UIKit

extension String {
    func nsrange(fromRange range : Range<String.Index>) -> NSRange {
        return NSRange(range, in: self)
    }
}

class TRTCKaraokeTipsWelcomCell: UITableViewCell {
    
    static let urlText = "https://cloud.tencent.com/document/product/647/59402"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        let urlStr = TRTCKaraokeTipsWelcomCell.urlText
        let totalStr = localizeReplaceXX(.welcomeText, urlStr)
        let urlColor = UIColor.tui_color(withHex: "0063FF")
        let totalRange = NSRange(location: 0, length: totalStr.count)
        var urlRange = totalRange
        if let range = totalStr.range(of: urlStr) {
            urlRange = totalStr.nsrange(fromRange: range)
        }
        let attr = NSMutableAttributedString(string: totalStr)
        attr.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "PingFangSC-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14), range: totalRange)
        attr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.tui_color(withHex: "3CCFA5"), range: totalRange)
        attr.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "PingFangSC-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14), range: urlRange)
        attr.addAttribute(NSAttributedString.Key.foregroundColor, value: urlColor, range: urlRange)
        attr.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: urlRange)
        attr.addAttribute(NSAttributedString.Key.underlineColor, value: urlColor, range: urlRange)
        label.attributedText = attr
        return label
    }()
    
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
    }
    
    func constructViewHierarchy() {
        contentView.addSubview(titleLabel)
    }
    
    func activateConstraints() {
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-10)
        }
    }
    
    func bindInteraction() {
        
    }
}

class TRTCKaraokeTipsTableCell: UITableViewCell {
    private var isViewReady: Bool = false
    
    private var acceptAction: (() -> Void)?
    
    private var model: MsgEntity?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        selectionStyle = .none
        bindInteraction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let containerView: UIView = {
        let view = UIView.init(frame: .zero)
        view.backgroundColor = UIColor.init(0xFFFFFF, alpha: 0.2)
        return view
    }()
    
    let contentLabel: UILabel = {
        let label = UILabel.init(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 14)
        label.textColor = .white
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()
    
    let acceptButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(.acceptText, for: .normal)
        button.clipsToBounds = true
        button.isHidden = true
        button.titleLabel?.font = UIFont(name: "PingFangSC-Medium", size: 14)
        button.titleLabel?.textColor = .white
        return button
    }()
    
    lazy var manageSongBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(.manageSongText, for: .normal)
        btn.setTitleColor(UIColor.tui_color(withHex: "F95F91"), for: .normal)
        btn.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 14)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.adjustsImageWhenHighlighted = false
        btn.isHidden = true
        return btn
    }()
    
    lazy var acceptButtonLayer: CAGradientLayer = {
        let acceptButtonLayer = acceptButton.gradient(colors: [UIColor.tui_color(withHex:"FF88DD").cgColor,
                                                               UIColor.tui_color(withHex:"7D00BD").cgColor,])
        acceptButtonLayer.startPoint = CGPoint(x: 0, y: 0.5)
        acceptButtonLayer.endPoint = CGPoint(x: 1, y: 0.5)
        return acceptButtonLayer
    }()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        containerView.layer.cornerRadius = containerView.frame.height * 0.5
        acceptButton.layer.cornerRadius = acceptButton.frame.height * 0.5
        acceptButtonLayer.colors = [UIColor.tui_color(withHex:"FF88DD").cgColor,
                                    UIColor.tui_color(withHex:"7D00BD").cgColor,]
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else {
            return
        }
        isViewReady = true
        constructViewHierarchy()
        activateConstraints()
    }

    func constructViewHierarchy() {
        /// 此方法内只做add子视图操作
        contentView.addSubview(containerView)
        contentView.addSubview(acceptButton)
        containerView.addSubview(contentLabel)
        containerView.addSubview(manageSongBtn)
    }
    
    func activateConstraints() {
        containerView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.width.lessThanOrEqualTo(UIScreen.main.bounds.width * 2.0 / 3.0)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
        }
        acceptButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-10)
            make.width.equalTo(75)
        }
        manageSongBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(2)
            make.bottom.equalToSuperview().offset(-2)
            make.width.lessThanOrEqualTo(60)
        }
    }
    
    func bindInteraction() {
        acceptButton.addTarget(self, action: #selector(acceptAction(sender:)), for: .touchUpInside)
        manageSongBtn.addTarget(self, action: #selector(acceptAction(sender:)), for: .touchUpInside)
    }
    
    @objc private func acceptAction(sender: UIButton) {
        self.acceptAction?()
    }
    
    func setCell(model: MsgEntity, action: (()->())?, indexPath: IndexPath) {
        var attr : NSMutableAttributedString
        acceptAction = nil
        self.model = model
        switch model.type {
        case .normal:
            var textInfo = "\(model.content)"
            if model.userName.count > 0 {
                if model.content.contains("xxx") {
                    textInfo = localizeReplaceXX(model.content, model.userName)
                }
                else {
                    textInfo = "\(model.userName):\(model.content)"
                }
                let nameRange = NSString(string: textInfo).range(of: model.userName)
                let totalRange = NSRange(location: 0, length: textInfo.count)
                attr = NSMutableAttributedString(string: textInfo)
                attr.addAttribute(.font, value: UIFont(name: "PingFangSC-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14), range: totalRange)
                attr.addAttribute(.foregroundColor, value: UIColor.white, range: totalRange)
                attr.addAttribute(.foregroundColor, value: getColor(indexPath.row), range: nameRange)
            }
            else {
                let totalRange = NSRange(location: 0, length: textInfo.count)
                attr = NSMutableAttributedString(string: textInfo)
                attr.addAttribute(.font, value: UIFont(name: "PingFangSC-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14), range: totalRange)
                attr.addAttribute(.foregroundColor, value: UIColor.white, range: totalRange)
            }
        case .agreed:
            var textInfo = "\(model.content)"
            if model.content.contains("xxx") {
                textInfo = localizeReplaceXX(model.content, model.userName)
            }
            else {
                textInfo = "\(model.userName):\(model.content)"
            }
            let nameRange = NSString(string: textInfo).range(of: model.userName)
            let totalRange = NSRange(location: 0, length: textInfo.count)
            attr = NSMutableAttributedString(string: textInfo)
            attr.addAttribute(.font, value: UIFont(name: "PingFangSC-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14), range: totalRange)
            attr.addAttribute(.foregroundColor, value: UIColor.white, range: totalRange)
            attr.addAttribute(.foregroundColor, value: getColor(indexPath.row), range: nameRange)
        case .manage_song:
            var textInfo = "\(model.content)"
            if model.content.contains("xxx") {
                textInfo = localizeReplaceXX(model.content, model.userName)
            }
            else {
                textInfo = "\(model.userName):\(model.content)"
            }
            let nameRange = NSString(string: textInfo).range(of: model.userName)
            let totalRange = NSRange(location: 0, length: textInfo.count)
            attr = NSMutableAttributedString(string: textInfo)
            attr.addAttribute(.font, value: UIFont(name: "PingFangSC-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14), range: totalRange)
            attr.addAttribute(.foregroundColor, value: UIColor.white, range: totalRange)
            attr.addAttribute(.foregroundColor, value: getColor(indexPath.row), range: nameRange)
            acceptAction = model.action
        default:
            var textInfo = "\(model.content)"
            if model.content.contains("xxx") {
                textInfo = localizeReplaceXX(model.content, model.userName)
            }
            else {
                textInfo = "\(model.userName):\(model.content)"
            }
            let nameRange = NSString(string: textInfo).range(of: model.userName)
            let totalRange = NSRange(location: 0, length: textInfo.count)
            attr = NSMutableAttributedString(string: textInfo)
            attr.addAttribute(.font, value: UIFont(name: "PingFangSC-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14), range: totalRange)
            attr.addAttribute(.foregroundColor, value: UIColor.white, range: totalRange)
            attr.addAttribute(.foregroundColor, value: getColor(indexPath.row), range: nameRange)
            acceptAction = action
        }
        contentLabel.attributedText = attr
        contentLabel.sizeToFit()
    }
    
    private lazy var nameColors : [UIColor] = {
        var color : [UIColor] = []
        color.append(UIColor.tui_color(withHex: "3074FD"))
        color.append(UIColor.tui_color(withHex: "3CCFA5"))
        color.append(UIColor.tui_color(withHex: "FF8607"))
        color.append(UIColor.tui_color(withHex: "F7AF97"))
        color.append(UIColor.tui_color(withHex: "FF8BB7"))
        color.append(UIColor.tui_color(withHex: "FC6091"))
        color.append(UIColor.tui_color(withHex: "FCAF41"))
        return color
    }()
    
    private func getColor(_ index: Int) -> UIColor {
        let ctt = index % nameColors.count
        return nameColors[ctt]
    }
    
    func updateCell() {
        guard let model = model else {
            return
        }
        switch model.type {
        case .agreed, .normal:
            acceptButton.isHidden = true
            manageSongBtn.isHidden = true
            contentLabel.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.width.lessThanOrEqualTo(UIScreen.main.bounds.width * 2.0 / 3.0)
                make.top.equalToSuperview().offset(4)
                make.bottom.equalToSuperview().offset(-4)
            }
        case .manage_song:
            acceptButton.isHidden = true
            manageSongBtn.isHidden = false
            contentLabel.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.right.equalTo(manageSongBtn.snp.left).offset(-4)
                make.width.lessThanOrEqualTo(UIScreen.main.bounds.width * 2.0 / 3.0)
                make.top.equalToSuperview().offset(4)
                make.bottom.equalToSuperview().offset(-4)
            }
        default:
            acceptButton.isHidden = false
            manageSongBtn.isHidden = true
            contentLabel.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.right.equalToSuperview().offset(-16)
                make.width.lessThanOrEqualTo(UIScreen.main.bounds.width * 2.0 / 3.0)
                make.top.equalToSuperview().offset(4)
                make.bottom.equalToSuperview().offset(-4)
            }
        }
        setNeedsLayout()
    }
}

/// MARK: - internationalization string
fileprivate extension String {
    static let acceptText = karaokeLocalize("Demo.TRTC.Karaoke.agree")
    static let welcomeText = karaokeLocalize("Demo.TRTC.Karaoke.welcome")
    static let manageSongText = karaokeLocalize("Demo.TRTC.Karaoke.manageselectedsongs")
}

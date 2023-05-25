//
//  TRTCKaraokeRootView.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//
import UIKit
import TXAppBasic
import SnapKit

// 设置字号和透明度的
enum TRTCSeatState {
    case cellSeatEmpty
    case cellSeatFull
    case masterSeatEmpty
    case masterSeatFull
}

// 需要设置合理的高度和宽度获得正常的显示效果(高度越高，name和avatar之间的间距越大)
class TRTCKaraokeSeatView: UIView {
    private var isViewReady: Bool = false
    private var isGetBounds: Bool = false
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        bindInteraction()
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("can't init this viiew from coder")
    }
    
    deinit {
        TRTCLog.out("seat view deinit")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        avatarImageView.layer.cornerRadius = avatarImageView.frame.height*0.5
        
        speakView.layer.cornerRadius = speakView.frame.height*0.5
        speakView.layer.borderWidth = 4
        speakView.layer.borderColor = UIColor(0x0FA968).cgColor
    }
    let speakView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.isHidden = true
        return view
    }()
    let avatarImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "Karaoke_placeholder_avatar", in: karaokeBundle(), compatibleWith: nil)
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let muteImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "audience_voice_off", in: karaokeBundle(), compatibleWith: nil)
        imageView.isHidden = true
        return imageView
    }()

    let userContainerView: UIStackView = {
        let view = UIStackView(frame: .zero)
        view.backgroundColor = .clear
        view.axis = .horizontal
        view.alignment = .fill
        view.spacing = 3
        view.contentMode = .scaleToFill
        return view
    }()

    let networkImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "signal_full", in: karaokeBundle(), compatibleWith: nil)
        imageView.isHidden = true
        return imageView
    }()

    let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = .handsupText
        label.font = UIFont(name: "PingFangSC-Regular", size: 12)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    // MARK: - 视图生命周期函数
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else {
            return
        }
        isViewReady = true
        constructViewHierarchy() // 视图层级布局
        activateConstraints() // 生成约束（此时有可能拿不到父视图正确的frame）
    }

    func setupStyle() {
        backgroundColor = .clear
    }
    
    func constructViewHierarchy() {
        /// 此方法内只做add子视图操作
        addSubview(avatarImageView)
        addSubview(muteImageView)
        addSubview(userContainerView)
        userContainerView.addArrangedSubview(nameLabel)
        userContainerView.addArrangedSubview(networkImageView)
        avatarImageView.addSubview(speakView)
    }

    func activateConstraints() {
        /// 此方法内只给子视图做布局,使用:AutoLayout布局
        avatarImageView.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(48)
            make.height.equalTo(avatarImageView.snp.width)
        }
        muteImageView.snp.makeConstraints { (make) in
            make.trailing.bottom.equalTo(avatarImageView)
        }
        userContainerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(avatarImageView.snp.bottom).offset(4)
            make.width.lessThanOrEqualToSuperview().offset(6)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
        }
        networkImageView.snp.makeConstraints { make in
            make.height.width.equalTo(15)
        }
        speakView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func bindInteraction() {
        /// 此方法负责做viewModel和视图的绑定操作
    }
    
    func setNetworkIcon(level: Int) -> Void {
        switch level {
        case 1,2:
            networkImageView.image = UIImage(named: "signal_full", in: karaokeBundle(), compatibleWith: nil)
            networkImageView.isHidden = false
            break
        case 3,4:
            networkImageView.image = UIImage(named: "signal_mid", in: karaokeBundle(), compatibleWith: nil)
            networkImageView.isHidden = false
            break
        case 5:
            networkImageView.image = UIImage(named: "signal_low", in: karaokeBundle(), compatibleWith: nil)
            networkImageView.isHidden = false
            break
        case 6:
            networkImageView.image = UIImage(named: "signal_unable", in: karaokeBundle(), compatibleWith: nil)
            networkImageView.isHidden = false
            break
        default:
            networkImageView.isHidden = true
            return
        }
    }

    func setSeatInfo(model: SeatInfoModel, seatIndex: Int) {
        if model.isUsed {
            // 有人
            if let userSeatInfo = model.seatUser {
                let placeholder = UIImage(named: "Karaoke_placeholder_avatar", in: karaokeBundle(), compatibleWith: nil)
                let avatarStr = userSeatInfo.avatarURL
                if let avatarURL = URL(string: avatarStr) {
                    avatarImageView.kf.setImage(with: avatarURL, placeholder: placeholder)
                } else {
                    avatarImageView.image = placeholder
                }
                nameLabel.text = userSeatInfo.userName.isEmpty ? userSeatInfo.userId : userSeatInfo.userName
            }
        } else {
            // 无人
            avatarImageView.image = UIImage(named: "seatDefault", in: karaokeBundle(), compatibleWith: nil)
            nameLabel.text = localizeReplaceXX(.seatIndexText, "\(seatIndex + 1)")
        }
        
        if model.isClosed {
            // close 状态
            avatarImageView.image = UIImage(named: "room_lockseat", in: karaokeBundle(), compatibleWith: nil)
            speakView.isHidden = true
            muteImageView.isHidden = true
            networkImageView.isHidden = true
            return
        }
        
        if let user = model.seatUser {
            muteImageView.isHidden = !user.mute
            setNetworkIcon(level: Int(user.networkLevel))
        }
        else {
            muteImageView.isHidden = true
            networkImageView.isHidden = true
        }
        
        if (model.isTalking) {
            speakView.isHidden = false
        } else {
            speakView.isHidden = true
        }
    }
}

/// MARK: - internationalization string
fileprivate extension String {
    static var handsupText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.presshandsup")
    }
    static var lockedText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.islocked")
    }
    static var inviteHandsupText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.invitehandsup")
    }
    static var seatIndexText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.xxmic")
    }
}




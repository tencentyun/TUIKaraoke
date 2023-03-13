//
//  TRTCMusicPanelView.swift
//  TUIKaraoke
//
//  Created by gg on 2021/6/24.
//  Copyright © 2022 Tencent. All rights reserved.

import Foundation
import UIKit

class TRTCMusicPanelView: UIView {
    var currentMusicModel: KaraokeMusicModel? = nil
    var isStartChorus: Bool = false // 是否正在合唱
    
    private var reciprocalThreeSecond = 3
    private var currentLrcUrl: URL? = nil
    private var isRequestSelectedMusicList: Bool = false
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var bgView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "lkyric_bg", in: karaokeBundle(), compatibleWith: nil))
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    lazy var seatIndexLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 12)
        label.textColor = .white
        return label
    }()

    lazy var userNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 12)
        label.textColor = .white
        return label
    }()

    lazy var musicIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "musicIcon", in: karaokeBundle(), compatibleWith: nil))
        return imageView
    }()

    lazy var musicNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 12)
        label.textColor = .white
        return label
    }()

    lazy var placeholderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.isHidden = true
        label.text = .placeholderText
        return label
    }()
    
    lazy var reciprocalLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 60)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.isHidden = true
        return label
    }()

    // 原生或者伴奏切换
    lazy var originalOrAccompanyChangeBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "room_accompany_icon", in: karaokeBundle(), compatibleWith: nil), for: .normal)
        btn.setImage(UIImage(named: "room_original_icon", in: karaokeBundle(), compatibleWith: nil), for: .selected)
        btn.adjustsImageWhenHighlighted = false
        btn.isHidden = true
        return btn
    }()
    
    lazy var voiceChangeBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "voiceChange_kongling_nor", in: karaokeBundle(), compatibleWith: nil), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.isHidden = true
        return btn
    }()

    lazy var soundEffectBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "tuning", in: karaokeBundle(), compatibleWith: nil), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        btn.isHidden = true
        return btn
    }()

    lazy var songSelectorBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(.songSelectorText, for: .normal)
        btn.clipsToBounds = true
        btn.titleLabel?.font = UIFont(name: "PingFangSC-Medium", size: 14)
        btn.titleLabel?.textColor = .white
        return btn
    }()
    
    lazy var startChorusBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(.startChorusText, for: .normal)
        btn.clipsToBounds = true
        btn.isHidden = true
        btn.titleLabel?.font = UIFont(name: "PingFangSC-Medium", size: 14)
        btn.titleLabel?.numberOfLines = 2
        btn.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2)
        btn.titleLabel?.textAlignment = .center
        btn.titleLabel?.textColor = .white
        return btn
    }()
    
    lazy var startChorusBtnLayer: CAGradientLayer = {
        let startChorusBtnLayer = startChorusBtn.gradient(colors: [UIColor.tui_color(withHex:"FF88DD").cgColor,
                                                                   UIColor.tui_color(withHex:"7D00BD").cgColor,])
        startChorusBtnLayer.startPoint = CGPoint(x: 0, y: 0.5)
        startChorusBtnLayer.endPoint = CGPoint(x: 1, y: 0.5)
        return startChorusBtnLayer
    }()

    lazy var lrcView: TUILyricsView = {
        let view = TUILyricsView()
        view.isHidden = true
        return view
    }()

    let viewModel: TRTCKaraokeViewModel
    
    var reciprocalTimer: Timer?

    init(frame: CGRect = .zero, viewModel: TRTCKaraokeViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = 12
        currentLrcUrl = nil
        viewModel.effectViewModel.viewResponder = self
    }
    
    deinit {
        currentLrcUrl = nil
        debugPrint("\(self) deinit")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let selectBtnLayer = songSelectorBtn.gradient(colors: [UIColor.tui_color(withHex:"FF88DD").cgColor,
                                                               UIColor.tui_color(withHex: "7D00BD").cgColor,])
        selectBtnLayer.startPoint = CGPoint(x: 0, y: 0.5)
        selectBtnLayer.endPoint = CGPoint(x: 1, y: 0.5)
        songSelectorBtn.layer.cornerRadius = songSelectorBtn.frame.height * 0.5
        
        startChorusBtn.layer.cornerRadius = startChorusBtn.frame.height * 0.5
    }

    private var isViewReady = false
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else {
            return
        }
        isViewReady = true
        constructViewHierarchy()
        activateConstraints()
        bindInteraction()
        updateLrcView(music: viewModel.effectViewModel.currentPlayingModel)
        setLrcURL(lrcString: viewModel.effectViewModel.currentPlayingModel?.lrcUrl)
    }
    
    func setLrcURL(lrcString: String?) {
        if let lrcString = lrcString {
            lrcView.lrcFileUrl = URL(fileURLWithPath: lrcString)
        } else {
            lrcView.lrcFileUrl = nil
        }
    }
    
    func updateLrcView(music: KaraokeMusicModel?) {
        if let music = music {
            setMusicDetail(show: true)
            let seatIndex = viewModel.getSeatIndexByUserId(userId: music.userId)
            seatIndexLabel.text = localizeReplaceXX(.seatIndexText, "\(seatIndex)")
            userNameLabel.text = music.bookUserName
            musicNameLabel.text = music.musicName
            currentMusicModel = music
            if music.music.isContentReady {
                startChorusBtnLayer.colors = [UIColor.tui_color(withHex: "FF88DD").cgColor, UIColor.tui_color(withHex: "7D00BD").cgColor]
                startChorusBtn.isUserInteractionEnabled = true
            } else {
                startChorusBtnLayer.colors = [UIColor.gray.cgColor,UIColor.gray.cgColor]
                startChorusBtn.isUserInteractionEnabled = false
            }
        } else {
            currentMusicModel = nil
            setMusicDetail(show: false)
        }
    }

    func setMusicDetail(show: Bool) {
        if placeholderLabel.isHidden != show {
            if show {
                songSelectorBtn.snp.remakeConstraints { make in
                    make.trailing.equalToSuperview().offset(-8)
                    make.top.equalToSuperview().offset(8)
                    make.size.equalTo(CGSize(width: 76, height: 38))
                }
                containerView.snp.remakeConstraints { make in
                    make.trailing.equalToSuperview().offset(-8)
                    make.top.equalToSuperview().offset(8)
                    make.size.equalTo(CGSize(width: 76, height: 38))
                }
            } else {
                songSelectorBtn.snp.remakeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.top.equalTo(self.snp.centerY).offset(10)
                    make.size.equalTo(CGSize(width: 76, height: 38))
                }
                containerView.snp.remakeConstraints { make in
                    make.trailing.equalToSuperview().offset(-8)
                    make.top.equalToSuperview().offset(8)
                    make.size.equalTo(CGSize(width: 0, height: 38))
                }
            }
            songSelectorBtn.setNeedsLayout()
        }
        seatIndexLabel.isHidden = !show
        userNameLabel.isHidden = !show
        musicNameLabel.isHidden = !show
        musicIcon.isHidden = !show
        placeholderLabel.isHidden = show
    }

    @objc func voiceChangeBtnClick() {
        let alert = TRTCKaraokeSoundEffectAlert(viewModel: viewModel, effectType: .voiceChange)
        alert.titleLabel.text = .voiceChangeTitleText
        superview?.addSubview(alert)
        alert.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        alert.layoutIfNeeded()
        alert.show()
    }

    @objc func soundEffectBtnClick() {
        let alert = TRTCKaraokeSoundEffectAlert(viewModel: viewModel, effectType: .soundEffect)
        superview?.addSubview(alert)
        alert.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        alert.layoutIfNeeded()
        alert.show()
    }

    lazy var songSelectorAlert: TRTCKaraokeSongSelectorAlert = {
        let alert = TRTCKaraokeSongSelectorAlert(viewModel: viewModel)
        return alert
    }()

    @objc func songSelectorBtnClick() {
        if !viewModel.updateNetworkSuccessed {
            viewModel.viewResponder?.showToast(message: .updateNetworkFailedText)
            return
        }
        if songSelectorAlert.superview == nil {
            superview?.addSubview(songSelectorAlert)
            songSelectorAlert.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            songSelectorAlert.layoutIfNeeded()
        }
        songSelectorAlert.show()
    }
    
    @objc func originalOrAccompanyChangeBtnClick() {
        if !viewModel.isOwner {
            viewModel.viewResponder?.showToast(message: .onlyAnchorOperationText)
            return
        }
        originalOrAccompanyChangeBtn.isSelected = !originalOrAccompanyChangeBtn.isSelected
        viewModel.Karaoke.switchMusicAccompanimentMode(isOriginal: originalOrAccompanyChangeBtn.isSelected)
        viewModel.effectViewModel.isOriginalVolume = originalOrAccompanyChangeBtn.isSelected
    }
    
    @objc
    func startChorusBtnClick() {
        if viewModel.isOwner {
            if let musicModel = viewModel.currentMusicModel {
                startChorusBtn.isHidden = true
                viewModel.effectViewModel.playMusic(musicModel)
                startTimer()
                isStartChorus = true
            }
        } else {
            startChorusBtn.isHidden = true
            startTimer()
        }
        if viewModel.userType == .anchor {
            voiceChangeBtn.isHidden = false
            soundEffectBtn.isHidden = false
            originalOrAccompanyChangeBtn.isHidden = false
        } else {
            voiceChangeBtn.isHidden = true
            soundEffectBtn.isHidden = true
            originalOrAccompanyChangeBtn.isHidden = true
        }
    }
    
    @objc
    func reciprocalThreeSecondToPlay() {
        if reciprocalThreeSecond < 1 {
            resetReciprocalStatus()
        } else {
            reciprocalLabel.isHidden = false
            lrcView.isHidden = true
            reciprocalLabel.text = "\(reciprocalThreeSecond)"
            reciprocalThreeSecond -= 1
        }
    }
    
    private func resetReciprocalStatus() {
        cleanTimer()
        reciprocalThreeSecond = 3
        reciprocalLabel.isHidden = true
        startChorusBtn.isHidden = true
        lrcView.isHidden = false
        placeholderLabel.text = .placeholderText
        reciprocalLabel.text = "\(reciprocalThreeSecond)"
    }
    
    func startTimer() {
        guard reciprocalTimer == nil else { return }
        reciprocalTimer = Timer.scheduledTimer(timeInterval: 1,
                                               target: self,
                                               selector: #selector(reciprocalThreeSecondToPlay),
                                               userInfo: nil,
                                               repeats: true)
        
        reciprocalTimer?.fire()
    }
    
    func cleanTimer() {
        reciprocalTimer?.invalidate()
        reciprocalTimer = nil
    }
    
    func checkBtnShouldHidden() {
        if viewModel.userType == .audience {
            voiceChangeBtn.isHidden = true
            soundEffectBtn.isHidden = true
            originalOrAccompanyChangeBtn.isHidden = true
        }
    }
    
    func updateChorusBtnStatus(musicId: String) {
        guard let currentMusicModel = currentMusicModel else {
            TRTCLog.out("___ currentMusicModel is nil")
            return
        }

        if currentMusicModel.music.getMusicId() == musicId {
            startChorusBtnLayer.colors = [UIColor.tui_color(withHex: "FF88DD").cgColor, UIColor.tui_color(withHex: "7D00BD").cgColor]
            startChorusBtn.isUserInteractionEnabled = true
        } else {
            TRTCLog.out("___ currentMusicModel.music.getMusicId() is \(currentMusicModel.music.getMusicId()), musicId = \(musicId)")
        }
    }
}

extension TRTCMusicPanelView: TRTCKaraokeSoundEffectViewResponder {
    
    func showStartAnimationAndPlay(startDelay: Int) {
        if reciprocalLabel.isHidden == true {
            reciprocalThreeSecond = startDelay >= 0 ? startDelay : 0
            reciprocalThreeSecond = (reciprocalThreeSecond + 500) / 1000
            startChorusBtnClick()
        }
    }
    
    func onSelectedMusicListChanged() {
        songSelectorAlert.reloadSelectedSongView(dataSource: viewModel.effectViewModel.musicSelectedList)
    }

    func onMusicListChanged() {
        songSelectorAlert.reloadSongSelectorView(dataSource: viewModel.effectViewModel.musicList)
        if viewModel.isOwner && viewModel.effectViewModel.currentPlayingModel == nil && !isStartChorus {
            startChorusBtn.isHidden = false
        }
        updateLrcView(music: viewModel.effectViewModel.musicSelectedList.first)
        if viewModel.effectViewModel.musicSelectedList.count == 0 {
            isStartChorus = false
            voiceChangeBtn.isHidden = true
            soundEffectBtn.isHidden = true
            originalOrAccompanyChangeBtn.isHidden = true
        }
    }

    func bgmOnPrepareToPlay(musicId: Int32) {
        guard musicId != 0 else {
            setLrcURL(lrcString:nil)
            return
        }
        var model: KaraokeMusicModel?
        if let current = viewModel.effectViewModel.currentPlayingModel {
            if current.musicID == musicId {
                model = current
            }
        }
        if model == nil {
            for selected in viewModel.effectViewModel.musicSelectedList {
                if selected.music.performId == String(musicId) {
                    model = selected
                    break
                }
            }
        }
        if model == nil {
            for music in viewModel.effectViewModel.musicList {
                if music.music.performId == String(musicId) {
                    model = music
                    break
                }
            }
        }
        if model != nil {
            setLrcURL(lrcString:model?.lrcUrl)
        }
    }

    func bgmOnPlaying(musicId: Int32, current: Double, total: Double) {
        if musicId == currentMusicModel?.musicID {
            lrcView.isHidden = false
            lrcView.currentTime = current
        } else {
            if isRequestSelectedMusicList {
                return
            }
            isRequestSelectedMusicList = true
            viewModel.effectViewModel.reloadSelectedMusicList { [weak self] _, _, _ in
                guard let self = self else { return }
                self.isRequestSelectedMusicList = false
            }
        }
    }

    func bgmOnCompletePlaying() {
        lrcView.isHidden = true
        voiceChangeBtn.isHidden = true
        soundEffectBtn.isHidden = true
        originalOrAccompanyChangeBtn.isHidden = true
    }

    func onManageSongBtnClick() {
        if songSelectorAlert.superview == nil {
            superview?.addSubview(songSelectorAlert)
            songSelectorAlert.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            songSelectorAlert.layoutIfNeeded()
        }
        songSelectorAlert.show(index: 1)
    }
    
    func onStartChorusBtnClick() {
        if isStartChorus {
            startChorusBtnClick()
        }
    }
}

// Layout
extension TRTCMusicPanelView {
    func constructViewHierarchy() {
        addSubview(bgView)

        addSubview(seatIndexLabel)
        addSubview(userNameLabel)
        addSubview(musicIcon)
        addSubview(musicNameLabel)

        addSubview(placeholderLabel)
        addSubview(originalOrAccompanyChangeBtn)

        addSubview(voiceChangeBtn)
        addSubview(soundEffectBtn)
        addSubview(containerView)
        addSubview(startChorusBtn)
        addSubview(songSelectorBtn)
        addSubview(reciprocalLabel)
        addSubview(lrcView)
    }

    func activateConstraints() {
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        seatIndexLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(12)
        }
        userNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(seatIndexLabel.snp.trailing).offset(8)
            make.centerY.equalTo(seatIndexLabel)
        }
        musicIcon.snp.makeConstraints { make in
            make.leading.equalTo(seatIndexLabel)
            make.centerY.equalTo(seatIndexLabel.snp.bottom).offset(20)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
        musicNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(musicIcon.snp.trailing).offset(4)
            make.centerY.equalTo(musicIcon)
        }
        containerView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(CGSize(width: 0, height: 38))
        }
        startChorusBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.snp.centerY).offset(10)
            make.size.equalTo(CGSize(width: 76, height: 38))
        }
        songSelectorBtn.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(CGSize(width: 76, height: 38))
        }
        soundEffectBtn.snp.makeConstraints { (make) in
            make.trailing.equalTo(containerView.snp.leading).offset(-10)
            make.centerY.equalTo(containerView)
            make.size.equalTo(CGSize(width: 32, height: 32))
        }
        voiceChangeBtn.snp.makeConstraints { (make) in
            make.trailing.equalTo(soundEffectBtn.snp.leading).offset(-10)
            make.centerY.size.equalTo(soundEffectBtn)
        }
        originalOrAccompanyChangeBtn.snp.makeConstraints { make in
            make.trailing.equalTo(voiceChangeBtn.snp.leading).offset(-10)
            make.centerY.size.equalTo(soundEffectBtn)
        }
        placeholderLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self.snp.centerY)
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        reciprocalLabel.snp.makeConstraints { make in
            make.centerX.equalTo(startChorusBtn.snp.centerX)
            make.centerY.equalTo(startChorusBtn.snp.centerY)
            make.size.equalTo(CGSize(width: 44, height: 44))
        }

        lrcView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-34)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
    }

    func bindInteraction() {
        voiceChangeBtn.addTarget(self, action: #selector(voiceChangeBtnClick), for: .touchUpInside)
        soundEffectBtn.addTarget(self, action: #selector(soundEffectBtnClick), for: .touchUpInside)
        songSelectorBtn.addTarget(self, action: #selector(songSelectorBtnClick), for: .touchUpInside)
        startChorusBtn.addTarget(self, action: #selector(startChorusBtnClick), for: .touchUpInside)
        originalOrAccompanyChangeBtn.addTarget(self, action: #selector(originalOrAccompanyChangeBtnClick), for: .touchUpInside)
    }
}

// MARK: - internationalization string

fileprivate extension String {
    static let songSelectorText = karaokeLocalize("Demo.TRTC.Karaoke.selectsong")
    static let voiceChangeTitleText = karaokeLocalize("ASKit.MainMenu.VoiceChangeTitle")
    static let placeholderText = karaokeLocalize("Demo.TRTC.Karaoke.nosongs")
    static let seatIndexText = karaokeLocalize("Demo.TRTC.Karaoke.xxmic")
    static let startChorusText = karaokeLocalize("Demo.TRTC.Chorus.StartChorus")
    static let onlyAnchorOperationText = karaokeLocalize("Demo.TRTC.Karaoke.onlyanchorcanoperation")
    static let updateNetworkFailedText = karaokeLocalize("Demo.TRTC.Karaoke.updateNetworkFailed")
}

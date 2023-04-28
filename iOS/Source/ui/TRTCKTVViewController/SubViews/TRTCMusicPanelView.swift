//
//  TRTCMusicPanelView.swift
//  TUIKaraoke
//
//  Created by gg on 2021/6/24.
//  Copyright © 2022 Tencent. All rights reserved.

import Foundation
import UIKit

class TRTCMusicPanelView: UIView {

    var isStartChorus: Bool = false // 是否正在合唱
    
    private let dateFormatter = DateFormatter()
    
    private var isRequestSelectedMusicList: Bool = false
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var bgView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "lkyric_bg", in: karaokeBundle(), compatibleWith: nil))
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.5
        return imageView
    }()
    
    lazy var musicIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "musicIcon", in: karaokeBundle(), compatibleWith: nil))
        return imageView
    }()

    lazy var musicNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 13)
        label.textColor = .white
        return label
    }()
    
    lazy var musicNameContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var musicNameActionImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "arrow", in: karaokeBundle(), compatibleWith: nil))
        return imageView
    }()
    
    lazy var musicTimeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 10)
        label.textColor = .white
        return label
    }()

    // 原生或者伴奏切换
    lazy var musicModeSegmented: TRTCKaraokeMusicModeSegmented = {
        let segmented = TRTCKaraokeMusicModeSegmented(frame: .zero,
                                                      items: [.musicAccompanimentText, .musicOriginalText],
                                                      viewModel: viewModel)
        segmented.delegate = self
        segmented.isHidden = true
        segmented.updateSelectedIndex(index: 0)
        return segmented
    }()
    
    lazy var soundEffectBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "effectSetting", in: karaokeBundle(), compatibleWith: nil), for: .normal)
        btn.setTitle(.soundEffectText, for: .normal)
        btn.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 16)
        btn.adjustsImageWhenHighlighted = false
        btn.titleLabel?.textColor = .white
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        return btn
    }()

    lazy var songSelectorBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(.songSelectorText, for: .normal)
        btn.clipsToBounds = true
        btn.titleLabel?.font = UIFont(name: "PingFangSC-Medium", size: 14)
        btn.titleLabel?.textColor = .white
        btn.backgroundColor = .white.withAlphaComponent(0.2)
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

    lazy var lyricsView: TUILyricsView = {
        let view = TUILyricsView()
        view.isHidden = true
        return view
    }()

    let viewModel: TRTCKaraokeViewModel

    init(frame: CGRect = .zero, viewModel: TRTCKaraokeViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = 12
        viewModel.effectViewModel.viewResponder = self
    }
    
    deinit {
        debugPrint("\(self) deinit")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
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
        updateMusicPanel(musicInfo: viewModel.currentMusicModel)
    }
    
    @objc func soundEffectBtnClick() {
        if viewModel.userType == .audience {
            viewModel.viewResponder?.showToast(message: .notInSeatText)
            return
        }
        let alert = TRTCKaraokeSoundEffectAlert(viewModel: viewModel, effectType: .soundEffect)
        superview?.addSubview(alert)
        alert.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        alert.layoutIfNeeded()
        alert.show()
    }

    @objc func songSelectorBtnClick() {
        if !viewModel.updateNetworkSuccessed {
            viewModel.viewResponder?.showToast(message: .updateNetworkFailedText)
            return
        }
        if !viewModel.isOwner {
            viewModel.viewResponder?.showToast(message: .onlyOwnerText)
            return
        }
        viewModel.showSongSelectorAlert()
    }
    
    @objc func startChorusBtnClick() {
        if viewModel.isOwner {
            if let musicModel = viewModel.currentMusicModel {
                startChorusBtn.isHidden = true
                musicModeSegmented.isHidden = false
                lyricsView.isHidden = false
                updateSongEffectBtnConstraints(isHidden: false)
                viewModel.effectViewModel.playMusic(musicModel)
                isStartChorus = true
            }
        }
    }
    
    func checkBtnShouldHidden() {
        if viewModel.userType == .audience {
            musicModeSegmented.isHidden = true
            updateSongEffectBtnConstraints(isHidden: true)
        } else {
            if isStartChorus {
                musicModeSegmented.isHidden = false
                updateSongEffectBtnConstraints(isHidden: false)
            }
        }
    }
    
    // 上下麦更新面板
    func updateStartChorusViewState() {
        if viewModel.userType == .anchor {
            if musicModeSegmented.isHidden {
                musicModeSegmented.isHidden = false
                updateSongEffectBtnConstraints(isHidden: false)
            }
        } else {
            if !musicModeSegmented.isHidden {
                musicModeSegmented.isHidden = true
                updateSongEffectBtnConstraints(isHidden: true)
            }
        }
    }
    
    // 歌曲下载成功后更新开始合唱按钮
    func updateChorusBtnStatus(musicId: String) {
        guard let currentMusicModel = viewModel.currentMusicModel else {
            TRTCLog.out("___ currentMusicModel is nil")
            return
        }

        if currentMusicModel.getMusicId() == musicId {
            startChorusBtnLayer.colors = [UIColor.tui_color(withHex: "FF88DD").cgColor, UIColor.tui_color(withHex: "7D00BD").cgColor]
            startChorusBtn.isUserInteractionEnabled = true
        } else {
            TRTCLog.out("___ currentMusicModel.music.getMusicId() is \(currentMusicModel.getMusicId()), musicId = \(musicId)")
        }
    }
    
    func updateLrcView(lrcString: String?) {
        if URL(fileURLWithPath: lrcString ?? "") != lyricsView.lrcFileUrl {
            lyricsView.resetLyricsViewStatus()
            musicTimeLabel.text = "00:00"
            musicTimeLabel.isHidden = true
        }
        if let lrcString = lrcString {
            if lyricsView.lrcFileUrl == URL(fileURLWithPath: lrcString) {
                debugPrint("same lrcFileUrl")
                return
            }
            lyricsView.resetLyricsViewStatus()
            lyricsView.lrcFileUrl = URL(fileURLWithPath: lrcString)
        } else {
            lyricsView.lrcFileUrl = nil
            lyricsView.isHidden = true
            lyricsView.resetLyricsViewStatus()
            musicTimeLabel.text = "00:00"
            musicTimeLabel.isHidden = true
        }
    }

    func updateMusicDetail(hidden: Bool) {
        musicNameContainerView.isHidden = hidden
        musicIcon.isHidden = hidden
        if viewModel.effectViewModel.musicSelectedList.count == 0 {
            songSelectorBtn.isHidden = !hidden
        } else {
            songSelectorBtn.isHidden = true
        }
        if viewModel.isOwner && !isStartChorus {
            startChorusBtn.isHidden = hidden
        }
        if startChorusBtn.isHidden {
            lyricsView.isHidden = hidden
        }
    }
}

extension TRTCMusicPanelView: TRTCKaraokeSoundEffectViewResponder {
    
    func onMusicAccompanimentModeChanged(musicId: String, isOrigin: Bool) {
        // 传入model层的musicId 其实对应的是外部的performId
        if viewModel.currentMusicModel?.performId == musicId {
            musicModeSegmented.updateSelectedIndex(index: isOrigin ? 1 : 0, animate: true)
        }
    }
    
    func onReceiveStartChorusCmd(musicId: String) {
        updateStartChorusViewState()
    }
    
    func onSelectedMusicListChanged() {
        viewModel.notiSelectedMusicListChange()
    }

    func onMusicListChanged() {
        viewModel.notiMusicListChange()
    }

    func updateMusicPanel(musicInfo: KaraokeMusicInfo?) {
        updateLrcView(lrcString: musicInfo?.lyricsUrl ?? "")
        updateMusicDetail(hidden: musicInfo == nil)
        if let musicInfo = musicInfo {
            musicNameLabel.text = musicInfo.musicName
            if musicInfo.isPreloaded() {
                startChorusBtnLayer.colors = [UIColor.tui_color(withHex: "FF88DD").cgColor, UIColor.tui_color(withHex: "7D00BD").cgColor]
                startChorusBtn.isUserInteractionEnabled = true
            } else {
                startChorusBtnLayer.colors = [UIColor.gray.cgColor,UIColor.gray.cgColor]
                startChorusBtn.isUserInteractionEnabled = false
            }
        }
        
        bgView.alpha = viewModel.effectViewModel.musicSelectedList.count == 0 ? 0.5 : 1.0
        if viewModel.effectViewModel.musicSelectedList.count == 0 {
            isStartChorus = false
            musicModeSegmented.isHidden = true
            updateSongEffectBtnConstraints(isHidden: true)
        }
    }
    
    func timeStampToString(timeStamp: Double)->String {
        let date = Date(timeIntervalSince1970: timeStamp)
        dateFormatter.dateFormat = "mm:ss"
        let dateString = dateFormatter.string(for: date)
        return dateString ?? ""
    }

    func bgmOnPlaying(musicId: Int32, current: Double, total: Double) {
        if String(musicId) == viewModel.currentMusicModel?.performId {
            viewModel.effectViewModel.checkHasHeadset()
            musicTimeLabel.isHidden = false
            musicTimeLabel.text = "\(timeStampToString(timeStamp: current))/\(timeStampToString(timeStamp: total))"
            lyricsView.currentTime = current
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
    
    func onStartChorusBtnClick() {
        if isStartChorus {
            guard let musicModel = viewModel.currentMusicModel, musicModel.isPreloaded() else {
                return
            }
            startChorusBtnClick()
        }
    }
}

// Layout
extension TRTCMusicPanelView {
    func constructViewHierarchy() {
        addSubview(bgView)
        
        addSubview(musicIcon)
        addSubview(musicNameContainerView)
        
        musicNameContainerView.addSubview(musicNameLabel)
        musicNameContainerView.addSubview(musicNameActionImageView)
        
        addSubview(musicTimeLabel)
        addSubview(musicModeSegmented)

        addSubview(soundEffectBtn)
        addSubview(containerView)
        addSubview(startChorusBtn)
        addSubview(songSelectorBtn)
        addSubview(lyricsView)
    }

    func activateConstraints() {
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        musicIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(12)
        }
        musicNameContainerView.snp.makeConstraints { make in
            make.leading.equalTo(musicIcon.snp.trailing).offset(2)
            make.centerY.equalTo(musicIcon)
        }
        musicNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        musicNameActionImageView.snp.makeConstraints { make in
            make.leading.equalTo(musicNameLabel.snp.trailing).offset(2)
            make.right.equalToSuperview()
            make.centerY.equalTo(musicNameLabel.snp.centerY)
        }
        musicTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(musicIcon.snp.leading)
            make.top.equalTo(musicNameLabel.snp.bottom).offset(2)
        }
        containerView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(CGSize(width: 0, height: 38))
        }
        startChorusBtn.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 76, height: 38))
        }
        songSelectorBtn.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 76, height: 38))
        }
        soundEffectBtn.snp.makeConstraints { (make) in
            make.trailing.equalTo(containerView.snp.leading)
            make.centerY.equalTo(containerView)
            make.size.equalTo(CGSize(width: 60, height: 32))
        }
        musicModeSegmented.snp.makeConstraints { make in
            make.trailing.equalTo(containerView.snp.leading)
            make.centerY.equalTo(containerView)
        }
        lyricsView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(60)
        }
    }

    func bindInteraction() {
        soundEffectBtn.addTarget(self, action: #selector(soundEffectBtnClick), for: .touchUpInside)
        songSelectorBtn.addTarget(self, action: #selector(songSelectorBtnClick), for: .touchUpInside)
        startChorusBtn.addTarget(self, action: #selector(startChorusBtnClick), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(musicNameActionTap(tap:)))
        musicNameContainerView.addGestureRecognizer(tap)
    }
    
    func updateSongEffectBtnConstraints(isHidden: Bool) {
        if isHidden {
            soundEffectBtn.snp.remakeConstraints { (make) in
                make.trailing.equalTo(containerView.snp.leading)
                make.centerY.equalTo(containerView)
                make.size.equalTo(CGSize(width: 60, height: 32))
            }
        } else {
            soundEffectBtn.snp.remakeConstraints { (make) in
                make.trailing.equalTo(musicModeSegmented.snp.leading).offset(-10)
                make.centerY.equalTo(containerView)
                make.size.equalTo(CGSize(width: 60, height: 32))
            }
        }
    }
    
    @objc func musicNameActionTap(tap: UITapGestureRecognizer) {
        if viewModel.isOwner {
            viewModel.viewResponder?.onManageSongBtnClick()
        } else {
            viewModel.viewResponder?.showToast(message: .onlyOwnerText)
        }
    }
}

extension TRTCMusicPanelView: TRTCKaraokeMusicModeSegmentedDelegate {
    func onSegemendSelecedIndex(index: Int) {
        viewModel.Karaoke.switchMusicAccompanimentMode(isOriginal: index == 1 ? true : false)
        viewModel.effectViewModel.isOriginalVolume = index == 1 ? true : false
    }
}

// MARK: - internationalization string
fileprivate extension String {
    static let songSelectorText = karaokeLocalize("Demo.TRTC.Karaoke.selectsong")
    static let seatIndexText = karaokeLocalize("Demo.TRTC.Karaoke.xxmic")
    static let startChorusText = karaokeLocalize("Demo.TRTC.Chorus.StartChorus")
    static let updateNetworkFailedText = karaokeLocalize("Demo.TRTC.Karaoke.updateNetworkFailed")
    static let soundEffectText = karaokeLocalize("Demo.TRTC.Chorus.SoundEffects")
    static let musicOriginalText = karaokeLocalize("Demo.TRTC.Chorus.musicOriginal")
    static let musicAccompanimentText = karaokeLocalize("Demo.TRTC.Chorus.musicAccompaniment")
    static let notInSeatText = karaokeLocalize("Demo.TRTC.Karaoke.onlyanchorcanoperation")
    static let onlyOwnerText = karaokeLocalize("Demo.TRTC.Karaoke.onlyownercanoperation")
}

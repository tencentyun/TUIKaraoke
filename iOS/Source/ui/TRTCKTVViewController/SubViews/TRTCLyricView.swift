//
//  TRTCLyricView.swift
//  TUIKaraoke
//
//  Created by gg on 2021/6/24.
//

import Foundation

class TRTCLyricView: UIView {
    public var currentMusicID: Int32 = 0
    private var isRequestSelectedMusicList: Bool = false
    lazy var bgView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "lkyric_bg", in: KaraokeBundle(), compatibleWith: nil))
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
        let imageView = UIImageView(image: UIImage(named: "musicIcon", in: KaraokeBundle(), compatibleWith: nil))
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

    // 原生或者伴奏切换
    lazy var originalOrAccompanyChangeBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "room_original_icon", in: KaraokeBundle(), compatibleWith: nil), for: .normal)
        btn.setImage(UIImage(named: "room_accompany_icon", in: KaraokeBundle(), compatibleWith: nil), for: .selected)
        btn.adjustsImageWhenHighlighted = false
        return btn
    }()

    lazy var voiceChangeBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "voiceChange_kongling_nor", in: KaraokeBundle(), compatibleWith: nil), for: .normal)
        btn.adjustsImageWhenHighlighted = false
        return btn
    }()

    lazy var soundEffectBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "tuning", in: KaraokeBundle(), compatibleWith: nil), for: .normal)
        btn.adjustsImageWhenHighlighted = false
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

    public lazy var lrcView: TUIVTTView = {
        let view = TUIVTTView()
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let selectBtnLayer = songSelectorBtn.gradient(colors: [UIColor(hex: "FF88DD")!.cgColor, UIColor(hex: "7D00BD")!.cgColor])
        selectBtnLayer.startPoint = CGPoint(x: 0, y: 0.5)
        selectBtnLayer.endPoint = CGPoint(x: 1, y: 0.5)
        songSelectorBtn.layer.cornerRadius = songSelectorBtn.frame.height * 0.5
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
        config(music: viewModel.effectViewModel.currentPlayingModel)
    }

    func config(music: KaraokeMusicModel?) {
        if let music = music {
            if currentMusicID != music.musicID {
                setMusicDetail(show: true)
                originalOrAccompanyChangeBtn.isHidden = !(music.music.userId == TRTCKaraokeIMManager.shared.curUserID)
                seatIndexLabel.text = LocalizeReplaceXX(.seatIndexText, "\(music.seatIndex + 1)")
                userNameLabel.text = music.bookUserName
                musicNameLabel.text = music.musicName
                currentMusicID = music.musicID
                lrcView.lrcFileUrl = URL(fileURLWithPath: music.lrcUrl)
            }
        } else {
            currentMusicID = 0
            setMusicDetail(show: false)
            lrcView.lrcFileUrl = nil
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
            } else {
                songSelectorBtn.snp.remakeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.top.equalTo(self.snp.centerY).offset(10)
                    make.size.equalTo(CGSize(width: 76, height: 38))
                }
            }
            songSelectorBtn.setNeedsLayout()
        }
        lrcView.isHidden = !show
        seatIndexLabel.isHidden = !show
        userNameLabel.isHidden = !show
        musicNameLabel.isHidden = !show
        musicIcon.isHidden = !show
        voiceChangeBtn.isHidden = !show
        originalOrAccompanyChangeBtn.isHidden = !show
        soundEffectBtn.isHidden = !show
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
        originalOrAccompanyChangeBtn.isSelected = !originalOrAccompanyChangeBtn.isSelected
        viewModel.Karaoke.switchToOriginalVolume(isOriginal: !originalOrAccompanyChangeBtn.isSelected)
    }
}

extension TRTCLyricView: TRTCKaraokeSoundEffectViewResponder {
    func onSelectedMusicListChanged() {
        songSelectorAlert.reloadSelectedSongView(dataSource: viewModel.effectViewModel.musicSelectedList)
    }

    func onMusicListChanged() {
        songSelectorAlert.reloadSongSelectorView(dataSource: viewModel.effectViewModel.musicList)
    }

    func bgmOnPrepareToPlay(performId: Int32) {
        guard performId != 0 else {
            config(music: nil)
            return
        }
        var model: KaraokeMusicModel?
        if let current = viewModel.effectViewModel.currentPlayingModel {
            if current.musicID == performId {
                model = current
            }
        }
        if model == nil {
            for selected in viewModel.effectViewModel.musicSelectedList {
                if selected.music.performId == String(performId) {
                    model = selected
                    break
                }
            }
        }
        if model == nil {
            for music in viewModel.effectViewModel.musicList {
                if music.music.performId == String(performId) {
                    model = music
                    break
                }
            }
        }
        if model != nil {
            model?.seatIndex = viewModel.getSeatIndexByUserId(userId: model?.music.userId ?? "")
            let seatUser = viewModel.getSeatUserByUserId(userId: model?.music.userId ?? "")
            model?.bookUserName = seatUser?.userName ?? ""
            model!.bookUserAvatar = seatUser?.userAvatar ?? ""
            config(music: model)
        }
    }

    func bgmOnPlaying(performId: Int32, current: Double, total: Double) {
        if performId == currentMusicID {
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
}

// Layout
extension TRTCLyricView {
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
        addSubview(songSelectorBtn)

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

        songSelectorBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(CGSize(width: 76, height: 38))
        }
        soundEffectBtn.snp.makeConstraints { make in
            make.trailing.equalTo(songSelectorBtn.snp.leading).offset(-10)
            make.centerY.equalTo(songSelectorBtn)
            make.size.equalTo(CGSize(width: 32, height: 32))
        }
        voiceChangeBtn.snp.makeConstraints { make in
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
        originalOrAccompanyChangeBtn.addTarget(self, action: #selector(originalOrAccompanyChangeBtnClick), for: .touchUpInside)
    }
}

// MARK: - internationalization string

fileprivate extension String {
    static let songSelectorText = KaraokeLocalize("Demo.TRTC.Karaoke.selectsong")
    static let voiceChangeTitleText = KaraokeLocalize("ASKit.MainMenu.VoiceChangeTitle")
    static let placeholderText = KaraokeLocalize("Demo.TRTC.Karaoke.nosongs")
    static let seatIndexText = KaraokeLocalize("Demo.TRTC.Karaoke.xxmic")
}

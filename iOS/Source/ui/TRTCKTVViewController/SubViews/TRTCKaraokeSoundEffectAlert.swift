//
//  TRTCKaraokeSoundEffectAlert.swift
//  TXLiteAVDemo
//
//  Created by gg on 2021/3/30.
//  Copyright © 2021 Tencent. All rights reserved.
//

import Foundation

enum AudioEffectType {
    case audition // 试听
    case musicVolume // 音乐音量
    case vocalVolume // 人声音量
    case vocalRiseFall // 人声升降调
    case voiceChange // 变声
    case reverberation // 混响
}

enum EffectType {
    case voiceChange
    case soundEffect
}

// MARK: - Sound Effect
class TRTCKaraokeSoundEffectAlert : TRTCKaraokeAlertContentView {
    
    var dataSource : [AudioEffectType] = []
    
    lazy var helpBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "helpUrl", in: karaokeBundle(), compatibleWith: nil), for: .normal)
        btn.isHidden = true
        return btn
    }()
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        return tableView
    }()
    
    let effectViewModel : TRTCKaraokeSoundEffectViewModel
    
    var totalHeight = 0
    
    let effectType: EffectType
    
    init(frame: CGRect = .zero, viewModel: TRTCKaraokeViewModel, effectType: EffectType) {
        self.effectViewModel = viewModel.effectViewModel
        self.effectType = effectType
        super.init(viewModel: viewModel)
        
        titleLabel.text = .effectTitleText
        
        if effectType == .voiceChange {
            dataSource = [.voiceChange]
            totalHeight = 80
        }
        else {
            dataSource = [.audition, .musicVolume, .vocalVolume, .vocalRiseFall, .reverberation, .voiceChange]
            totalHeight = 52 * 4 + 120 * 2
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    override func constructViewHierarchy() {
        super.constructViewHierarchy()
        contentView.addSubview(helpBtn)
        contentView.addSubview(tableView)
    }
    
    override func activateConstraints() {
        super.activateConstraints()
        helpBtn.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.trailing).offset(4)
            make.centerY.equalTo(titleLabel)
        }
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(totalHeight + 20)
        }
    }
    
    override func bindInteraction() {
        super.bindInteraction()
        
        helpBtn.addTarget(self, action: #selector(helpBtnClick), for: .touchUpInside)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TRTCKaraokeSoundEffectCollectionCell.self, forCellReuseIdentifier: "TRTCKaraokeSoundEffectCollectionCell")
        tableView.register(TRTCKaraokeSoundEffectSwitchCell.self, forCellReuseIdentifier: "TRTCKaraokeSoundEffectSwitchCell")
        tableView.register(TRTCKaraokeSoundEffectDetailCell.self, forCellReuseIdentifier: "TRTCKaraokeSoundEffectDetailCell")
        tableView.register(TRTCKaraokeSoundEffectSliderCell.self, forCellReuseIdentifier: "TRTCKaraokeSoundEffectSliderCell")
        tableView.register(TRTCKaraokeSoundEffectPlayingCell.self, forCellReuseIdentifier: "TRTCKaraokeSoundEffectPlayingCell")
    }
    
    @objc func helpBtnClick() {
        
    }
}
extension TRTCKaraokeSoundEffectAlert : UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = dataSource[indexPath.row]
        switch type {
        case .audition:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TRTCKaraokeSoundEffectSwitchCell", for: indexPath)
            if let scell = cell as? TRTCKaraokeSoundEffectSwitchCell {
                scell.titleLabel.text = .auditionText
                scell.descLabel.text = .bringHeadphoneText
                scell.onOff.isOn = self.viewModel.voiceEarMonitor
                scell.valueChanged = { [weak self] (isOn) in
                    guard let `self` = self else { return }
                    self.viewModel.voiceEarMonitor = isOn
                }
            }
            return cell
        case .musicVolume:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TRTCKaraokeSoundEffectSliderCell", for: indexPath)
            if let scell = cell as? TRTCKaraokeSoundEffectSliderCell {
                scell.titleLabel.text = .musicVolumeText
                scell.set(100, 0, Float(effectViewModel.musicVolume))
                scell.valueChanged = { [weak self] (current) in
                    guard let `self` = self else { return }
                    self.effectViewModel.setVolume(music: Int(current))
                }
            }
            return cell
        case .vocalVolume:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TRTCKaraokeSoundEffectSliderCell", for: indexPath)
            if let scell = cell as? TRTCKaraokeSoundEffectSliderCell {
                scell.titleLabel.text = .vocalVolumeText
                scell.set(100, 0, Float(effectViewModel.voiceVolume))
                scell.valueChanged = { [weak self] (current) in
                    guard let `self` = self else { return }
                    self.effectViewModel.setVolume(voice: Int(current))
                }
            }
            return cell
        case .vocalRiseFall:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TRTCKaraokeSoundEffectSliderCell", for: indexPath)
            if let scell = cell as? TRTCKaraokeSoundEffectSliderCell {
                scell.titleLabel.text = .vocalRiseFallText
                scell.set(1, -1, Float(effectViewModel.musicPitch))
                scell.valueChanged = { [weak self] (current) in
                    guard let `self` = self else { return }
                    self.effectViewModel.setMusic(pitch: Double(current))
                }
            }
            return cell
        case .voiceChange:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TRTCKaraokeSoundEffectCollectionCell", for: indexPath)
            if let scell = cell as? TRTCKaraokeSoundEffectCollectionCell {
                scell.dataSource = effectViewModel.voiceChangeDataSource
                scell.titleLabel.text = .voiceChangeText
            }
            return cell
        case .reverberation:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TRTCKaraokeSoundEffectCollectionCell", for: indexPath)
            if let scell = cell as? TRTCKaraokeSoundEffectCollectionCell {
                scell.dataSource = effectViewModel.reverbDataSource
                scell.titleLabel.text = .reverbText
            }
            return cell
            
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let type = dataSource[indexPath.row]
        if type == .reverberation || type == .voiceChange {
            return 120
        } else {
            return 52
        }
    }
    func string2Display(second: Int) -> String {
        let min = second / 60
        let sec = second % 60
        return "\(string(fromSecond: min)):\(string(fromSecond: sec))"
    }
    func string(fromSecond: Int) -> String {
        if fromSecond > 9 {
            return String(fromSecond)
        }
        else {
            return "0\(fromSecond)"
        }
    }
}

// MARK: - Cells
class TRTCKaraokeSoundEffectBaseCell: UITableViewCell {
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Medium", size: 16)
        label.textColor = .white
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }
    func constructViewHierarchy() {
        contentView.addSubview(titleLabel)
    }
    func activateConstraints() {
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(12)
        }
    }
    func bindInteraction() {
        
    }
}

class TRTCKaraokeSoundEffectSwitchCell: TRTCKaraokeSoundEffectBaseCell {
    
    public var valueChanged: ((_ isOn: Bool)->())?
    
    lazy var descLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 12)
        label.textColor = UIColor.init(white: 1, alpha: 0.6)
        label.adjustsFontSizeToFitWidth = true
        label.numberOfLines = 2
        return label
    }()
    
    lazy var onOff: UISwitch = {
        let onoff = UISwitch(frame: .zero)
        onoff.onTintColor = UIColor.tui_color(withHex: "F95F91")
        return onoff
    }()
    
    override func constructViewHierarchy() {
        super.constructViewHierarchy()
        contentView.addSubview(descLabel)
        contentView.addSubview(onOff)
    }
    override func activateConstraints() {
        super.activateConstraints()
        titleLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-12)
        }
        descLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            make.centerY.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(onOff.snp.leading)
        }
        onOff.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(titleLabel)
        }
    }
    override func bindInteraction() {
        super.bindInteraction()
        onOff.addTarget(self, action: #selector(switchValueChanged(sender:)), for: .valueChanged)
    }
    
    @objc func switchValueChanged(sender: UISwitch) {
        if let action = valueChanged {
            action(sender.isOn)
        }
    }
}

class TRTCKaraokeSoundEffectSlider: UISlider {
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let edge = CGFloat(4)
        var rect = rect
        rect.origin.x -= edge
        rect.size.width += 2 * edge
        return super.thumbRect(forBounds: bounds, trackRect: rect, value: value).insetBy(dx: edge, dy: edge)
    }
}

class TRTCKaraokeSoundEffectSliderCell: TRTCKaraokeSoundEffectBaseCell {
    
    public var valueChanged : ((_ value: Float)->())?
    
    public var maxValue : Float = 0 {
        didSet {
            slider.maximumValue = maxValue
        }
    }
    public var minValue : Float = 0 {
        didSet {
            slider.minimumValue = minValue
        }
    }
    public var currentValue : Float = 0 {
        didSet {
            slider.value = currentValue
        }
    }
    
    public func set(_ max: Float, _ min: Float, _ current: Float) {
        maxValue = max
        minValue = min
        currentValue = current
        updateSlider()
    }
    
    lazy var slider: TRTCKaraokeSoundEffectSlider = {
        let slider = TRTCKaraokeSoundEffectSlider(frame: .zero)
        slider.setThumbImage(UIImage(named: "Slider", in: karaokeBundle(), compatibleWith: nil), for: .normal)
        slider.minimumTrackTintColor = UIColor.tui_color(withHex: "F95F91")
        slider.maximumTrackTintColor = UIColor.tui_color(withHex: "F4F5F9")
        return slider
    }()
    
    lazy var valueLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Medium", size: 16)
        label.textColor = .white
        return label
    }()
    
    override func constructViewHierarchy() {
        super.constructViewHierarchy()
        contentView.addSubview(slider)
        contentView.addSubview(valueLabel)
    }
    override func activateConstraints() {
        super.activateConstraints()
        titleLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-12)
            make.trailing.lessThanOrEqualTo(slider.snp.leading).offset(-8)
        }
        valueLabel.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(titleLabel)
            make.width.equalTo(convertPixel(w: 50))
        }
        slider.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(convertPixel(w: 110))
            make.centerY.equalTo(titleLabel)
            make.trailing.equalTo(valueLabel.snp.leading).offset(-10)
        }
    }
    override func bindInteraction() {
        super.bindInteraction()
        slider.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .valueChanged)
    }
    
    @objc func sliderValueChanged(sender: UISlider) {
        updateSlider()
        if let action = valueChanged {
            action(slider.value)
        }
    }
    
    private func updateSlider() {
        if slider.maximumValue == 1 && slider.minimumValue == -1 {
            valueLabel.text = String(format: "%.2f", slider.value)
        }
        else {
            valueLabel.text = String(Int(slider.value))
        }
    }
}

class TRTCKaraokeSoundEffectPlayingCell: TRTCKaraokeSoundEffectBaseCell {
    lazy var timeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .black
        return label
    }()
    lazy var playBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "bgm_play", in: karaokeBundle(), compatibleWith: nil), for: .normal)
        btn.setImage(UIImage(named: "bgm_pause", in: karaokeBundle(), compatibleWith: nil), for: .selected)
        return btn
    }()
    
    public var playBtnDidClick: (()->())?
    
    override func constructViewHierarchy() {
        super.constructViewHierarchy()
        contentView.addSubview(playBtn)
        contentView.addSubview(timeLabel)
    }
    override func activateConstraints() {
        super.activateConstraints()
        titleLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-12)
        }
        playBtn.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(titleLabel)
        }
        timeLabel.snp.makeConstraints { (make) in
            make.trailing.equalTo(playBtn.snp.leading).offset(-10)
            make.centerY.equalTo(titleLabel)
        }
    }
    override func bindInteraction() {
        super.bindInteraction()
        playBtn.addTarget(self, action: #selector(playBtnClick), for: .touchUpInside)
    }
    
    @objc func playBtnClick() {
        if let action = playBtnDidClick {
            action()
        }
    }
}

class TRTCKaraokeSoundEffectDetailCell: TRTCKaraokeSoundEffectBaseCell {
    lazy var arrowImageView: UIImageView = {
        let imageV = UIImageView(image: UIImage(named: "detail", in: karaokeBundle(), compatibleWith: nil))
        return imageV
    }()
    
    lazy var descLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 16)
        label.textColor = UIColor.tui_color(withHex: "999999")
        return label
    }()
    
    override func constructViewHierarchy() {
        super.constructViewHierarchy()
        contentView.addSubview(descLabel)
        contentView.addSubview(arrowImageView)
    }
    override func activateConstraints() {
        super.activateConstraints()
        titleLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-12)
        }
        arrowImageView.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalTo(titleLabel)
        }
        descLabel.snp.makeConstraints { (make) in
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(8)
            make.centerY.equalTo(titleLabel)
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-10)
        }
    }
    override func bindInteraction() {
        super.bindInteraction()
        
    }
}

class TRTCKaraokeSoundEffectCollectionCell: TRTCKaraokeSoundEffectBaseCell {
    
    var currentSelect: Int = 0
    
    var dataSource : [TRTCAudioEffectCellModel] = [] {
        didSet {
            for (i, model) in dataSource.enumerated() {
                if model.selected {
                    currentSelect = i
                    break
                }
            }
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            collectionView.selectItem(at: IndexPath(item: currentSelect, section: 0), animated: true, scrollPosition: .left)
        }
    }
    
    private var isHideTitleLabel = false
    private var isViewReady = false
    func hideTitleLabel() {
        isHideTitleLabel = true
        if isViewReady {
            collectionView.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().offset(12)
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(75)
            }
        }
    }
    
    override func constructViewHierarchy() {
        super.constructViewHierarchy()
        contentView.addSubview(collectionView)
    }
    override func activateConstraints() {
        super.activateConstraints()
        if isHideTitleLabel {
            collectionView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(12)
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(75)
            }
        }
        else {
            collectionView.snp.makeConstraints { (make) in
                make.top.equalTo(titleLabel.snp.bottom).offset(10)
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(75)
            }
        }
    }
    override func bindInteraction() {
        super.bindInteraction()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TRTCKaraokeSoundEffectCellForCollectionCell.self, forCellWithReuseIdentifier: "TRTCKaraokeSoundEffectCellForCollectionCell")
        isViewReady = true
    }
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 75)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        return collectionView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension TRTCKaraokeSoundEffectCollectionCell : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TRTCKaraokeSoundEffectCellForCollectionCell", for: indexPath)
        if let scell = cell as? TRTCKaraokeSoundEffectCellForCollectionCell {
            let model = dataSource[indexPath.item]
            scell.model = model
        }
        return cell
    }
}
extension TRTCKaraokeSoundEffectCollectionCell : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = dataSource[indexPath.item]
        if let action = model.action {
            action()
        }
    }
}
class TRTCKaraokeSoundEffectCellForCollectionCell: UICollectionViewCell {
    
    var model : TRTCAudioEffectCellModel? {
        didSet {
            guard let model = model else {
                return
            }
            headImageView.image = model.icon
            headImageView.highlightedImage = model.selectIcon
            titleLabel.text = model.title
            isSelected = model.selected
        }
    }
    
    override var isSelected: Bool {
        didSet {
            guard let model = model else {
                return
            }
            model.selected = isSelected
            headImageView.isHighlighted = isSelected
            titleLabel.isHighlighted = isSelected
        }
    }
    
    lazy var headImageView: UIImageView = {
        let imageV = UIImageView(frame: .zero)
        imageV.contentMode = .scaleAspectFill
        imageV.clipsToBounds = true
        return imageV
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 12)
        label.textColor = UIColor.tui_color(withHex: "666666")
        label.highlightedTextColor = UIColor.tui_color(withHex: "006EFF")
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        contentView.addSubview(headImageView)
        contentView.addSubview(titleLabel)
        headImageView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(headImageView.snp.width)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(headImageView.snp.bottom).offset(4)
            make.leading.trailing.centerX.equalToSuperview()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        headImageView.layer.cornerRadius = headImageView.frame.height * 0.5
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// MARK: - internationalization string
fileprivate extension String {
    static let effectTitleText = karaokeLocalize("ASKit.MainMenu.Title")
    static let voiceChangeText = karaokeLocalize("ASKit.MainMenu.VoiceChangeTitle")
    static let reverbText = karaokeLocalize("ASKit.MainMenu.Reverberation")
    static let auditionText = karaokeLocalize("ASKit.MusicSelectMenu.Title")
    static let bringHeadphoneText = karaokeLocalize("Demo.TRTC.Karaoke.useearphones")
    static let copyrightText = karaokeLocalize("Demo.TRTC.Karaoke.copyrights")
    static let selectMusicText = karaokeLocalize("ASKit.MainMenu.SelectMusic")
    static let musicVolumeText = karaokeLocalize("ASKit.MainMenu.MusicVolum")
    static let vocalVolumeText = karaokeLocalize("ASKit.MainMenu.PersonVolum")
    static let vocalRiseFallText = karaokeLocalize("ASKit.MainMenu.PersonPitch")
}

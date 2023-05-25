//
//  TRTCKaraokeDashboardRemoteAudioCell.swift
//  TUIKaraoke
//
//  Created by bluedang on 2023/3/23.
//

import Foundation

class TRTCKaraokeDashboardRemoteAudioCell: UITableViewCell {
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle(.remoteAudioInfoText, size: 16)
        label.textColor = .white
        return label
    }()
    
    lazy var userIdNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("userId", size: 12)
        label.textColor = .white
        label.alpha = 0.6
        return label
    }()
    
    lazy var userIdValueLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("", size: 12)
        label.textColor = .white
        return label
    }()
    
    lazy var bitrateNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("audioBitrate", size: 12)
        label.textColor = .white
        label.alpha = 0.6
        return label
    }()
    
    lazy var bitrateValueLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("", size: 12)
        label.textColor = .white
        return label
    }()

    
    lazy var bufferDelayNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("jitterBufferDelay", size: 12)
        label.textColor = .white
        label.alpha = 0.6
        return label
    }()

    lazy var bufferDelayValueLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("", size: 12)
        label.textColor = .white
        return label
    }()
    
    lazy var blockRateNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("audioBlockRate", size: 12)
        label.textColor = .white
        label.alpha = 0.6
        return label
    }()

    lazy var blockRateValueLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("", size: 12)
        label.textColor = .white
        return label
    }()

    
    lazy var sampleRateNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("audioSampleRate", size: 12)
        label.textColor = .white
        label.alpha = 0.6
        return label
    }()
    
    lazy var sampleRateValueLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("", size: 12)
        label.textColor = .white
        return label
    }()

    lazy var volumeNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("audioVolume", size: 12)
        label.textColor = .white
        label.alpha = 0.6
        return label
    }()
    
    lazy var volumeValueLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("", size: 12)
        label.textColor = .white
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.clear
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAudioInfo(info: TRTCRemoteStatistics) {
        let statisics = info as TRTCRemoteStatistics
        userIdValueLabel.text = statisics.userId
        sampleRateValueLabel.text = String(statisics.audioSampleRate) + "Hz"
        bitrateValueLabel.text = String(statisics.audioBitrate) + "Kbps"
        bufferDelayValueLabel.text = String(statisics.jitterBufferDelay) + "ms"
        blockRateValueLabel.text = String(statisics.audioBlockRate) + "%"
    }
    
    func setVolume(volume: UInt) {
        volumeValueLabel.text = String(volume) + "%"
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
        layer.cornerRadius = bounds.size.height * 0.5
    }

    func constructViewHierarchy() {
        addSubview(titleLabel)
        addSubview(userIdNameLabel)
        addSubview(userIdValueLabel)
        addSubview(bitrateNameLabel)
        addSubview(bitrateValueLabel)
        addSubview(bufferDelayNameLabel)
        addSubview(bufferDelayValueLabel)
        addSubview(sampleRateNameLabel)
        addSubview(sampleRateValueLabel)
        addSubview(volumeNameLabel)
        addSubview(volumeValueLabel)
        addSubview(blockRateNameLabel)
        addSubview(blockRateValueLabel)
    }

    func activateConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        userIdNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
        userIdValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(userIdNameLabel)
        }
        sampleRateNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(userIdNameLabel.snp.bottom).offset(15)
        }
        sampleRateValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(sampleRateNameLabel)
        }
        bitrateNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(sampleRateValueLabel.snp.bottom).offset(15)
        }
        bitrateValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(bitrateNameLabel)
        }
        bufferDelayNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(bitrateValueLabel.snp.bottom).offset(15)
        }
        bufferDelayValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(bufferDelayNameLabel)
        }
        blockRateNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(bufferDelayValueLabel.snp.bottom).offset(15)
        }
        blockRateValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(blockRateNameLabel)
        }
        volumeNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(blockRateValueLabel.snp.bottom).offset(15)
        }
        volumeValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(volumeNameLabel)
            make.bottom.equalToSuperview().offset(-20)
        }
    }

    func bindInteraction() {
        
    }
}

fileprivate extension String {
    static var remoteAudioInfoText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.remoteAudioInfo")
    }
}

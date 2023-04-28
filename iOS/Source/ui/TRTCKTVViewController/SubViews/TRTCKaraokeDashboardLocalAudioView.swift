//
//  TRTCKaraokeDashboardLocalAudioView.swift
//  TUIKaraoke
//
//  Created by bluedang on 2023/3/23.
//

import Foundation

class TRTCKaraokeDashboardLocalAudioView: UIView {
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle(.localAudioInfoText, size: 16)
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
    
    lazy var captureStateNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("audioCaptureState", size: 12)
        label.textColor = .white
        label.alpha = 0.6
        return label
    }()

    lazy var captureStateValueLabel: UILabel = {
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
    
    func setAudioInfo(info: TRTCLocalStatistics) {
        let statisics = info as TRTCLocalStatistics
        bitrateValueLabel.text = String(statisics.audioBitrate) + "Kbps"
        captureStateValueLabel.text = String(statisics.audioCaptureState)
        sampleRateValueLabel.text = String(statisics.audioSampleRate) + "Hz"
    }
    
    func setLocalVolume(volume: UInt) {
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
        addSubview(bitrateNameLabel)
        addSubview(bitrateValueLabel)
        addSubview(captureStateNameLabel)
        addSubview(captureStateValueLabel)
        addSubview(sampleRateNameLabel)
        addSubview(sampleRateValueLabel)
        addSubview(volumeNameLabel)
        addSubview(volumeValueLabel)
    }

    func activateConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        bitrateNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
        bitrateValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(bitrateNameLabel)
        }
        captureStateNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(bitrateNameLabel.snp.bottom).offset(15)
        }
        captureStateValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(captureStateNameLabel)
        }
        sampleRateNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(captureStateNameLabel.snp.bottom).offset(15)
        }
        sampleRateValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(sampleRateNameLabel)
        }
        volumeNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(sampleRateNameLabel.snp.bottom).offset(15)
        }
        volumeValueLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(volumeNameLabel)
            make.bottom.equalToSuperview()
        }
    }

    func bindInteraction() {
        
    }
}

fileprivate extension String {
    static let localAudioInfoText = karaokeLocalize("Demo.TRTC.Karaoke.localAudioInfo")
}

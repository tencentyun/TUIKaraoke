//
//  TRTCKaraokeDashboardAlert.swift
//  TUIKaraoke
//
//  Created by bluedang on 2023/3/22.
//  Copyright © 2022 Tencent. All rights reserved.

import Foundation
import TUICore

class TRTCKaraokeDashboardAlert: TRTCKaraokeAlertContentView {

    lazy var containerView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()

    lazy var dashboardTitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle(.dashBoardText, size: 24)
        label.textColor = .white
        return label
    }()

    lazy var networkInfoView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()

    lazy var networkTiteLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle(.networkInfoText, size: 16)
        label.textColor = .white
        return label
    }()

    lazy var netInfoStackView: UIStackView = {
        let view = UIStackView(frame: .zero)
        view.backgroundColor = .clear
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fillEqually
        view.contentMode = .scaleToFill
        return view
    }()

    private lazy var rttInfoView: NetworkInfoCell = {
        let info = NetworkInfoCell(name:"RTT", frame: .zero)
        info.backgroundColor = .clear
        return info
    }()

    private lazy var downLossInfoView: NetworkInfoCell = {
        let info = NetworkInfoCell(name:"downLoss", frame: .zero)
        info.backgroundColor = .clear
        return info
    }()

    private lazy var upLossInfoView: NetworkInfoCell = {
        let info = NetworkInfoCell(name:"upLoss", frame: .zero)
        info.backgroundColor = .clear
        return info
    }()

    private lazy var localAudioInfoView: TRTCKaraokeDashboardLocalAudioView = {
        let info = TRTCKaraokeDashboardLocalAudioView(frame: .zero)
        info.backgroundColor = .clear
        return info
    }()

    private lazy var remoteAudioTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(TRTCKaraokeDashboardRemoteAudioCell.self, forCellReuseIdentifier: "TRTCKaraokeDashboardRemoteAudioCell")

        return tableView
    }()

    private var remoteStaticsList: [TRTCRemoteStatistics] = []
    
    override init(frame: CGRect = .zero, viewModel: TRTCKaraokeViewModel) {
        super.init(viewModel: viewModel)
        titleLabel.text = ""
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getRttStatus(rtt: Int) -> NetworkInfoCell.StatusType {
        if (rtt > 100) {
            return .warning
        }
        return .normal
    }

    private func getLossStatus(loss: Int) -> NetworkInfoCell.StatusType {
        if (loss > 10) {
            return .warning
        }
        return .normal
    }

    func refreshData() {
        guard let statisics = viewModel.trtcStatisics else {
            return
        }
        
        rttInfoView.setValue(value: String(statisics.rtt) + "ms", status: getRttStatus(rtt: Int(statisics.rtt)))
        upLossInfoView.setValue(value: String(statisics.upLoss) + "%", status: getLossStatus(loss: Int(statisics.upLoss)))
        downLossInfoView.setValue(value: String(statisics.downLoss) + "%", status: getLossStatus(loss: Int(statisics.downLoss)))
        if let localStatics = statisics.localStatistics.first {
            localAudioInfoView.setAudioInfo(info: localStatics)
        } else {
            let localStatistics = TRTCLocalStatistics()
            localStatistics.audioBitrate = 0
            localStatistics.audioSampleRate = 0
            localStatistics.audioCaptureState = 0
            localAudioInfoView.setAudioInfo(info: localStatistics)
        }
        if let localVolume = viewModel.userVolumeDic[TUILogin.getUserID() ?? ""] {
            localAudioInfoView.setLocalVolume(volume: localVolume)
        }
        
        remoteStaticsList.removeAll()
        statisics.remoteStatistics.forEach { (info) in
            remoteStaticsList.append(info)
        }
        
        remoteAudioTableView.reloadData()
    }

    override func constructViewHierarchy() {
        super.constructViewHierarchy()
        contentView.addSubview(containerView)
        containerView.addSubview(dashboardTitleLabel)
        containerView.addSubview(networkInfoView)
        
        networkInfoView.addSubview(networkTiteLabel)
        networkInfoView.addSubview(netInfoStackView)
        netInfoStackView.addArrangedSubview(rttInfoView)
        netInfoStackView.addArrangedSubview(downLossInfoView)
        netInfoStackView.addArrangedSubview(upLossInfoView)
        
        containerView.addSubview(localAudioInfoView)
        containerView.addSubview(remoteAudioTableView)
    }

    override func activateConstraints() {
        super.activateConstraints()
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        dashboardTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        networkInfoView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(dashboardTitleLabel.snp.bottom).offset(20)
        }
        
        networkTiteLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }
        
        netInfoStackView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(networkTiteLabel.snp.bottom).offset(20)
        }
        
        localAudioInfoView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(networkInfoView.snp.bottom).offset(30)
        }
        
        remoteAudioTableView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.top.equalTo(localAudioInfoView.snp.bottom).offset(30)
            make.height.equalTo(230)
            make.bottom.equalToSuperview().offset(-40)
        }
    }
    override func bindInteraction() {
        super.bindInteraction()

        remoteAudioTableView.delegate = self
        remoteAudioTableView.dataSource = self
    }
}

extension TRTCKaraokeDashboardAlert : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return remoteStaticsList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TRTCKaraokeDashboardRemoteAudioCell", for: indexPath)
                
        if let cell = cell as? TRTCKaraokeDashboardRemoteAudioCell {
            cell.setAudioInfo(info: remoteStaticsList[indexPath.section])
            let userId = remoteStaticsList[indexPath.section].userId ?? ""
            if let volume = viewModel.userVolumeDic[userId] {
                cell.setVolume(volume: volume)
            } else {
                cell.setVolume(volume: 0)
            }
        }
        return cell
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
}
extension TRTCKaraokeDashboardAlert : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}


fileprivate class NetworkInfoCell: UIView {
    
    enum StatusType {
        case normal // 正常绿色
        case warning // 异常红色
    }

    lazy var valueLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("0", size: 24, fontName: "DIN")
        label.textColor = UIColor.tui_color(withHex: "47d4ab")
        return label
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.setDashBoardStyleTitle("RTT")
        label.textColor = .white
        label.alpha = 0.6
        return label
    }()

    init(name: String, frame: CGRect = .zero) {
        super.init(frame: frame)
        bindInteraction()
        self.nameLabel.text = name
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
        layer.cornerRadius = bounds.size.height * 0.5
    }
    
    func setValue(value: String, status: StatusType) {
        valueLabel.text = value
        if status == .normal {
            valueLabel.textColor = UIColor.tui_color(withHex: "47d4ab")
        }
        if status == .warning {
            valueLabel.textColor = UIColor.tui_color(withHex: "f95f91")
        }
    }

    func constructViewHierarchy() {
        addSubview(nameLabel)
        addSubview(valueLabel)
    }

    func activateConstraints() {
        valueLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(valueLabel.snp.bottom).offset(5)
        }
    }

    func bindInteraction() {
        
    }
}



extension UILabel {
    func setDashBoardStyleTitle(_ title: String, size: CGFloat = 12, fontName: String = "PingFangSC-Regular") {
        text = title
        font = UIFont(name: fontName, size: size)
        textAlignment = .center
        numberOfLines = 1
        adjustsFontSizeToFitWidth = true
        minimumScaleFactor = 0.5
    }
}

// MARK: - internationalization string

fileprivate extension String {
    static var dashBoardText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.dashboard")
    }
    static var networkInfoText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.networkInfo")
    }
}

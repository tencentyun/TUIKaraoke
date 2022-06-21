//
//  TRTCKaraokeSelectedSongTableView.swift
//  TUIKaraoke
//
//  Created by gg on 2021/6/25.
//  Copyright © 2022 Tencent. All rights reserved.

import Foundation
import Kingfisher

enum SelectedState {
    case playing
    case nextPlay
    case list
    case hide
}

enum BtnActionType {
    case top
    case next
}

class TRTCKaraokeSelectedSongTableView: UIView {
    var dataSource: [KaraokeMusicModel] {
        return viewModel.effectViewModel.musicSelectedList
    }

    func updateDataSource() {
        tableView.reloadData()
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        return tableView
    }()

    let viewModel: TRTCKaraokeViewModel
    init(viewModel: TRTCKaraokeViewModel, frame: CGRect = .zero) {
        self.viewModel = viewModel
        super.init(frame: frame)

        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isViewReady = false
    private var isClickTopOn = false
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
        addSubview(tableView)
    }

    func activateConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func bindInteraction() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TRTCKaraokeSelectedSongTableViewCell.self, forCellReuseIdentifier: "TRTCKaraokeSelectedSongTableViewCell")
    }
}

extension TRTCKaraokeSelectedSongTableView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TRTCKaraokeSelectedSongTableViewCell", for: indexPath)
        let model = dataSource[indexPath.row]
        if let scell = cell as? TRTCKaraokeSelectedSongTableViewCell {
            model.seatIndex = viewModel.getSeatIndexByUserId(userId: model.music.userId)
            let seatUser = viewModel.getSeatUserByUserId(userId: model.music.userId)
            model.bookUserName = seatUser?.userName ?? ""
            model.bookUserAvatar = seatUser?.userAvatar ?? ""
            scell.model = model
            let index = indexPath.item
            if index == 0 {
                scell.playImageView.isHidden = false
                let path = KaraokeBundle().path(forResource: "playing", ofType: "gif") ?? ""
                scell.playImageView.kf.setImage(with: URL(fileURLWithPath: path))
                scell.sortLabel.text = ""
                scell.sortLabel.isHidden = true
            } else {
                scell.playImageView.image = nil
                scell.playImageView.isHidden = true
                scell.sortLabel.text = "\(index + 1)"
                scell.sortLabel.isHidden = false
            }
            scell.selectedAction = viewModel.effectViewModel.selectedAction

            var state: SelectedState
            if viewModel.isOwner {
                switch indexPath.row {
                case 0:
                    state = .playing
                case 1:
                    state = .nextPlay
                default:
                    state = .list
                }
            } else {
                state = .hide
            }
            scell.setState(state)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        }
        if viewModel.isOwner {
            return true
        }
        let model = dataSource[indexPath.row]
        return model.music.userId == TRTCKaraokeIMManager.shared.curUserID
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard indexPath.row != 0, editingStyle == .delete else {
            return
        }

        let musicSelectedList = viewModel.effectViewModel.musicSelectedList
        if musicSelectedList.count > indexPath.row {
            let deleteModel = musicSelectedList[indexPath.row]
            viewModel.musicDataSource?.deleteMusic(musicInfo: deleteModel.music, callback: { [weak self] code, msg in
                guard let self = self else { return }
                if code != 0 {
                    self.superview?.makeToast(msg)
                }
            })
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        guard indexPath.row != 0 else {
            return ""
        }
        return .deleteText
    }
}

class TRTCKaraokeSelectedSongTableViewCell: UITableViewCell {
    public var selectedAction: ((_ v: KaraokeMusicModel, _ callBack: @escaping cellClickCallback) -> Void)?
    private var isClicking: Bool = false
    lazy var playImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        return imageView
    }()

    lazy var sortLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Medium", size: 14)
        label.textColor = .white
        return label
    }()

    lazy var headerImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        return imageView
    }()

    lazy var labelContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Medium", size: 16)
        label.textColor = .white
        return label
    }()

    lazy var authorLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 14)
        label.textColor = UIColor(white: 1, alpha: 0.6)
        return label
    }()

    lazy var micOrderLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 14)
        label.textColor = UIColor(white: 1, alpha: 0.6)
        return label
    }()

    lazy var userNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 14)
        label.textColor = UIColor(white: 1, alpha: 0.6)
        return label
    }()

    lazy var topBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.adjustsImageWhenHighlighted = false
        btn.adjustsImageWhenDisabled = false
        return btn
    }()

    var model: KaraokeMusicModel? {
        didSet {
            isClicking = false
            guard let model = model else {
                return
            }
            if let url = URL(string: model.bookUserAvatar) {
                headerImageView.kf.setImage(with: .network(url), placeholder: UIImage(named: "voiceChange_loli_sel", in: KaraokeBundle(), compatibleWith: nil))
            } else {
                headerImageView.image = UIImage(named: "voiceChange_loli_sel", in: KaraokeBundle(), compatibleWith: nil)
            }
            titleLabel.text = model.musicName
            authorLabel.text = LocalizeReplaceXX(.originSingerText, model.singer)
            micOrderLabel.text = LocalizeReplaceXX(.seatIndexText, "\(model.seatIndex + 1)")
            userNameLabel.text = model.bookUserName
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
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
        contentView.addSubview(playImageView)
        contentView.addSubview(sortLabel)
        contentView.addSubview(headerImageView)
        contentView.addSubview(labelContainerView)
        labelContainerView.addSubview(titleLabel)
        labelContainerView.addSubview(authorLabel)
        labelContainerView.addSubview(micOrderLabel)
        labelContainerView.addSubview(userNameLabel)
        contentView.addSubview(topBtn)
    }

    func activateConstraints() {
        playImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
        sortLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalTo(playImageView)
        }
        headerImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalToSuperview().offset(44)
            make.size.equalTo(CGSize(width: 64, height: 64))
        }
        topBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        labelContainerView.snp.makeConstraints { make in
            make.leading.equalTo(headerImageView.snp.trailing).offset(16)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.trailing.equalTo(topBtn.snp.leading).offset(-10)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        authorLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
            make.trailing.lessThanOrEqualToSuperview()
        }
        micOrderLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(authorLabel.snp.bottom)
            make.bottom.equalToSuperview()
        }
        userNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(micOrderLabel.snp.trailing).offset(8)
            make.top.equalTo(micOrderLabel)
        }
    }

    func bindInteraction() {
        topBtn.addTarget(self, action: #selector(topBtnClick), for: .touchUpInside)
    }

    @objc func topBtnClick() {
        if isClicking {
            return
        }
        guard let model = model else {
            return
        }
        if let action = selectedAction {
            isClicking = true
            let block: cellClickCallback = { [weak self] errorCode, errorMessage in
                guard let self = self else { return }
                if (errorCode != 0) && (errorCode != 1000) && (errorCode != 1001) && (errorCode != 1002) {
                    self.superview?.makeToast(errorMessage)
                }
                self.isClicking = false
            }
            action(model, block)
        }
    }

    func setState(_ state: SelectedState) {
        switch state {
        case .playing:
            topBtn.setImage(UIImage(named: "switchSong", in: KaraokeBundle(), compatibleWith: nil), for: .normal)
            topBtn.setImage(nil, for: .disabled)
            topBtn.isHidden = false
            topBtn.isEnabled = true
        case .nextPlay:
            topBtn.setImage(UIImage(named: "top_normal", in: KaraokeBundle(), compatibleWith: nil), for: .normal)
            topBtn.setImage(UIImage(named: "top_disable", in: KaraokeBundle(), compatibleWith: nil), for: .disabled)
            topBtn.isHidden = false
            topBtn.isEnabled = false
        case .list:
            topBtn.setImage(UIImage(named: "top_normal", in: KaraokeBundle(), compatibleWith: nil), for: .normal)
            topBtn.setImage(UIImage(named: "top_disable", in: KaraokeBundle(), compatibleWith: nil), for: .disabled)
            topBtn.isHidden = false
            topBtn.isEnabled = true
        case .hide:
            topBtn.isHidden = true
        }
    }
}

// MARK: - internationalization string

fileprivate extension String {
    static let deleteText = KaraokeLocalize("Demo.TRTC.Karaoke.delete")
    static let seatIndexText = KaraokeLocalize("Demo.TRTC.Karaoke.xxmic")
    static let originSingerText = KaraokeLocalize("Demo.TRTC.Karaoke.singerisxx")
}

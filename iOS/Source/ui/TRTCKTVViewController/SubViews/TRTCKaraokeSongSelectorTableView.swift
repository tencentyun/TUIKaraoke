//
//  TRTCKaraokeSongSelectorTableView.swift
//  TUIKaraoke
//
//  Created by gg on 2021/6/25.
//

import Foundation

class TRTCKaraokeSongSelectorTableView: UIView {
    var dataSource: [KaraokeMusicModel] {
        return viewModel.effectViewModel.musicList
    }

    func updateDataSource() {
        tableView.reloadData()
    }

    let searchContainerView: UIButton = {
        let view = UIButton(type: .custom)
        view.backgroundColor = .clear
        view.addTarget(self, action: #selector(tapToPushSearchView), for: .touchUpInside)
        return view
    }()

    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.backgroundImage = UIImage()
        searchBar.placeholder = .searchPlaceholderText
        searchBar.backgroundColor = UIColor(white: 1, alpha: 0.1)
        searchBar.barTintColor = .clear
        searchBar.returnKeyType = .search
        searchBar.layer.cornerRadius = 20
        searchBar.isUserInteractionEnabled = false
        if let textfield = searchBar.value(forKey: "searchField") as? UITextField {
            textfield.layer.cornerRadius = 22.0
            textfield.layer.masksToBounds = true
            textfield.textColor = .white
            textfield.backgroundColor = .clear
            textfield.leftViewMode = .always
        }
        searchBar.setImage(UIImage(named: "search_normal", in: KaraokeBundle(), compatibleWith: nil), for: .search, state: .normal)
        return searchBar
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.tableHeaderView = searchContainerView
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
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else {
            return
        }
        isViewReady = true
        constructViewHierarchy()
        activateConstraints()
        bindInteraction()
        tableView.reloadData()
    }

    func constructViewHierarchy() {
        addSubview(tableView)
        searchContainerView.addSubview(searchBar)
    }

    func activateConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        searchContainerView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: 68)
        searchBar.snp.makeConstraints { make in
            make.left.lessThanOrEqualTo(16)
            make.top.lessThanOrEqualTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
        }
    }

    func bindInteraction() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TRTCKaraokeSongSelectorTableViewCell.self, forCellReuseIdentifier: "TRTCKaraokeSongSelectorTableViewCell")
    }

    @objc func tapToPushSearchView() {
        let vc = TRTCKaraokeSearchViewController(viewModel: viewModel)
        vc.modalPresentationStyle = .custom
        vc.dismissCallCack = { [weak self] _ in
            guard let self = self else { return }
            self.updateDataSource()
        }
        viewModel.rootVC?.present(vc, animated: true, completion: nil)
    }
}

extension TRTCKaraokeSongSelectorTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TRTCKaraokeSongSelectorTableViewCell", for: indexPath)
        let model = dataSource[indexPath.row]
        if let scell = cell as? TRTCKaraokeSongSelectorTableViewCell {
            let userSelectedSong = viewModel.effectViewModel.userSelectedSong
            model.isSelected = userSelectedSong[model.music.getMusicId()] ?? false
            if !model.isSelected {
                model.isSelected = (viewModel.cacheSelectd.object(forKey: model.music.getMusicId() as NSString) != nil)
            }
            scell.model = model
            scell.listAction = viewModel.effectViewModel.listAction
            scell.downloadAction = viewModel.effectViewModel.downloadAction
        }
        return cell
    }
}

extension TRTCKaraokeSongSelectorTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let scell = cell as? TRTCKaraokeSongSelectorTableViewCell {
            scell.reloadSongSelectorBtnState()
        }
    }
}

class TRTCKaraokeSongSelectorTableViewCell: UITableViewCell {
    var listAction: ((_ v: KaraokeMusicModel, _ callBack: @escaping cellClickCallback) -> Void)?
    var downloadAction: ((_ musicInfo: KaraokeMusicInfo, _ progress: @escaping MusicProgressCallback, _ complete: @escaping MusicFinishCallback) -> Void)?
    lazy var headerImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Medium", size: 16)
        label.textColor = .white
        return label
    }()

    lazy var descLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC-Regular", size: 14)
        label.textColor = UIColor(white: 1, alpha: 0.6)
        return label
    }()

    lazy var songSelectBtn: UIButton = {
        let btn = UIButton(type: .custom)

        let norTitle = String.songSelectorText
        let norRange = NSRange(location: 0, length: norTitle.count)
        let norAttr = NSMutableAttributedString(string: norTitle)
        norAttr.addAttribute(.font, value: UIFont(name: "PingFangSC-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14), range: norRange)
        norAttr.addAttribute(.foregroundColor, value: UIColor.white, range: norRange)
        btn.setAttributedTitle(norAttr, for: .normal)

        let selTitle = String.selectedSongText
        let selRange = NSRange(location: 0, length: selTitle.count)
        let selAttr = NSMutableAttributedString(string: selTitle)
        selAttr.addAttribute(.font, value: UIFont(name: "PingFangSC-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14), range: selRange)
        selAttr.addAttribute(.foregroundColor, value: UIColor(white: 1, alpha: 0.4), range: selRange)
        btn.setAttributedTitle(selAttr, for: .disabled)

        btn.clipsToBounds = true
        btn.bounds.size = CGSize(width: 76, height: 38)
        return btn
    }()

    lazy var maskSongSelectBtn: UIView = {
        let btn = UIButton(type: .custom)
        let selTitle = String.selectedSongText
        let selRange = NSRange(location: 0, length: selTitle.count)
        let selAttr = NSMutableAttributedString(string: selTitle)
        selAttr.addAttribute(.font, value: UIFont(name: "PingFangSC-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14), range: selRange)
        selAttr.addAttribute(.foregroundColor, value: UIColor(hex: "7FABFC")!, range: selRange)
        btn.setAttributedTitle(selAttr, for: .normal)
        btn.layer.borderColor = UIColor(hex: "7FABFC")!.cgColor
        btn.layer.borderWidth = 1
        btn.clipsToBounds = true
        btn.bounds.size = CGSize(width: 76, height: 38)
        btn.layer.cornerRadius = btn.frame.height * 0.5
        btn.frame = btn.bounds
        let view = UIView(frame: btn.bounds)
        view.addSubview(btn)
        view.isUserInteractionEnabled = false
        view.layer.masksToBounds = true
        view.backgroundColor = .clear
        return view
    }()

    var model: KaraokeMusicModel? {
        didSet {
            guard let model = model else {
                return
            }
            headerImageView.image = UIImage(named: "music_default", in: KaraokeBundle(), compatibleWith: nil)
            titleLabel.text = model.musicName
            descLabel.text = model.singer
            songSelectBtn.isEnabled = !model.isSelected
            if model.isSelected {
                maskSongSelectBtn.alpha = 1
                if model.music.isContentReady {
                    let frame = songSelectBtn.bounds
                    maskSongSelectBtn.frame = frame
                } else {
                    var frame = self.maskSongSelectBtn.bounds
                    frame.size.width = 0
                    self.maskSongSelectBtn.frame = frame
                    if let action = downloadAction {
                        let progress: MusicProgressCallback = { [weak self] musicId, progress in
                            guard let self = self else { return }
                            if self.model?.music.getMusicId() == musicId {
                                var frame = self.maskSongSelectBtn.bounds
                                frame.size.width = self.songSelectBtn.bounds.size.width * CGFloat(progress)
                                self.maskSongSelectBtn.frame = frame
                            }
                        }
                        let complete: MusicFinishCallback = { [weak self] musicId, errorCode, _ in
                            guard let self = self else { return }
                            if self.model?.music.getMusicId() == musicId {
                                if errorCode == 0 {
                                    let frame = self.songSelectBtn.bounds
                                    self.maskSongSelectBtn.frame = frame
                                }
                            }
                        }
                        action(model.music, progress, complete)
                    }
                }
            } else {
                maskSongSelectBtn.alpha = 0
            }
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

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        songSelectBtn.layer.cornerRadius = songSelectBtn.frame.height * 0.5
    }

    func reloadSongSelectorBtnState() {
        if songSelectBtn.isEnabled {
            let selectBtnLayer = songSelectBtn.gradient(colors: [UIColor(hex: "FF88DD")!.cgColor, UIColor(hex: "7D00BD")!.cgColor])
            selectBtnLayer.startPoint = CGPoint(x: 0, y: 0.5)
            selectBtnLayer.endPoint = CGPoint(x: 1, y: 0.5)

            songSelectBtn.layer.borderWidth = 0
        } else {
            songSelectBtn.removeGradientLayer()
            songSelectBtn.layer.borderColor = UIColor(white: 1, alpha: 0.4).cgColor
            songSelectBtn.layer.borderWidth = 1
        }
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
        contentView.addSubview(headerImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)
        contentView.addSubview(songSelectBtn)
        songSelectBtn.addSubview(maskSongSelectBtn)
    }

    func activateConstraints() {
        headerImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.leading.equalToSuperview().offset(20)
            make.size.equalTo(CGSize(width: 64, height: 64))
        }
        songSelectBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 76, height: 38))
        }
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(contentView.snp.centerY)
            make.leading.equalTo(headerImageView.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualTo(songSelectBtn.snp.leading).offset(-10)
        }
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(contentView.snp.centerY)
            make.trailing.lessThanOrEqualTo(songSelectBtn.snp.leading).offset(-10)
        }
    }

    func bindInteraction() {
        songSelectBtn.addTarget(self, action: #selector(songSelectBtnClick), for: .touchUpInside)
    }

    func setSearchUi(indexPath: IndexPath) {
        let array = ["voiceChange_xionghaizi_nor","voiceChange_loli_nor","voiceChange_dashu_nor"]
        headerImageView.image = UIImage(named: array[indexPath.row%3], in: KaraokeBundle(), compatibleWith: nil)
    }

    @objc func songSelectBtnClick() {
        guard let model = model else {
            return
        }
        if let action = listAction {
            songSelectBtn.isEnabled = false
            reloadSongSelectorBtnState()
            var frame = maskSongSelectBtn.bounds
            frame.size.width = 0
            maskSongSelectBtn.frame = frame
            let block: cellClickCallback = { [weak self] errorCode, errorMessage in
                guard let self = self else { return }
                if errorCode == 0 {
                    self.songSelectBtn.isEnabled = false
                    self.reloadSongSelectorBtnState()
                    model.isSelected = true
                    let image = self.headerImageView.image
                    self.model = model
                    self.headerImageView.image = image
                } else {
                    self.songSelectBtn.isEnabled = true
                    self.reloadSongSelectorBtnState()
                    self.superview?.window?.makeToast(errorMessage)
                }
            }
            action(model, block)
        }
    }
}

// MARK: - internationalization string

fileprivate extension String {
    static let songSelectorText = KaraokeLocalize("Demo.TRTC.Karaoke.selectsong")
    static let selectedSongText = KaraokeLocalize("Demo.TRTC.Karaoke.selectedsong")
    static let permissionDeniedText = KaraokeLocalize("Permission denied")
    static let searchPlaceholderText = KaraokeLocalize("Demo.TRTC.Karaoke.searchlike")
}

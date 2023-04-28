//
//  TRTCKaraokeSongSelectorView.swift
//  TUIKaraoke
//
//  Created by gg on 2021/6/25.
//  Copyright © 2022 Tencent. All rights reserved.

import Foundation
import MJRefresh

class TRTCKaraokeSongSelectorView: UIView {
    
    var songDataSource: [KaraokeMusicInfo] {
        return viewModel.effectViewModel.musicList
    }
    
    var songTagDataSource: [KaraokeMusicTagModel] {
        return viewModel.effectViewModel.musicTagList
    }

    func updateDataSource() {
        songTableView.reloadData()
    }

    let searchContainerView: UIButton = {
        let view = UIButton(type: .custom)
        view.backgroundColor = .clear
        return view
    }()
    
    let indicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.color = .white
        view.hidesWhenStopped = false
        view.startAnimating()
        view.isHidden = true
        return view
    }()

    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.backgroundImage = UIImage()
        let attributedPlaceholderText = NSAttributedString(string: .searchPlaceholderText,
                                                           attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        searchBar.searchTextField.attributedPlaceholder = attributedPlaceholderText
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
        searchBar.setImage(UIImage(named: "search_normal", in: karaokeBundle(), compatibleWith: nil), for: .search, state: .normal)
        return searchBar
    }()

    lazy var songTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
//        let footer = MJRefreshAutoNormalFooter()
//        footer.setRefreshingTarget(self, refreshingAction: #selector(loadMoreMusicInfoListAction))
//        tableView.mj_footer = footer
        return tableView
    }()
    
    lazy var songTagView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(width: 60, height: 32)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
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
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
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
        songTagView.selectItem(at: viewModel.effectViewModel.selectedIndexPath, animated: false, scrollPosition:.top)
    }

    func constructViewHierarchy() {
        addSubview(searchContainerView)
        searchContainerView.addSubview(searchBar)
        
        addSubview(songTagView)
        addSubview(songTableView)
        addSubview(indicatorView)
    }

    func activateConstraints() {
        searchContainerView.snp.makeConstraints { make in
            make.right.left.top.equalToSuperview()
            make.height.equalTo(68)
        }
        
        searchBar.snp.makeConstraints { make in
            make.left.lessThanOrEqualTo(14)
            make.top.lessThanOrEqualTo(14)
            make.right.equalTo(-14)
            make.height.equalTo(44)
            make.centerX.equalToSuperview()
        }
        
        songTagView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchContainerView.snp.bottom)
            make.height.equalTo(40)
        }
        
        songTableView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(0)
            make.bottom.equalToSuperview()
            make.top.equalTo(songTagView.snp.bottom)
        }
        
        indicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func bindInteraction() {
        songTagView.delegate = self
        songTagView.dataSource = self
        songTagView.register(TRTCKaraokeSongTagViewCell.self, forCellWithReuseIdentifier: "TRTCKaraokeSongTagViewCell")
        
        songTableView.delegate = self
        songTableView.dataSource = self
        songTableView.register(TRTCKaraokeSongSelectorTableViewCell.self, forCellReuseIdentifier: "TRTCKaraokeSongSelectorTableViewCell")
        searchContainerView.addTarget(self, action: #selector(tapToPushSearchView), for: .touchUpInside)
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
    
//    @objc func loadMoreMusicInfoListAction() {
//        let model = songTagDataSource[viewModel.effectViewModel.selectedIndexPath.item]
//        viewModel.effectViewModel.getMusicInfoListBy(tagId: model.tagId,
//                                                     scrollToken: viewModel.effectViewModel.scrollToken,
//                                                     needCleanData: false) { [weak self] errorCode, listCount in
//            guard let self = self else { return }
//            self.songTableView.mj_footer?.endRefreshing()
//            if listCount == 0 {
//                self.songTableView.mj_footer?.endRefreshingWithNoMoreData()
//            } else {
//                self.songTableView.reloadData()
//                self.songTableView.mj_footer?.resetNoMoreData()
//            }
//        }
//    }
}

extension TRTCKaraokeSongSelectorView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TRTCKaraokeSongSelectorTableViewCell", for: indexPath)
        let model = songDataSource[indexPath.row]
        if let scell = cell as? TRTCKaraokeSongSelectorTableViewCell {
            let userSelectedSong = viewModel.effectViewModel.userSelectedSong
            model.isSelected = userSelectedSong[model.getMusicId()] ?? false
            scell.model = model
            scell.viewModel = viewModel
        }
        return cell
    }
}

extension TRTCKaraokeSongSelectorView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let scell = cell as? TRTCKaraokeSongSelectorTableViewCell {
            scell.reloadSongSelectorBtnState()
        }
    }
}

extension TRTCKaraokeSongSelectorView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return songTagDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TRTCKaraokeSongTagViewCell", for: indexPath)
        let model = songTagDataSource[indexPath.item]
        if let scell = cell as? TRTCKaraokeSongTagViewCell {
            scell.titleLabel.text = model.tagName
            scell.isSelected = viewModel.effectViewModel.selectedIndexPath.item == indexPath.item
        }
        return cell
    }
}

extension TRTCKaraokeSongSelectorView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if viewModel.effectViewModel.selectedIndexPath.item == indexPath.item { return }
        viewModel.effectViewModel.selectedIndexPath = indexPath
        viewModel.effectViewModel.scrollToken = ""
        let model = songTagDataSource[indexPath.item]
        indicatorView.isHidden = false
        viewModel.effectViewModel.getMusicInfoListBy(tagId: model.tagId,
                                                     scrollToken: viewModel.effectViewModel.scrollToken,
                                                     needCleanData: true) { [weak self] errorCode, listCount in
            guard let self = self else { return }
            self.indicatorView.isHidden = true
            if errorCode == 0 && listCount > 0 {
                self.songTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }
}

class TRTCKaraokeSongSelectorTableViewCell: UITableViewCell {
    weak var viewModel: TRTCKaraokeViewModel?
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
        selAttr.addAttribute(.foregroundColor, value: UIColor.tui_color(withHex: "F95F91"), range: selRange)
        btn.setAttributedTitle(selAttr, for: .normal)
        btn.layer.borderColor = UIColor.tui_color(withHex: "F95F91").cgColor
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

    var model: KaraokeMusicInfo? {
        didSet {
            guard let model = model else { return }
            if let coverUrl = URL(string: model.coverUrl) {
                headerImageView.sd_setImage(with: coverUrl)
            } else {
                headerImageView.image = UIImage(named: "music_default", in: karaokeBundle(), compatibleWith: nil)
            }
            titleLabel.text = model.musicName
            descLabel.text = model.singer()
            songSelectBtn.isEnabled = !model.isSelected
            if model.isSelected {
                maskSongSelectBtn.alpha = 1
                if model.isPreloaded() {
                    let frame = songSelectBtn.bounds
                    maskSongSelectBtn.frame = frame
                } else {
                    var frame = self.maskSongSelectBtn.bounds
                    frame.size.width = 0
                    self.maskSongSelectBtn.frame = frame
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
        headerImageView.roundedRect(rect: headerImageView.bounds,
                                    byRoundingCorners: .allCorners,
                                    cornerRadii: CGSize(width: 6, height: 6))
        songSelectBtn.layer.cornerRadius = songSelectBtn.frame.height * 0.5
    }

    func reloadSongSelectorBtnState() {
        if songSelectBtn.isEnabled {
            let selectBtnLayer = songSelectBtn.gradient(colors: [UIColor.tui_color(withHex: "FF88DD").cgColor,
                                                                 UIColor.tui_color(withHex: "7D00BD").cgColor,])
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
        headerImageView.image = UIImage(named: array[indexPath.row%3], in: karaokeBundle(), compatibleWith: nil)
    }

    @objc func songSelectBtnClick() {
        guard let model = model else { return }
        guard let viewModel = viewModel else { return }
        songSelectBtn.isEnabled = false
        reloadSongSelectorBtnState()
        var frame = maskSongSelectBtn.bounds
        frame.size.width = 0
        maskSongSelectBtn.frame = frame
        
        model.addMusicToPlaylist(viewModel: viewModel) { musicInfo in
        } progress: { [weak self] musicInfo, progress in
            guard let self = self else { return }
            if self.model?.getMusicId() == musicInfo?.getMusicId() {
                self.maskSongSelectBtn.alpha = 1
                var frame = self.maskSongSelectBtn.bounds
                frame.size.width = self.songSelectBtn.bounds.size.width * CGFloat(progress)
                self.maskSongSelectBtn.frame = frame
            }
        } finish: { [weak self] musicInfo, errorCode, msg in
            guard let self = self else { return }
            if self.model?.getMusicId() == musicInfo.getMusicId() {
                if errorCode == 0 {
                    let frame = self.songSelectBtn.bounds
                    self.maskSongSelectBtn.frame = frame
                    model.isSelected = true
                    let image = self.headerImageView.image
                    self.model = model
                    self.headerImageView.image = image
                } else {
                    self.maskSongSelectBtn.alpha = 0
                    self.songSelectBtn.isEnabled = true
                    self.reloadSongSelectorBtnState()
                }
            }
        }
    }
}

class TRTCKaraokeSongTagViewCell: UICollectionViewCell {
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont(name: "PingFangSC", size: 13)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                backgroundColor = UIColor(hex: "F95F91")
            } else {
                backgroundColor = UIColor.white.withAlphaComponent(0.2)
            }
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
        layer.cornerRadius = bounds.size.height * 0.5
    }

    func constructViewHierarchy() {
        contentView.addSubview(titleLabel)
    }

    func activateConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
    }

    func bindInteraction() {
        
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let att = super.preferredLayoutAttributesFitting(layoutAttributes)
        if let titleString = titleLabel.text as? NSString {
            var newFrame = titleString.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT),
                                                                height: 32),
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: [NSAttributedString.Key.font : titleLabel.font ?? UIFont.systemFont(ofSize: 14)],
                                                   context: nil)
            newFrame.size.width += 30
            newFrame.size.height = 32
            att.frame = newFrame
            return att
        }
        return att
    }
}

// MARK: - internationalization string
fileprivate extension String {
    static let songSelectorText = karaokeLocalize("Demo.TRTC.Karaoke.selectsong")
    static let selectedSongText = karaokeLocalize("Demo.TRTC.Karaoke.selectedsong")
    static let permissionDeniedText = karaokeLocalize("Permission denied")
    static let searchPlaceholderText = karaokeLocalize("Demo.TRTC.Karaoke.searchlike")
}

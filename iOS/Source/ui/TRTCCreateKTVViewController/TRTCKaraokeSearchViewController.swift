//
//  TRTCKaraokeSearchViewController.swift
//  TRTCAPP_AppStore
//
//  Created by WesleyLei on 2021/8/9.
//  Copyright © 2022 Tencent. All rights reserved.

import MJRefresh
import UIKit
public class TRTCKaraokeSearchViewController: UIViewController, UISearchBarDelegate {
    var dataSource: [KaraokeMusicModel] = []
    var dismissCallCack: ((_ data: [String: Any]) -> Void)?
    private var page: Int
    lazy var loading: UIActivityIndicatorView = {
        let loading = UIActivityIndicatorView()
        if #available(iOS 13.0, *) {
            loading.style = .large
        }
        return loading
    }()

    lazy var blurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: effect)
        return view
    }()

    let searchContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
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

    /// 搜索按钮
    lazy var searchBtn: UIButton = {
        let done = UIButton(type: .custom)
        done.setTitle(.searchBackText, for: .normal)
        done.setTitleColor(.white, for: .normal)
        done.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        done.backgroundColor = .clear
        done.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return done
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        let footer = MJRefreshAutoNormalFooter()
        footer.setRefreshingTarget(self, refreshingAction: #selector(loadMoreDataAction))
        tableView.mj_footer = footer
        footer.isHidden = true
        return tableView
    }()

    let viewModel: TRTCKaraokeViewModel
    init(viewModel: TRTCKaraokeViewModel) {
        self.viewModel = viewModel
        page = 0
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        TRTCLog.out("deinit \(type(of: self))")
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override public var prefersStatusBarHidden: Bool {
        return false
    }

    // MARK: - life cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        constructViewHierarchy()
        activateConstraints()
        bindInteraction()
    }

    override public func viewDidAppear(_ animated: Bool) {
        searchBar.becomeFirstResponder()
    }

    func constructViewHierarchy() {
        view.addSubview(blurView)
        view.addSubview(searchContainerView)
        searchContainerView.addSubview(searchBar)
        searchContainerView.addSubview(searchBtn)
        view.addSubview(tableView)
        view.addSubview(loading)
    }

    func activateConstraints() {
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        searchContainerView.snp.makeConstraints { make in
            let statusBarHeight = Int(UIApplication.shared.statusBarFrame.size.height)
            make.top.equalTo(view).offset(10 + statusBarHeight)
            make.leading.equalTo(20)
            make.trailing.equalTo(-20)
            make.height.equalTo(44)
        }
        searchBar.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.equalTo(searchBtn.snp.leading).offset(-10)
        }
        searchBtn.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.width.equalTo(60)
        }

        tableView.snp.makeConstraints { make in
            let statusBarHeight = Int(UIApplication.shared.statusBarFrame.size.height)
            make.top.equalToSuperview().offset(statusBarHeight + 50)
            make.left.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(0)
            make.bottom.equalToSuperview().offset(0)
            make.center.equalToSuperview()
        }
        loading.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.centerX.centerY.equalTo(view)
        }
    }

    func bindInteraction() {
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TRTCKaraokeSongSelectorTableViewCell.self, forCellReuseIdentifier: "TRTCKaraokeSongSelectorTableViewCell")
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        searchBar.endEditing(true)
    }

    /// 取消
    @objc func cancel() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.dismissCallCack?([:])
        }
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let input = searchBar.text, input.count > 0 {
            page = 1
            dataSource = []
            tableView.reloadData()
            searchMusic(input: input, page: page)
        }
    }

    public func searchMusic(input: String, page: Int) {
        if page == 1 {
            loading.startAnimating()
            searchBar.isUserInteractionEnabled = false
            tableView.isUserInteractionEnabled = false
            tableView.mj_footer?.isHidden = true
        }
        viewModel.musicDataSource?.ktvSearchMusicByKeyWords(offset: dataSource.count, pageSize:10,  keyWords: input, callback: { [weak self] errorCode, errorMessage, list in
            guard let self = self else { return }
            self.searchBar.isUserInteractionEnabled = true
            self.tableView.isUserInteractionEnabled = true
            self.tableView.mj_footer?.endRefreshing()
            self.loading.stopAnimating()
            if errorCode == 0 {
                if page == 1 {
                    self.dataSource = []
                }
                if list.count > 0 {
                    self.page = page + 1
                    for sourceModel in list {
                        let model = KaraokeMusicModel(sourceModel: sourceModel)
                        self.dataSource.append(model)
                    }
                    self.tableView.reloadData()
                    self.tableView.mj_footer?.resetNoMoreData()
                } else {
                    self.tableView.mj_footer?.endRefreshingWithNoMoreData()
                    if page == 1 {
                        self.view.makeToast(.searchNoResult)
                    }
                }
            } else {
                self.view.makeToast(errorMessage)
            }
            if self.dataSource.count >= 10 {
                self.tableView.mj_footer?.isHidden = false
            } else {
                self.tableView.mj_footer?.isHidden = true
            }
        })
    }

    @objc
    func loadMoreDataAction() {
        if let input = searchBar.text, input.count > 0 {
            searchMusic(input: input, page: page)
        }
    }
}

extension TRTCKaraokeSearchViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            scell.setSearchUi(indexPath: indexPath)
        }
        return cell
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }
}

extension TRTCKaraokeSearchViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let scell = cell as? TRTCKaraokeSongSelectorTableViewCell {
            scell.reloadSongSelectorBtnState()
        }
    }
}

// MARK: - internationalization string

fileprivate extension String {
    static let searchPlaceholderText = KaraokeLocalize("Demo.TRTC.Karaoke.searchlike")
    static let searchBackText = KaraokeLocalize("Demo.TRTC.LiveRoom.searchback")
    static let searchNoResult = KaraokeLocalize("Demo.TRTC.LiveRoom.searchnoresult")
}

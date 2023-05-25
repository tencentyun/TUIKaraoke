//
//  TRTCKaraokeRootView.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//
import UIKit

public enum IconTupleType : Int {
    case message = 1
    case gift
    case mute
}

class IconTuple: NSObject {
    let normal: UIImage
    let selected: UIImage
    let type: IconTupleType
    var isSelect = false
    init(normal: UIImage, selected: UIImage, type: IconTupleType) {
        self.normal = normal
        self.selected = selected
        self.type = type
        super.init()
    }
}

protocol TRTCKaraokeMainMenuDelegate: AnyObject {
    func menuView(menu: TRTCKaraokeMainMenuView, click item: IconTuple) -> Bool
    func menuView(menu: TRTCKaraokeMainMenuView, shouldClick item: IconTuple) -> Bool
}

class TRTCKaraokeMainMenuView: UIView {
    private var isViewReady: Bool = false
    private let icons: [IconTuple]
    var dataSource: [IconTuple] = []
    weak var delegate: TRTCKaraokeMainMenuDelegate?
    let viewModel: TRTCKaraokeViewModel
    /// 初始化方法
    /// - Parameters:
    ///   - frame: 视图frame
    ///   - icons: 视图菜单icons（最多5个，最少1个）
    init(frame: CGRect = .zero, icons: [IconTuple], viewModel: TRTCKaraokeViewModel) {
        icons.forEach { (tuple) in
            if tuple.type == .mute {
                tuple.isSelect = true
            }
        }
        self.icons = icons
        self.viewModel = viewModel
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("can't init this viiew from coder")
    }
    
    lazy var menuStack: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 44, height: 44)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 8, left: 20, bottom: 0, right: 0)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        return collectionView
    }()
    
    lazy var songSelectorBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(.songSelectorText, for: .normal)
        btn.setImage(UIImage(named: "musicSelect", in: karaokeBundle(), compatibleWith: nil), for: .normal)
        btn.clipsToBounds = true
        btn.titleLabel?.font = UIFont(name: "PingFangSC-Medium", size: 16)
        btn.titleLabel?.textColor = .white
        btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        return btn
    }()
    
    // MARK: - 视图的生命周期
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else {
            return
        }
        isViewReady = true
        constructViewHierarchy() // 视图层级布局
        activateConstraints() // 生成约束（此时有可能拿不到父视图正确的frame）
        bindInteraction()
    }
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let selectBtnLayer = songSelectorBtn.gradient(colors: [UIColor.tui_color(withHex:"FF88DD").cgColor,
                                                               UIColor.tui_color(withHex: "7D00BD").cgColor,])
        selectBtnLayer.startPoint = CGPoint(x: 0, y: 0.5)
        selectBtnLayer.endPoint = CGPoint(x: 1, y: 0.5)
        songSelectorBtn.layer.cornerRadius = songSelectorBtn.frame.height * 0.5
    }

    func constructViewHierarchy() {
        /// 此方法内只做add子视图操作
        addSubview(menuStack)
        menuStack.addSubview(collectionView)
        menuStack.addSubview(songSelectorBtn)
    }

    func activateConstraints() {
        /// 此方法内只给子视图做布局,使用:AutoLayout布局
        menuStack.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(52)
            make.centerY.equalToSuperview()
        }
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        songSelectorBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalTo(collectionView.snp.bottom)
            make.height.equalTo(44)
            make.width.equalTo(102)
        }
    }

    func bindInteraction() {
        /// 此方法负责做viewModel和视图的绑定操作
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TRTCKaraokeMainMenuViewCell.self, forCellWithReuseIdentifier: "TRTCKaraokeMainMenuViewCell")
        songSelectorBtn.addTarget(self, action: #selector(songSelectorBtnClick), for: .touchUpInside)
    }
    
    public func anchorType() {
        dataSource.removeAll()
        icons.forEach { (tuple) in
            if tuple.type == .message || tuple.type == .gift || tuple.type == .mute {
                tuple.isSelect = true
                dataSource.append(tuple)
            }
        }
        collectionView.reloadData()
    }
    
    public func audienceType() {
        dataSource.removeAll()
        icons.forEach { (tuple) in
            if tuple.type == .message || tuple.type == .gift {
                tuple.isSelect = true
                dataSource.append(tuple)
            }
        }
        collectionView.reloadData()
    }
    
    public func changeMixStatus(isMute: Bool) {
        collectionView.reloadData()
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
}

extension TRTCKaraokeMainMenuView : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TRTCKaraokeMainMenuViewCell", for: indexPath)
        if let scell = cell as? TRTCKaraokeMainMenuViewCell {
            scell.model = dataSource[indexPath.item]
        }
        return cell
    }
}

extension TRTCKaraokeMainMenuView : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = dataSource[indexPath.item]
        if let delegate = delegate, delegate.menuView(menu: self, click: model) {
            model.isSelect = !model.isSelect
            let cell = collectionView.cellForItem(at: indexPath)
            if let scell = cell as? TRTCKaraokeMainMenuViewCell {
                scell.select = model.isSelect
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        let model = dataSource[indexPath.item]
        guard let delegate = delegate else {
            return true
        }
        return delegate.menuView(menu: self, shouldClick: model)
    }
}

class TRTCKaraokeMainMenuViewCell: UICollectionViewCell {
    var model: IconTuple? {
        didSet {
            guard let model = model else {
                return
            }
            select = model.isSelect
        }
    }
    
    var select: Bool = false {
        didSet {
            guard let model = model else {
                return
            }
            headImageView.image = select ? model.selected : model.normal
        }
    }
    
    lazy var headImageView: UIImageView = {
        let imageV = UIImageView(frame: .zero)
        imageV.contentMode = .scaleAspectFill
        return imageV
    }()
    
    var isViewReady = false
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else {
            return
        }
        isViewReady = true
        constructViewHierarchy() // 视图层级布局
        activateConstraints() // 生成约束（此时有可能拿不到父视图正确的frame）
    }
    
    func constructViewHierarchy() {
        contentView.addSubview(headImageView)
    }

    func activateConstraints() {
        headImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}

extension UIButton {
    private struct AssociaKey{
        static var tupleTypeKey: String = "tupleTypeKey"
    }
    var tupleType : IconTupleType {
        set {
            objc_setAssociatedObject(self, &AssociaKey.tupleTypeKey, newValue.rawValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            guard let value = objc_getAssociatedObject(self, &AssociaKey.tupleTypeKey) else {
                return .message
            }
            return IconTupleType(rawValue: value as! Int) ?? IconTupleType.message
        }
    }
}

// MARK: - internationalization string

fileprivate extension String {
    static var songSelectorText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.selectsong")
    }
    static var updateNetworkFailedText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.updateNetworkFailed")
    }
    static var onlyOwnerText: String {
        karaokeLocalize("Demo.TRTC.Karaoke.onlyownercanoperation")
    }
}

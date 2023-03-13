//
//  TRTCKaraokeRootView.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//
import UIKit
import Kingfisher
import Toast_Swift

class TRTCKaraokeRootView: UIView {
    private var isViewReady: Bool = false
    let viewModel: TRTCKaraokeViewModel
    public weak var rootViewController: UIViewController?
    
    lazy var giftAnimator: TUIGiftAnimator = {
        let giftAnimator = TUIGiftAnimator.init(animationContainerView: self)
        return giftAnimator
    }()
    
    init(frame: CGRect = .zero, viewModel: TRTCKaraokeViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
        bindInteraction()
    }
    
    required init?(coder: NSCoder) {
        fatalError("can't init this viiew from coder")
    }
    
    let backgroundLayer: CALayer = {
        // fillCode
        let layer = CAGradientLayer()
        layer.colors = [UIColor.init(0x13294b).cgColor, UIColor.init(0x000000).cgColor]
        layer.locations = [0.2, 1.0]
        layer.startPoint = CGPoint(x: 0.4, y: 0)
        layer.endPoint = CGPoint(x: 0.6, y: 1.0)
        return layer
    }()
    
    lazy var bgView: UIView = {
        let bg = UIView(frame: .zero)
        return bg
    }()
    
    lazy var topView : TRTCKaraokeTopView = {
        var view = TRTCKaraokeTopView(viewModel: viewModel)
        return view
    }()
    
    lazy var musicPanelView: TRTCMusicPanelView = {
        let view = TRTCMusicPanelView(viewModel: viewModel)
        return view
    }()
    
    let seatCollection: UICollectionView = {
        let layout = UICollectionViewFlowLayout.init()
        layout.itemSize = CGSize.init(width: 60, height: 78)
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 20
        layout.sectionInset = .init(top: 0, left: 20, bottom: 0, right: 20)
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView.init(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TRTCKaraokeSeatCell.self, forCellWithReuseIdentifier: "TRTCKaraokeSeatCell")
        collectionView.backgroundColor = UIColor.clear
        return collectionView
    }()
    
    lazy var tipsView: TRTCKaraokeTipsView = {
        let view = TRTCKaraokeTipsView.init(frame: .zero, viewModel: viewModel)
        return view
    }()
    
    lazy var mainMenuView: TRTCKaraokeMainMenuView = {
        let icons: [IconTuple] = [
            IconTuple(normal: UIImage(named: "room_message", in: karaokeBundle(), compatibleWith: nil)!, selected: UIImage(named: "room_message", in: karaokeBundle(), compatibleWith: nil)!, type: .message),
            IconTuple(normal: UIImage(named: "room_leave_mic", in: karaokeBundle(), compatibleWith: nil)!, selected: UIImage(named: "room_leave_mic", in: karaokeBundle(), compatibleWith: nil)!, type: .micoff),
            IconTuple(normal: UIImage(named: "room_voice_off", in: karaokeBundle(), compatibleWith: nil)!, selected: UIImage(named: "room_voice_on", in: karaokeBundle(), compatibleWith: nil)!, type: .mute),
            IconTuple(normal: UIImage(named: "gift", in: karaokeBundle(), compatibleWith: nil)!, selected: UIImage(named: "gift", in: karaokeBundle(), compatibleWith: nil)!, type: .gift),
        ]
        icons.forEach { (icon) in
            switch icon.type {
            case .mute:
                viewModel.muteItem = icon
            default:
                break
            }
        }
        let view = TRTCKaraokeMainMenuView.init(icons: icons)
        return view
    }()
    
    lazy var msgInputView: TRTCKaraokeMsgInputView = {
        let view = TRTCKaraokeMsgInputView.init(frame: .zero, viewModel: viewModel)
        view.isHidden = true
        return view
    }()
    
    lazy var audiceneListView: TRTCKaraokeAudienceListView = {
        let view = TRTCKaraokeAudienceListView.init(viewModel: viewModel)
        view.hide()
        return view
    }()
    
    deinit {
        musicPanelView.cleanTimer()
        TRTCLog.out("reset audio settings")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let bgGradientLayer = bgView.gradient(colors: [UIColor.tui_color(withHex: "FF88DD").cgColor,
                                                       UIColor.tui_color(withHex: "1E009B").cgColor,])
        bgGradientLayer.startPoint = CGPoint(x: 0.8, y: 0)
        bgGradientLayer.endPoint = CGPoint(x: 0.2, y: 1)
    }
    
    // MARK: - 视图生命周期
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
        /// 此方法内只做add子视图操作
        backgroundLayer.frame = bounds;
        layer.insertSublayer(backgroundLayer, at: 0)
        addSubview(bgView)
        addSubview(topView)
        addSubview(musicPanelView)
        addSubview(seatCollection)
        addSubview(tipsView)
        addSubview(mainMenuView)
        addSubview(msgInputView)
        addSubview(audiceneListView)
    }

    func activateConstraints() {
        bgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        topView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
        }
        musicPanelView.snp.makeConstraints { (make) in
            make.top.equalTo(topView.snp.bottom)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        activateConstraintsOfCustomSeatArea()
        activateConstraintsOfTipsView()
        activateConstraintsOfMainMenu()
        activateConstraintsOfTextView()
        activateConstraintsOfAudiceneList()
    }

    func bindInteraction() {
        seatCollection.delegate = self
        seatCollection.dataSource = self
        /// 此方法负责做viewModel和视图的绑定操作
        mainMenuView.delegate = self
    }
}

extension TRTCKaraokeRootView: TRTCKaraokeMainMenuDelegate {
    func menuView(menu: TRTCKaraokeMainMenuView, shouldClick item: IconTuple) -> Bool {
        if item.type == .mute && !viewModel.isOwner && viewModel.mSelfSeatIndex != -1 {
            let res = !(viewModel.anchorSeatList[viewModel.mSelfSeatIndex].seatInfo?.mute ?? false)
            if !res {
                makeToast(.seatmutedText)
            }
            return res
        }
        return true
    }
    func menuView(menu: TRTCKaraokeMainMenuView, click item: IconTuple) -> Bool {
        switch item.type {
        case .message:
            // 消息框
            viewModel.openMessageTextInput()
            break
        case .mute:
            // 麦克风
            return viewModel.muteAction(isMute: item.isSelect)
        case .gift:
            showGiftAlert()
            break
        case .micoff:
            let seatIndex = viewModel.mSelfSeatIndex
            if seatIndex > 0 && seatIndex <= viewModel.anchorSeatList.count {
                viewModel.leaveSeat()
            }
            break
        }
        return false
    }
}

// MARK: - collection view delegate
extension TRTCKaraokeRootView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            /// 默认1号麦序不允许下麦
            return
        }
        let model = viewModel.anchorSeatList[indexPath.item]
        model.action?(indexPath.item) // 转换座位号输入
    }
}

extension TRTCKaraokeRootView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.anchorSeatList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TRTCKaraokeSeatCell", for: indexPath)
        let model = viewModel.anchorSeatList[indexPath.item]
        if let seatCell = cell as? TRTCKaraokeSeatCell {
            // 配置 seatCell 信息
            seatCell.setCell(model: model, userMuteMap: viewModel.userMuteMap, seatIndex: indexPath.item)
        }
        return cell
    }
}

extension TRTCKaraokeRootView {
    func activateConstraintsOfCustomSeatArea() {
        seatCollection.snp.makeConstraints { (make) in
            make.top.equalTo(musicPanelView.snp.bottom).offset(8)
            make.height.equalTo(78*2+8)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
    }
    
    func activateConstraintsOfTipsView() {
        tipsView.snp.makeConstraints { (make) in
            make.top.equalTo(seatCollection.snp.bottom).offset(8)
            make.bottom.equalTo(mainMenuView.snp.top).offset(-25)
            make.left.right.equalToSuperview()
        }
    }
    
    func activateConstraintsOfMainMenu() {
        mainMenuView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(52)
            if #available(iOS 11.0, *) {
                make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-20)
            } else {
                // Fallback on earlier versions
                make.bottom.equalToSuperview().offset(-20)
            }
        }
    }
    
    func activateConstraintsOfTextView() {
        msgInputView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
    }
    
    func activateConstraintsOfAudiceneList() {
        audiceneListView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
        
    }
}

extension TRTCKaraokeRootView: TRTCKaraokeViewResponder {
   
    func onUpdateDownloadMusic(musicId: String) {
        musicPanelView.updateChorusBtnStatus(musicId: musicId)
    }
    
    func showGiftAnimation(giftInfo: TUIGiftInfo) {
        giftAnimator.show(giftInfo: giftInfo)
    }
    
    func stopPlayBGM() {
        mainMenuView.audienceType()
    }
    
    func recoveryVoiceSetting() {
        
    }
    
    func audienceListRefresh() {
        audiceneListView.refreshList()
        topView.reloadAudienceList()
    }
    
    func onSeatMute(isMute: Bool) {
        if isMute {
            makeToast(.mutedText, duration: 0.3)
        } else {
            makeToast(.unmutedText, duration: 0.3)
            if viewModel.isSelfMute {
                return;
            }
        }
        var muteModel: IconTuple?
        for model in mainMenuView.dataSource {
            if model.type == .mute {
                muteModel = model
                break
            }
        }
        if let model = muteModel {
            model.isSelect = !isMute
        }
        mainMenuView.changeMixStatus(isMute: isMute)
    }
    
    func onAnchorMute(isMute: Bool) {
        seatCollection.reloadData()
    }
    
    func showAlert(info: (title: String, message: String),
                   sureAction: @escaping () -> Void,
                   cancelAction: (() -> Void)?) {
        let alertController = UIAlertController.init(title: info.title, message: info.message, preferredStyle: .alert)
        let sureAlertAction = UIAlertAction.init(title: .acceptText, style: .default) { (action) in
            sureAction()
        }
        let cancelAlertAction = UIAlertAction.init(title: .refuseText, style: .cancel) { (action) in
            cancelAction?()
        }
        alertController.addAction(sureAlertAction)
        alertController.addAction(cancelAlertAction)
        rootViewController?.present(alertController, animated: false, completion: {
            
        })
    }
    
    func showUpdateNetworkAlert(info: (isUpdateSuccessed: Bool, message: String), retryAction: (() -> Void)?, cancelAction: @escaping (() -> Void)) {
        let alertModel = TUIAlertModel(titleText: "",
                                       descText: info.message,
                                       cancelButtonText: info.isUpdateSuccessed ? nil : .retryText,
                                       sureButtonText: info.isUpdateSuccessed ? .acceptText : .cancelText,
                                       cancelButtonAction: retryAction,
                                       sureButtonAction: cancelAction)
        let alertView = TUIAlertView(frame: .zero)
        alertView.show(alertModel: alertModel)
    }
    
    func showActionSheet(actionTitles: [String], actions: @escaping (Int) -> Void) {
        let actionSheet = UIAlertController.init(title: .selectText, message: "", preferredStyle: .actionSheet)
        actionTitles.enumerated().forEach { (item) in
            let index = item.offset
            let title = item.element
            let action = UIAlertAction.init(title: title, style: UIAlertAction.Style.default) { (action) in
                actions(index)
                actionSheet.dismiss(animated: true, completion: nil)
            }
            actionSheet.addAction(action)
        }
        let cancelAction = UIAlertAction.init(title: .cancelText, style: .cancel) { (action) in
            actionSheet.dismiss(animated: true, completion: nil)
        }
        actionSheet.addAction(cancelAction)
        rootViewController?.present(actionSheet, animated: true, completion: nil)
    }
    
    func showGiftAlert() {
        let alert = TUIGiftPanelView.init()
        alert.parentView = self
        alert.delegate = self
        addSubview(alert)
        
        alert.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        alert.layoutIfNeeded()
        alert.show()
    }
    
    func showAudienceAlert(seat: SeatInfoModel) {
        let audienceList = viewModel.memberAudienceList
        let alert = TRTCKaraokeAudienceAlert(viewModel: viewModel, seatModel: seat, audienceList: audienceList)
        addSubview(alert)
        alert.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        alert.layoutIfNeeded()
        alert.show()
    }
    
    func showToast(message: String) {
        makeToast(message)
    }
    
    func showToastActivity(){
        makeToastActivity(.center)
    }
    
    func hiddenToastActivity() {
        hideToastActivity()
    }
    
    func popToPrevious() {
        rootViewController?.navigationController?.popViewController(animated: true)
    }
    
    func switchView(type: RoomUserType) {
        debugPrint("Began switch view")
        switch type {
        case .audience:
            viewModel.userType = .audience
            mainMenuView.audienceType()
        case .anchor:
            viewModel.userType = .anchor
            mainMenuView.anchorType()
        }
        musicPanelView.checkBtnShouldHidden()
    }
    
    func changeRoom(info: RoomInfo) {
        topView.reloadRoomInfo(info)
    }
    
    func refreshAnchorInfos() {
        refreshRoomInfo()
        seatCollection.reloadData()
    }
    
    func refreshRoomInfo() {
        topView.reloadRoomAvatar()
    }
    
    func refreshMsgView() {
        tipsView.refreshList()
    }
    
    func msgInput(show: Bool) {
        if show {
            msgInputView.showMsgInput()
        } else {
            msgInputView.hideTextInput()
        }
    }
    
    func audiceneList(show: Bool) {
        if show {
            audiceneListView.show()
        } else {
            audiceneListView.hide()
        }
    }
    
}

extension TRTCKaraokeRootView: TUIGiftPanelViewDelegate {
    func show(giftModel: TUIGiftModel) {
        giftAnimator.show(giftInfo: TUIGiftInfo.init(giftModel: giftModel, sendUser: TRTCKaraokeIMManager.shared.curUserName, sendUserHeadIcon: TRTCKaraokeIMManager.shared.curUserAvatar))
        viewModel.sendGift(giftId: giftModel.giftId) { [weak self] (code, msg) in
            if code != 0 {
                guard let `self` = self else { return }
                self.makeToast(msg)
            }
        }
    }
}

/// MARK: - internationalization string
fileprivate extension String {
    static let mutedText = karaokeLocalize("Demo.TRTC.Salon.seatmuted")
    static let unmutedText = karaokeLocalize("Demo.TRTC.Salon.seatunmuted")
    static let acceptText = karaokeLocalize("Demo.TRTC.LiveRoom.accept")
    static let retryText = karaokeLocalize("Demo.TRTC.LiveRoom.retry")
    static let refuseText = karaokeLocalize("Demo.TRTC.LiveRoom.refuse")
    static let selectText = karaokeLocalize("Demo.TRTC.Salon.pleaseselect")
    static let cancelText = karaokeLocalize("Demo.TRTC.LiveRoom.cancel")
    static let seatmutedText = karaokeLocalize("Demo.TRTC.Karaoke.onseatmuted")
}



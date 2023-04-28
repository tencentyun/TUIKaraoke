//
//  TRTCKaraokeMusicModeSegmented.swift
//  AlertKit
//
//  Created by adams on 2023/3/25.
//  Copyright © 2023 tencent. All rights reserved.
//

import UIKit

protocol TRTCKaraokeMusicModeSegmentedDelegate: NSObject {
    func onSegemendSelecedIndex(index: Int)
}

class TRTCKaraokeMusicModeSegmented: UIView {

    weak var delegate: TRTCKaraokeMusicModeSegmentedDelegate?
    
    private let viewModel: TRTCKaraokeViewModel
    
    private var items: [String]
    
    private var normalSegmentedArray: [UILabel] = []
    
    private(set) var selectedIndex = 0
    
    private lazy var segmentedViewGradientLayer: CAGradientLayer = {
        let gradientLayer = selectedSegmentedView.gradient(colors: [UIColor.tui_color(withHex:"FF88DD").cgColor,
                                                                   UIColor.tui_color(withHex:"7D00BD").cgColor,])
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        return gradientLayer
    }()
    
    private lazy var selectedSegmentedView: UIView = {
        let view = UIView(frame: .zero)
        return view
    }()

    init(frame: CGRect, items: [String], viewModel: TRTCKaraokeViewModel) {
        self.items = items
        self.viewModel = viewModel
        super.init(frame: frame)
        constructViewHierarchy()
        activateConstraints()
    }
    
    deinit {
        debugPrint("\(self) deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height * 0.5
        layer.masksToBounds = true
//        selectedSegmentedView.layer.cornerRadius = selectedSegmentedView.bounds.height * 0.5
        segmentedViewGradientLayer.colors = [UIColor.tui_color(withHex: "FF88DD").cgColor,
                                             UIColor.tui_color(withHex: "7D00BD").cgColor,]
        segmentedViewGradientLayer.cornerRadius = selectedSegmentedView.bounds.height * 0.5
    }
    
    @objc private func selectedSegmented(gestureRecognizer: UITapGestureRecognizer) {
        if !viewModel.isOwner {
            viewModel.viewResponder?.showToast(message: .onlyAnchorOperationText)
            return
        }
        
        guard let currentMusicModel = viewModel.currentMusicModel else { return }
        if currentMusicModel.accompanyUrl == "" {
            viewModel.viewResponder?.showToast(message: .noAccompanimentText)
            return
        }
        
        guard let label = gestureRecognizer.view as? UILabel else { return }
        let index = label.tag - 100
        if index == selectedIndex { return }
        selectedIndex = index
        if let delegate = delegate {
            delegate.onSegemendSelecedIndex(index: selectedIndex)
        }
        
        UIView.animate(withDuration: 0.35) {
            self.selectedSegmentedView.snp.remakeConstraints { make in
                make.left.right.top.bottom.equalTo(label)
            }
            self.layoutIfNeeded()
        }
    }
    
    func updateSelectedIndex(index: Int, animate: Bool = false) {
        if index > items.count - 1 { return }
        selectedIndex = index
        let label = normalSegmentedArray[index]
        if animate {
            UIView.animate(withDuration: 0.35) {
                self.selectedSegmentedView.snp.remakeConstraints { make in
                    make.left.right.top.bottom.equalTo(label)
                }
                self.layoutIfNeeded()
            }
        } else {
            selectedSegmentedView.snp.remakeConstraints { make in
                make.left.right.top.bottom.equalTo(label)
            }
        }
        
    }
    
    func getSelectedIndex() -> Int {
        selectedIndex
    }
}

extension TRTCKaraokeMusicModeSegmented {
    private func constructViewHierarchy() {
        backgroundColor = .white.withAlphaComponent(0.2)
        addSubview(selectedSegmentedView)
        
        for (index, item) in items.enumerated() {
            let label = UILabel(frame: .zero)
            label.text = item
            label.textColor = .white
            label.backgroundColor = .clear
            label.textAlignment = .center
            label.font = UIFont(name: "PingFangSC-Regular", size: 14)
            label.tag = 100 + index
            label.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(selectedSegmented(gestureRecognizer:)))
            label.addGestureRecognizer(tap)
            addSubview(label)
            
            label.sizeToFit()
            normalSegmentedArray.append(label)
        }
    }
    
    private func activateConstraints() {
        var labelTemp: UILabel?
        let segmentedMargin = 3
        normalSegmentedArray.forEach { label in
            if let lastLabel = labelTemp {
                label.snp.makeConstraints { make in
                    make.left.equalTo(lastLabel.snp.right)
                    make.top.bottom.height.equalTo(lastLabel)
                    make.width.equalTo(label.bounds.size.width + 15)
                    if label == normalSegmentedArray.last {
                        make.right.equalToSuperview().offset(-segmentedMargin)
                    }
                }
            } else {
                label.snp.makeConstraints { make in
                    make.left.equalToSuperview().offset(segmentedMargin)
                    make.top.equalToSuperview().offset(segmentedMargin)
                    make.bottom.equalToSuperview().offset(-segmentedMargin)
                    make.height.equalTo(label.bounds.height + 4)
                    make.width.equalTo(label.bounds.size.width + 15)
                }
                labelTemp = label
            }
        }
    }
}
 
// MARK: - internationalization string
fileprivate extension String {
    static let noAccompanimentText = karaokeLocalize("Demo.TRTC.Chorus.NoAccompaniment")
    static let onlyAnchorOperationText = karaokeLocalize("Demo.TRTC.Karaoke.onlyanchorcanoperation")
}

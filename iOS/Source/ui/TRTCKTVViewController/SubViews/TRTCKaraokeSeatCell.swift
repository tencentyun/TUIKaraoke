//
//  TRTCKaraokeSeatCell.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

import UIKit

enum TRTCKaraokeSeatCellType {
    case add
    case seat
    case lock
}

class TRTCKaraokeSeatCell: UICollectionViewCell {
    private var isViewReady: Bool = false
    
    let seatView: TRTCKaraokeSeatView = {
        let view = TRTCKaraokeSeatView()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else {
            return
        }
        isViewReady = true
        constructViewHierarchy()
        activateConstraints()
    }
    
    func constructViewHierarchy() {
        contentView.addSubview(seatView)
    }
    
    func activateConstraints() {
        seatView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
    }
    
    func setCell(model: SeatInfoModel, seatIndex: Int) {
        seatView.setSeatInfo(model: model, seatIndex: seatIndex)
    }
}

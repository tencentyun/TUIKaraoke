//
//  TUIAlertView.swift
//  AlertKit
//
//  Created by adams on 2023/2/22.
//

import UIKit

class TUIAlertView: UIView {
    
    private var isViewReady: Bool = false
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()
    
    lazy var descLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }()
    
    lazy var cancelButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setTitleColor(.systemBlue, for: .normal)
        return btn
    }()
    
    lazy var sureButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.setTitleColor(.systemBlue, for: .normal)
        return btn
    }()
    
    lazy var lineView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor(hex: "DCDCDC")
        return view
    }()
    
    var alertModel: TUIAlertModel = TUIAlertModel(titleText: "",
                                                  descText: "",
                                                  cancelButtonText: nil,
                                                  sureButtonText: nil,
                                                  cancelButtonAction: nil,
                                                  sureButtonAction: nil)
    
    // MARK: - 视图生命周期
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else {
            return
        }
        isViewReady = true
        layer.cornerRadius = 8
        layer.masksToBounds = true
        backgroundColor = UIColor(hex: "F5F5F5")
    }
    
    deinit {
        debugPrint("____ \(self) deinit")
    }
}


extension TUIAlertView {
    func show(alertModel:TUIAlertModel) {
        self.alertModel = alertModel
        titleLabel.text = alertModel.titleText
        descLabel.text = alertModel.descText
        
        addSubview(titleLabel)
        addSubview(descLabel)
        addSubview(lineView)
        
        var hasCancelBtn = false
        if let cancelButtonText = alertModel.cancelButtonText {
            cancelButton.setTitle(cancelButtonText, for: .normal)
            cancelButton.addTarget(self, action: #selector(cancelButtonClick), for: .touchUpInside)
            addSubview(cancelButton)
            
            hasCancelBtn = true
        }
        
        if let sureButtonText = alertModel.sureButtonText {
            sureButton.setTitle(sureButtonText, for: .normal)
        } else {
            sureButton.setTitle("确定", for: .normal)
        }
        
        sureButton.addTarget(self, action: #selector(sureButtonClick), for: .touchUpInside)
        addSubview(sureButton)
        
        sureButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.height.equalTo(40)
            make.bottom.equalToSuperview()
            make.top.equalTo(lineView.snp.bottom)
            if hasCancelBtn {
                make.leading.equalTo(cancelButton.snp.trailing)
            } else {
                make.leading.equalToSuperview()
            }
        }
        
        if hasCancelBtn {
            cancelButton.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.bottom.equalToSuperview()
                make.top.equalTo(lineView.snp.bottom)
                make.height.equalTo(40)
                make.width.equalTo(sureButton.snp.width)
            }
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
        }
        
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
        }
        
        lineView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(descLabel.snp.bottom).offset(20)
            make.height.equalTo(0.6)
        }
        
        UIApplication.shared.keyWindow?.addSubview(self)
        snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    func dismiss() {
        removeFromSuperview()
    }
}

extension TUIAlertView {
    @objc func cancelButtonClick() {
        if let cancelAction = alertModel.cancelButtonAction {
            cancelAction()
        }
        dismiss()
    }
    
    @objc func sureButtonClick() {
        if let sureAction = alertModel.sureButtonAction {
            sureAction()
        }
        dismiss()
    }
}

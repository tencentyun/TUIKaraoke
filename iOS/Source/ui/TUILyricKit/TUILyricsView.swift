//
//  TUILyricsView.swift
//
//  Created by adams on 2021/7/16.
//  Copyright © 2022 Tencent. All rights reserved.

import UIKit

class TUILyricsView: UIView {
    
    var lyricsInfo: TUILyricsInfo? {
        didSet {
            if lyricsInfo != nil {
                lastIndex = -1
            }
            else {
                leftView.lineInfo = nil
                rightView.lineInfo = nil
            }
        }
    }
    
    var lrcFileUrl: URL? {
        didSet {
            if let url = lrcFileUrl {
                debugPrint("___ set lrc file = \(url)")
                lyricsInfo = TUILyricParser.parserLocalLyricFile(fileURL: url)
            }
            else {
                debugPrint("___ clear lrc file")
                lyricsInfo = nil
            }
        }
    }
    
    var currentIndex: NSInteger {
        get {
            guard let lyricsInfo = lyricsInfo else {
                return 0
            }
            for (i, model) in lyricsInfo.lyricLineInfos.enumerated() {
                if model.startTime > currentTime {
                    if i > 0 {
                        return i - 1
                    } else {
                        return i
                    }
                }
            }
            return lyricsInfo.lyricLineInfos.count - 1
        }
    }
    
    var currentTime: TimeInterval = 0 {
        didSet {
            guard lyricsInfo != nil, lrcFileUrl != nil else {
                return
            }
            setTime(currentTime)
        }
    }
    
    private func setTime(_ time: TimeInterval) {
        guard let lyricsInfo = lyricsInfo else { return }
        let next = currentIndex + 1
        var nextLineInfo: TUILyricsLineInfo?
        if next < lyricsInfo.lyricLineInfos.count {
            nextLineInfo = lyricsInfo.lyricLineInfos[next]
        }
        let currentLineInfo = lyricsInfo.lyricLineInfos[currentIndex]
        if lastIndex != currentIndex {
            leftView.lineInfo = currentLineInfo
            currentLabel = leftView
            if let nextLineInfo = nextLineInfo {
                rightView.isHidden = false
                rightView.lineInfo = nextLineInfo
            } else {
                rightView.isHidden = true
            }
            lastIndex = currentIndex
        }
        
        let progress = time - currentLineInfo.startTime
        currentLabel?.updateProgress(time: progress)
    }
    
    var lastIndex: NSInteger = -1
    var currentLabel: TUILyricsLineView?
    
    lazy var leftView: TUILyricsLineView = {
        return TUILyricsLineView(frame: .zero)
    }()
    
    lazy var rightView: TUILyricsLineView = {
        return TUILyricsLineView(frame: .zero)
    }()
    
    init() {
        super.init(frame: .zero)
        setupView()
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TUILyricsView {
    
    private func setupView() {
        addSubview(leftView)
        leftView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        addSubview(rightView)
        rightView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(leftView.snp.bottom).offset(10)
        }
    }
    
    public func refreshTime(time: Double) {
        currentTime = time
    }
    
}

class TUILyricsLineView: UIView {
    
    var lineInfo: TUILyricsLineInfo? {
        didSet {
            updateView()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        guard let lineInfo = lineInfo else { return }
        var lastLabel: TUILyricsLabel?
        for (index,model) in lineInfo.charStrArray.enumerated() {
            let characterLabel = TUILyricsLabel(frame: .zero)
            characterLabel.characterInfo = model
            characterLabel.textAlignment = .left
            characterLabel.normalTextColor = .white
            characterLabel.selectedTextColor = .orange
            characterLabel.font = UIFont(name: "PingFangSC-Semibold", size: 18)
            addSubview(characterLabel)
            if index == 0 {
                characterLabel.snp.makeConstraints { make in
                    make.left.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
            } else {
                characterLabel.snp.makeConstraints { make in
                    make.left.equalTo(lastLabel!.snp.right)
                    make.top.bottom.equalTo(lastLabel!)
                    if index == lineInfo.charStrArray.count - 1 {
                        make.right.equalToSuperview()
                    }
                }
            }
            lastLabel = characterLabel
        }
    }
    
    func updateView() {
        for subView in subviews {
            guard let lyricLabel = subView as? TUILyricsLabel else { continue }
            lyricLabel.removeFromSuperview()
        }
        setupView()
    }
    
    func updateProgress(time: Double) {
        guard let lastLabel = subviews.last as? TUILyricsLabel else { return }
        if Int(time) > lastLabel.characterInfo.endTime && time < 0 {
            return
        }
        for subView in subviews  {
            guard let lyricLabel = subView as? TUILyricsLabel else { continue }
            let mill = time * 1000
            if (mill <= Double(lyricLabel.characterInfo.endTime)) {
                let current = mill - Double(lyricLabel.characterInfo.startTime)
                if current >= 0 {
                    let progress = current / Double(lyricLabel.characterInfo.duration)
                    lyricLabel.progress = progress
                    return
                }
            } else {
                lyricLabel.progress = 1
            }
        }
    }
}

public class TUILyricsLabel: UIView {
    
    public var font: UIFont? = UIFont(name: "PingFangSC-Semibold", size: 18) {
        didSet {
            textLabel.font = font
            maskLabel.font = font
        }
    }
    
    public var textAlignment: NSTextAlignment = .left {
        didSet {
            textLabel.textAlignment = textAlignment
            maskLabel.textAlignment = textAlignment
        }
    }
    
    public var textColor: UIColor? = .white {
        didSet {
            textLabel.textColor = textColor
        }
    }
    
    public var characterInfo: TUILyricsCharacterInfo = TUILyricsCharacterInfo(startTime: 0,
                                                                               duration: 0,
                                                                               characterStr: "") {
        didSet {
            if oldValue.startTime != characterInfo.startTime {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                maskLayer.bounds = CGRect(x: 0, y: 0, width: 0, height: bounds.height)
                CATransaction.commit()
            }
            textLabel.text = characterInfo.characterStr
            maskLabel.text = characterInfo.characterStr
            textLabel.sizeToFit()
            maskLabel.sizeToFit()
        }
    }
    
    public var progress: Double = 0 {
        didSet {
            if progress > 0 && progress <= 1 {
                setNeedsDisplay()
            }
        }
    }
    
    public func reset() {
        maskLayer.bounds = CGRect(x: 0, y: 0, width: 0, height: bounds.height)
        progress = 0
    }
    
    var normalTextColor: UIColor? {
        didSet {
            textLabel.textColor = normalTextColor
        }
    }
    
    var selectedTextColor: UIColor = .cyan {
        didSet {
            maskLabel.textColor = selectedTextColor
        }
    }
    
    lazy var textLabel: UILabel = {
        let label = UILabel(frame: bounds)
        label.font = font
        label.text = characterInfo.characterStr
        label.textAlignment = textAlignment
        label.textColor = textColor
        return label
    }()
    
    lazy var maskLabel: UILabel = {
        let label = UILabel(frame: bounds)
        label.font = font
        label.text = characterInfo.characterStr
        label.textAlignment = textAlignment
        label.textColor = textColor
        label.layer.mask = maskLayer
        backgroundColor = .clear
        return label
    }()
    
    lazy var maskLayer: CALayer = {
        let maskLayer = CALayer()
        maskLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
        maskLayer.backgroundColor = UIColor.white.cgColor
        return maskLayer
    }()
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        maskLayer.position = CGPoint(x: 0, y: bounds.height * 0.5)
        
        if progress == 0 {
            maskLayer.bounds = CGRect(x: 0, y: 0, width: 0, height: bounds.height)
        }
        else {
            maskLayer.bounds = CGRect(x: 0, y: 0, width: maskLabel.bounds.width * CGFloat(progress), height: bounds.height)
        }
    }
    
    private var isViewReady = false
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if isViewReady {
            return
        }
        isViewReady = true
        
        addSubview(textLabel)
        textLabel.snp.makeConstraints { (make) in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
        
        addSubview(maskLabel)
        maskLabel.snp.makeConstraints { (make) in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
    }
}

//
//  TRTCKaraokeSoundEffectViewModel.swift
//  TXLiteAVDemo
//
//  Created by gg on 2021/3/30.
//  Copyright © 2021 Tencent. All rights reserved.
//

import Foundation
public typealias cellClickCallback = (_ errorCode: Int32, _ errorMessage: String) -> Void
class TRTCAudioEffectCellModel: NSObject {
    var actionID: Int = 0
    var title: String = ""
    var icon: UIImage?
    var selectIcon: UIImage?
    var selected: Bool = false
    var action: (() -> Void)?
}

protocol TRTCKaraokeSoundEffectViewResponder: AnyObject {
    func updateMusicPanel(musicInfo: KaraokeMusicInfo?)
    func bgmOnPlaying(musicId: Int32, current: Double, total: Double)
    func onSelectedMusicListChanged()
    func onMusicListChanged()
    func onReceiveStartChorusCmd(musicId: String)
    func onStartChorusBtnClick()
    func onMusicAccompanimentModeChanged(musicId: String, isOrigin: Bool)
}

class TRTCKaraokeSoundEffectViewModel: NSObject {
    weak var viewResponder: TRTCKaraokeSoundEffectViewResponder?

    weak var viewModel: TRTCKaraokeViewModel?
    
    var scrollToken: String = ""
    
    var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    
    private var hasShowHeadsetTips: Bool = false
    
    init(_ model: TRTCKaraokeViewModel) {
        viewModel = model
        super.init()
        getMusicTagList()
        reloadSelectedMusicList(nil)
    }

    var musicVolume: Int = 60
    var voiceVolume: Int = 80
    var musicPitch: Double = 0
    var earMonitor: Bool = false
    
    var isOriginalVolume: Bool = false

    func setVolume(music: Int) {
        musicVolume = music
        viewModel?.Karaoke.updateMusicVolume(musicVolume: music)
    }

    func setEarMonitor(_ enable: Bool) {
        earMonitor = enable
        viewModel?.Karaoke.enableVoiceEarMonitor(enable: enable)
    }

    func setVolume(voice: Int) {
        voiceVolume = voice
        viewModel?.Karaoke.setVoiceVolume(voiceVolume: voice)
    }

    func setMusic(pitch: Double) {
        musicPitch = pitch
        viewModel?.Karaoke.setMusicPitch(musicPitch: pitch)
    }

    // MARK: - Music

    let loadPageSize = 10

    lazy var musicList: [KaraokeMusicInfo] = []
    lazy var musicSelectedList: [KaraokeMusicInfo] = []
    lazy var musicTagList: [KaraokeMusicTagModel] = []

    lazy var userSelectedSong: [String: Bool] = [:]
    
    lazy var selectedAction: ((_ v: KaraokeMusicInfo, _ callBack: @escaping cellClickCallback) -> Void) = { [weak self] model, callBack in
        guard let `self` = self else { return }
        guard let index = self.musicSelectedList.firstIndex(of: model) else {
            return
        }
        if index == 0 {
            self.viewModel?.Karaoke.stopPlayMusic()
            self.viewModel?.musicService?.switchMusicFromPlaylist(musicInfo: model, callback: { [weak self] code, msg in
                guard let self = self else { return }
                if code == 0 {
                    self.viewModel?.notiMusicListChange()
                }
                callBack(code, msg)
            })
        } else {
            self.viewModel?.musicService?.topMusic(musicInfo: model, callback: { code, msg in
                callBack(code, msg)
            })
        }
    }
    
    func getMusicTagList() {
        viewModel?.musicService?.getMusicTagList(callback: { [weak self] _, _, list in
            guard let self = self else { return }
            self.musicTagList = list
            if let tagId = list.first?.tagId {
                self.getMusicInfoListBy(tagId: tagId, scrollToken: self.scrollToken, needCleanData: false, callBack: nil)
            }
        })
    }
    
    func getMusicInfoListBy(tagId: String, scrollToken: String, needCleanData: Bool, callBack: ((Int, Int)-> Void)?) {
        viewModel?.musicService?.getMusicsByTagId(tagId: tagId,
                                                  scrollToken: scrollToken,
                                                  callback: { [weak self] errorCode, errorMessage, list, scrollToken in
            guard let self = self else { return }
            if errorCode == 0 {
                if needCleanData {
                    self.musicList.removeAll()
                }
                self.scrollToken = scrollToken
                for sourceModel in list {
                    let model = sourceModel
                    self.musicList.append(model)
                }
                self.viewResponder?.onMusicListChanged()
            }
            if let callBack = callBack {
                callBack(errorCode, list.count)
            }
        })
    }

    func reloadSelectedMusicList(_ callback: MusicSelectedListCallback?) {
        viewModel?.musicService?.getPlaylist({ [weak self] errorCode, _, list in
            guard let `self` = self else { return }
            if errorCode == 0 {
                self.musicSelectedList = list
                self.viewResponder?.onSelectedMusicListChanged()
            }
            callback?(0, "", list)
        })
    }

    func playMusic(_ model: KaraokeMusicInfo) {
        viewModel?.Karaoke.startPlayMusic(musicID: Int32(model.performId) ?? 0,
                                          originalUrl: model.originUrl,
                                          accompanyUrl: model.accompanyUrl ?? "")
    }

    func stopPlay() {
        if viewModel?.currentMusicModel != nil {
            viewModel?.currentMusicModel = nil
            viewModel?.Karaoke.stopPlayMusic()
        }
    }

    func pausePlay() {
        viewModel?.Karaoke.pausePlayMusic()
    }

    func resumePlay() {
        viewModel?.Karaoke.resumePlayMusic()
    }

    func clearStatus() {
        if viewModel?.currentMusicModel != nil {
            setMusic(pitch: 0)
            stopPlay()
        }
        setVolume(music: 30)
        setVolume(voice: 100)
        viewModel?.currentMusicModel = nil
    }

    func checkHasHeadset() {
        var hasHeadset = false
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs where
        output.portType == .headphones ||
        output.portType == .bluetoothA2DP ||
        output.portType == .bluetoothHFP ||
        output.portType == .bluetoothLE {
            hasHeadset = true
        }
        if !hasHeadset && !hasShowHeadsetTips {
            viewModel?.viewResponder?.showToast(message: .audioRouteChangeTipsText)
            hasShowHeadsetTips = true
        }
    }
    
    // MARK: - Voice change and reverb

    var currentChangerType: TXVoiceChangeType = ._0
    var currentReverb: TXVoiceReverbType = ._0

    lazy var reverbDataSource: [TRTCAudioEffectCellModel] = {
        var res: [TRTCAudioEffectCellModel] = []
        let titleArray = [
            karaokeLocalize("ASKit.MenuItem.No effect"),
            karaokeLocalize("ASKit.MenuItem.Karaoke room"),
            karaokeLocalize("ASKit.MenuItem.Metallic"),
            karaokeLocalize("ASKit.MenuItem.Deep"),
            karaokeLocalize("ASKit.MenuItem.Resonant"),
        ]
        let iconNameArray = [
            "originState_nor",
            "Reverb_Karaoke_nor",
            "Reverb_jinshu_nor",
            "Reverb_dichen_nor",
            "Reverb_hongliang_nor",
        ]
        let iconSelectedNameArray = [
            "originState_sel",
            "Reverb_Karaoke_sel",
            "Reverb_jinshu_sel",
            "Reverb_dichen_sel",
            "Reverb_hongliang_sel",
        ]
        for index in 0 ..< titleArray.count {
            let title = titleArray[index]
            let normalIconName = iconNameArray[index]
            let selectIconName = iconSelectedNameArray[index]

            let model = TRTCAudioEffectCellModel()
            model.actionID = index
            model.title = title
            model.selected = title == karaokeLocalize("ASKit.MenuItem.No effect")
            model.icon = UIImage(named: normalIconName, in: karaokeBundle(), compatibleWith: nil)
            model.selectIcon = UIImage(named: selectIconName, in: karaokeBundle(), compatibleWith: nil)
            model.action = { [weak self] in
                guard let `self` = self else { return }
                let type = self.switch2ReverbType(index)
                self.viewModel?.Karaoke.setVoiceReverbType(reverbType: type.rawValue)
                self.currentReverb = type
            }
            if model.icon != nil {
                res.append(model)
            }
        }
        return res
    }()

    lazy var voiceChangeDataSource: [TRTCAudioEffectCellModel] = {
        var res: [TRTCAudioEffectCellModel] = []

        let titleArray =
            [karaokeLocalize("ASKit.MenuItem.Original"),
             karaokeLocalize("ASKit.MenuItem.Naughty boy"),
             karaokeLocalize("ASKit.MenuItem.Little girl"),
             karaokeLocalize("ASKit.MenuItem.Middle-aged man"),
             karaokeLocalize("ASKit.MenuItem.Ethereal voice"),
            ]

        let iconNameArray = [
            "originState_nor",
            "voiceChange_xionghaizi_nor",
            "voiceChange_loli_nor",
            "voiceChange_dashu_nor",
            "voiceChange_kongling_nor",
        ]

        let iconSelectedNameArray = [
            "originState_sel",
            "voiceChange_xionghaizi_sel",
            "voiceChange_loli_sel",
            "voiceChange_dashu_sel",
            "voiceChange_kongling_sel",
        ]

        for index in 0 ..< titleArray.count {
            let title = titleArray[index]
            let normalIconName = iconNameArray[index]
            let selectedIconName = iconSelectedNameArray[index]
            let model = TRTCAudioEffectCellModel()
            model.title = title
            model.actionID = index
            model.selected = title == karaokeLocalize("ASKit.MenuItem.Original")
            model.icon = UIImage(named: normalIconName, in: karaokeBundle(), compatibleWith: nil)
            model.selectIcon = UIImage(named: selectedIconName, in: karaokeBundle(), compatibleWith: nil)
            model.action = { [weak self] in
                guard let `self` = self else { return }
                let type = self.switch2VoiceChangeType(index)
                self.viewModel?.Karaoke.setVoiceChangerType(changerType: type.rawValue)
                self.currentChangerType = type
            }
            if model.icon != nil {
                res.append(model)
            }
        }
        return res
    }()

    func switch2VoiceChangeType(_ index: Int) -> TXVoiceChangeType {
        switch index {
        case 0:
            return ._0
        case 1:
            return ._1
        case 2:
            return ._2
        case 3:
            return ._3
        case 4:
            return ._11
        default:
            return ._0
        }
    }

    func switch2ReverbType(_ index: Int) -> TXVoiceReverbType {
        switch index {
        case 0:
            return ._0
        case 1:
            return ._1
        case 2:
            return ._6
        case 3:
            return ._4
        case 4:
            return ._5
        default:
            return ._0
        }
    }
}

// MARK: - internationalization string

fileprivate extension String {
    static let musicTitle1Text = karaokeLocalize("Demo.TRTC.Karaoke.musicname1")
    static let musicTitle2Text = karaokeLocalize("Demo.TRTC.Karaoke.musicname2")
    static let musicTitle3Text = karaokeLocalize("Demo.TRTC.Karaoke.musicname3")
    static let notInSeatText = karaokeLocalize("Demo.TRTC.Karaoke.onlyanchorcanoperation")
    static let audioRouteChangeTipsText = karaokeLocalize("Demo.TRTC.Karaoke.audioRouteChangeTips")
}

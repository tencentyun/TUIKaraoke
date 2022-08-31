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
    func bgmOnPrepareToPlay(performId: Int32)
    func bgmOnPlaying(performId: Int32, current: Double, total: Double)
    func bgmOnCompletePlaying()
    func onSelectedMusicListChanged()
    func onMusicListChanged()
    func onManageSongBtnClick()
}

class TRTCKaraokeSoundEffectViewModel: NSObject {
    weak var viewResponder: TRTCKaraokeSoundEffectViewResponder?

    weak var viewModel: TRTCKaraokeViewModel?

    init(_ model: TRTCKaraokeViewModel) {
        viewModel = model
        super.init()
        reloadMusicList()
        reloadSelectedMusicList(nil)
    }

    lazy var manager: TXAudioEffectManager? = {
        viewModel?.Karaoke.getAudioEffectManager()
    }()

    var currentMusicVolum: Int = 100
    var currentVocalVolume: Int = 100
    var currentPitchVolum: Double = 0
    var currentEarMonitor: Bool = false
    var bgmID: Int32 = 0
    
    var isOriginalVolume: Bool = true {
        didSet {
            if isOriginalVolume == oldValue {
                return
            }
            bgmID = bgmID + (isOriginalVolume ? -1 : 1)
            setVolume(music: currentMusicVolum)
            setVolume(person: currentVocalVolume)
            setPitch(person: currentPitchVolum)
        }
    }

    public func setVolume(music: Int) {
        currentMusicVolum = music
        guard let manager = manager else {
            return
        }
        if bgmID != 0 {
            manager.setMusicPlayoutVolume(bgmID, volume: music)
            manager.setMusicPublishVolume(bgmID, volume: music)
        }
    }

    public func setEarMonitor(_ enable: Bool) {
        guard let manager = manager else {
            return
        }
        currentEarMonitor = enable
        manager.enableVoiceEarMonitor(enable)
    }

    public func setVolume(person: Int) {
        currentVocalVolume = person
        guard let manager = manager else {
            return
        }
        manager.setVoiceVolume(person)
    }

    public func setPitch(person: Double) {
        currentPitchVolum = person
        guard let manager = manager else {
            return
        }
        if bgmID != 0 {
            manager.setMusicPitch(bgmID, pitch: person)
        }
    }

    // MARK: - Music

    let loadPageSize = 10
    var currentPlayingModel: KaraokeMusicModel?

    lazy var popularMusic: [KaraokePopularInfo] = []
    lazy var musicList: [KaraokeMusicModel] = []
    lazy var musicSelectedList: [KaraokeMusicModel] = []

    lazy var userSelectedSong: [String: Bool] = [:]
    lazy var listAction: ((_ v: KaraokeMusicModel, _ callBack: @escaping cellClickCallback) -> Void) = { [weak self] model, callBack in
        guard let `self` = self else { return }
        if self.viewModel?.userType == .anchor {
            self.viewModel?.cacheSelectd.setObject("1", forKey: model.music.getMusicId() as NSString)
            self.viewModel?.musicDataSource?.pickMusic(musicInfo: model.music, callback: { [weak self] code, msg in
                guard let self = self else { return }
                self.viewModel?.cacheSelectd.removeObject(forKey: model.music.getMusicId() as NSString)
                callBack(code, msg)
            })
        } else {
            callBack(-1, .notInSeatText)
        }
    }

    lazy var downloadAction: ((_ musicInfo: KaraokeMusicInfo, _ progress: @escaping MusicProgressCallback, _ complete: @escaping MusicFinishCallback) -> Void) = { [weak self] musicInfo, progress, complete in
        guard let `self` = self else { return }
        self.viewModel?.musicDataSource?.downloadMusic(musicInfo, progress: progress, complete: complete)
    }

    lazy var selectedAction: ((_ v: KaraokeMusicModel, _ callBack: @escaping cellClickCallback) -> Void) = { [weak self] model, callBack in
        guard let `self` = self else { return }
        guard let index = self.musicSelectedList.firstIndex(of: model) else {
            return
        }
        if index == 0 {
            self.viewModel?.musicDataSource?.nextMusic(musicInfo: model.music, callback: { code, msg in
                callBack(code, msg)
            })
        } else {
            self.viewModel?.musicDataSource?.topMusic(musicInfo: model.music, callback: { code, msg in
                callBack(code, msg)
            })
        }
    }

    func reloadMusicList() {
        viewModel?.musicDataSource?.ktvGetPopularMusic(callback: { [weak self] _, _, list in
            guard let `self` = self else { return }
            self.popularMusic = list
            if let playlistId = self.popularMusic.first?.playlistId {
                self.loadMoreListDataByOffset(playlistId: playlistId, offset: 0)
            }
        })
    }

    func loadMoreListDataByOffset(playlistId: String, offset: Int) {
        viewModel?.musicDataSource?.ktvGetMusicPage(playlistId: playlistId, offset: offset, pageSize: 50, callback: { [weak self] errorCode, _, list in
            guard let `self` = self else { return }
            if errorCode == 0 {
                for sourceModel in list {
                    let model = KaraokeMusicModel(sourceModel: sourceModel)
                    self.musicList.append(model)
                }
                self.viewResponder?.onMusicListChanged()
            }
        })
    }

    func reloadSelectedMusicList(_ callback: MusicSelectedListCallback?) {
        viewModel?.musicDataSource?.ktvGetSelectedMusicList({ [weak self] errorCode, _, list in
            guard let `self` = self else { return }
            if errorCode == 0 {
                self.musicSelectedList = list
                self.viewResponder?.onSelectedMusicListChanged()
            }
            callback?(0, "", list)
        })
    }

    func playMusic(_ model: KaraokeMusicModel) {
        if currentPlayingModel?.music.performId != model.music.performId {
            currentPlayingModel = model
            model.seatIndex = viewModel?.getSeatIndexByUserId(userId: model.music.userId) ?? 0
            let seatUser = viewModel?.getSeatUserByUserId(userId: model.music.userId)
            model.bookUserName = seatUser?.userName ?? ""
            model.bookUserAvatar = seatUser?.userAvatar ?? ""
            bgmID = model.musicID
            viewModel?.Karaoke.startPlayMusic(musicID: model.musicID, originalUrl: model.music.muscicLocalPath, accompanyUrl: model.music.accompanyLocalPath)
            resetMusicSeting()
        }
    }

    func resetMusicSeting() {
        guard let manager = manager else {
            return
        }
        manager.setVoiceVolume(currentVocalVolume)
        manager.setVoiceReverbType(currentReverb)
        manager.setVoiceChangerType(currentChangerType)
        setVolume(music: currentMusicVolum)
        setVolume(person: currentVocalVolume)
        setPitch(person: currentPitchVolum)
        setEarMonitor(currentEarMonitor)
    }

    func stopPlay() {
        currentPlayingModel = nil
        bgmID = 0
        viewModel?.Karaoke.stopPlayMusic()
    }

    func pausePlay() {
        viewModel?.Karaoke.pausePlayMusic()
    }

    func resumePlay() {
        viewModel?.Karaoke.resumePlayMusic()
    }

    func clearStatus() {
        currentPlayingModel = nil
        if bgmID != 0 {
            setPitch(person: 0)
            stopPlay()
            bgmID = 0
        }
        setVolume(music: 100)
        setVolume(person: 100)
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
                self.manager?.setVoiceReverbType(type)
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
                self.manager?.setVoiceChangerType(type)
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
}

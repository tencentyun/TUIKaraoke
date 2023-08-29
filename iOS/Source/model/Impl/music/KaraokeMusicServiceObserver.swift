//
//  KaraokeMusicServiceObserver.swift
//  TUIKaraoke
//
//  Created by adams on 2023/4/3.
//

import UIKit

/**
 * 歌曲管理回调接口
 */
public protocol KaraokeMusicServiceObserver: AnyObject {
    /**
     * 歌曲列表更新回调
     * - parameter musicInfoList   已点歌曲列表数组
     */
    func onMusicListChanged(musicInfoList: [KaraokeMusicInfo])
    
    // MARK: - 打分相关
    
    /**
     * 打分准备就绪回调
     * - parameter pitchModelList 歌曲音高模型
     */
    func onMusicScorePrepared(pitchModelList: [MusicPitchModel])
    
    /**
     * 打分结束回调
     * - parameter totalScore  总分
     */
    func onMusicScoreFinished(totalScore: Int32)
    
    /**
     * 歌曲的进度
     * - parameter progress  歌曲实时进度
     */
    func onMusicRealTimeProgress(progress: Int)
    
    /**
     * 实时音高回调
     * - parameter pitch      实时音高
     */
    func onMusicRealTimePitch(pitch: Int)
    
    /**
     * 每句歌曲得分
     * - parameter currentScore 分数
     */
    func onMusicSingleScore(currentScore: Int32)
}

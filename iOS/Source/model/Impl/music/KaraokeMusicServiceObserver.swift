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
}

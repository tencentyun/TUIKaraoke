//
//  TRTCKaraokeModelDef.swift
//  TRTCKaraokeDemo
//
//  Created by abyyxwang on 2020/6/15.
//  Copyright © 2020 tencent. All rights reserved.
//

import UIKit

public enum KaraokeViewType {
    case owner
    case audience
}

/// Voice Room 定义常量的类
class KaraokeConstants {
    public static let TYPE_VOICE_ROOM = "Karaoke"
    // 直播端右下角listview显示的type
    public static let CMD_REQUEST_TAKE_SEAT = "1"
    public static let CMD_PICK_UP_SEAT = "2"
}

/// 记录房间座位信息的Model
struct SeatInfoModel {
    var seatIndex: Int = -1
    var isClosed: Bool = false
    var isUsed: Bool = false
    var isOwner: Bool = false
    var seatInfo: SeatInfo?
    var seatUser: UserInfo?
    var action: ((Int) -> Void)? // 入参为SeatIndex
    var isTalking: Bool = false
}

enum MsgEntityType: Int {
    case normal = 0
    case wait_agree
    case agreed
    case manage_song
}

/// 记录房间消息列表的Model
struct MsgEntity {
    
    let userId: String
    let userName: String
    let content: String
    let invitedId: String
    var type: MsgEntityType
    var action: (()->())? = nil
}

struct AudienceInfoModel {
    
    static let TYPE_IDEL = 0
    static let TYPE_IN_SEAT = 1
    static let TYPE_WAIT_AGREE = 2
    
    var type: Int = 0 // 观众类型
    var userInfo: UserInfo
    var action: (Int) -> Void // 点击邀请按钮的动作
}

struct SeatInvitation {
    let seatIndex: Int
    let inviteUserId: String
}

//
//  HttpJsonModel.swift
//  TRTCAPP_AppStore
//
//  Created by WesleyLei on 2021/8/2.
//

import Foundation
import TUIKaraoke
// 拦截错误码model定义
public class HttpJsonModel: NSObject {
    var errorCode: Int32 = -1
    var errorMessage: String = ""
    var data: Any?

    public static func json(_ json: [String: Any]) -> HttpJsonModel? {
        guard let errorCode = json["errorCode"] as? Int32 else {
            return nil
        }
        guard let errorMessage = json["errorMessage"] as? String else {
            return nil
        }
        let info = HttpJsonModel()
        info.errorCode = errorCode
        info.errorMessage = errorMessage
        info.data = json["data"] as Any
        return info
    }

    // 懒加载---业务解析层处理
    // 获取登录返回的sdkAppId
    lazy var sdkAppId: Int32? = {
        guard let result = data as? [String: Any] else { return nil }
        return result["sdkAppId"] as? Int32
    }()

    // 获取UserModel
    lazy var currentUserModel: UserModel? = {
        guard let result = data as? [String: Any] else { return nil }
        return getUserModel(result)
    }()

    // 获取用户列表
    lazy var users: [UserModel] = {
        var usersResult: [UserModel] = []
        guard let result = data as? [[String: Any]] else { return usersResult }
        for dict in result {
            if let userModel = getUserModel(dict) {
                usersResult.append(userModel)
            }
        }
        return usersResult
    }()
    
    private func getUserModel(_ result: [String: Any]) -> UserModel? {
        guard let userId = result["userId"] as? String else { return nil }
        let userSig = (result["userSig"] as? String) ?? ""
        let token = (result["token"] as? String) ?? ""
        let apaasAppId = (result["apaasAppId"] as? String) ?? ""
        let apaasUserId = (result["apaasUserId"] as? String) ?? ""
        let sdkUserSig = (result["sdkUserSig"] as? String) ?? ""
        let phone = (result["phone"] as? String) ?? ""
        let name = (result["name"] as? String) ?? ""
        let avatar = (result["avatar"] as? String) ?? ""
        return UserModel(token: token, phone: phone, name: name, avatar: avatar, userId: userId, userSig: userSig, apaasAppId: apaasAppId, apaasUserId: apaasUserId, sdkUserSig: sdkUserSig)
    }
}

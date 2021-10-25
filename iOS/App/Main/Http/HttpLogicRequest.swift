//
//  HttpLogicRequest.swift
//  TRTCAPP_AppStore
//
//  Created by WesleyLei on 2021/8/3.
//

import Alamofire
import Foundation
import ImSDK_Plus
import TUIKaraoke
import TUICore
import Kingfisher

//您需要在这里替换你在腾讯云发布日志中获取API网关地址，例如：
//https://service-xxxyyzzz-xxxxxxxxxx.gz.apigw.tencentcs.com
private let httpBaseUrl = ""

private let appLoginBaseUrl = httpBaseUrl + "/prod/base/v1/"
private let SDK_APP_ID_KEY = "sdk_app_id_key"

public typealias HttpLogicRequestSuccessCallBack = (_ data: HttpJsonModel) -> Void
public typealias HttpLogicRequestFailedCallBack = (_ errorCode: Int32, _ errorMessage: String?) -> Void
public typealias HttpUserLoginRequestSuccessCallBack = (_ data: UserModel?) -> Void

public class HttpLogicRequest {
    // set get 方法
    private static var _sdkAppId: Int32 = 0
    private(set) static var sdkAppId: Int32 {
        set {
            _sdkAppId = newValue
        }
        get {
            if _sdkAppId > 0 {
                return _sdkAppId
            }
            if let appid = UserDefaults.standard.object(forKey: SDK_APP_ID_KEY) as? String {
                _sdkAppId = Int32(appid) ?? Int32(1400188366)
            } else {
                _sdkAppId = Int32(1400188366)
            }
            return _sdkAppId
        }
    }

    /// 心跳和保活
    /// - Parameters:
    public static func user_keepalive(success: HttpLogicRequestSuccessCallBack?, failed: HttpLogicRequestFailedCallBack?) {
        let baseUrl = appLoginBaseUrl + "auth_users/user_keepalive"
        logicRequest(baseUrl: baseUrl, params: [:], success: success, failed: failed)
    }

    /// 用户签名登录
    /// - Parameters:
    ///   - phone: 手机号
    ///   - success: 成功回调
    ///   - failed: 失败回调
    public static func oauthSignature(phone: String, success: HttpUserLoginRequestSuccessCallBack?, failed: HttpLogicRequestFailedCallBack?) {
        let baseUrl = appLoginBaseUrl + "oauth/signature"
        let hash = "md5"
        let tag = "karaoke"
        if let signature = (phone+tag+hash).md5() {
            let params = ["username": phone, "hash": hash, "tag": tag, "signature": signature]
            logicRequest(baseUrl: baseUrl, params: params as Parameters, success: { model in
                if let sdkAppId = model.sdkAppId {
                    HttpLogicRequest.updateSdkAppId(sdkAppId: sdkAppId)
                    IMLogicRequest.imUserLogin(currentUserModel: model.currentUserModel, success: success, failed: failed)
                } else {
                    failed?(-1, TRTCKaraokeLocalize("Demo.TRTC.http.syserror"))
                }
            }, failed: failed)
        }else{
            failed?(-1, TRTCKaraokeLocalize("LoginNetwork.ProfileManager.loginfailed"))
        }
        
    }

    /// Token登录
    /// - Parameters:
    ///   - userId: 用户id
    ///   - token: token
    ///   - success: 成功回调
    ///   - failed: 失败回调
    public static func userLoginToken(userId: String, token: String, success: HttpUserLoginRequestSuccessCallBack?, failed: HttpLogicRequestFailedCallBack?) {
        let baseUrl = appLoginBaseUrl + "auth_users/user_login_token"
        let params = ["userId": userId, "token": token]
        logicRequest(baseUrl: baseUrl, params: params, success: { model in
            IMLogicRequest.imUserLogin(currentUserModel: model.currentUserModel, success: success, failed: failed)
        }, failed: failed)
    }

    /// 注销登录
    /// - Parameters:
    ///   - userId: 用户id
    ///   - token: token
    ///   - success: 成功回调
    ///   - failed: 失败回调
    public static func userLogout(userId: String, token: String, success: HttpUserLoginRequestSuccessCallBack?, failed: HttpLogicRequestFailedCallBack?) {
        let baseUrl = appLoginBaseUrl + "auth_users/user_logout"
        let params = ["userId": userId, "token": token]
        logicRequest(baseUrl: baseUrl, params: params, success: { _ in
            IMLogicRequest.imUserLogout(currentUserModel: nil, success: success, failed: failed)
        }, failed: failed)
    }

    /// 修改用户信息
    /// - Parameters:
    ///   - currentUserModel: UserModel
    ///   - name: 用户名，昵称。限制125个字符。可以是中文
    ///   - success: 成功回调
    ///   - failed: 失败回调
    public static func userUpdate(currentUserModel: UserModel, name: String, success: HttpUserLoginRequestSuccessCallBack?, failed: HttpLogicRequestFailedCallBack?) {
        let baseUrl = appLoginBaseUrl + "auth_users/user_update"
        let params = ["userId": currentUserModel.userId, "token": currentUserModel.token, "name": name]
        logicRequest(baseUrl: baseUrl, params: params, success: { _ in
            IMLogicRequest.synchronizUserInfo(currentUserModel: currentUserModel, name: name, success: success, failed: failed)
        }, failed: failed)
    }

    /// 发起网络请求
    /// - Parameters:
    ///   - baseUrl: baseUrl
    ///   - params: params
    ///   - success: 成功回调
    ///   - failed: 失败回调
    private static func logicRequest(baseUrl: URLConvertible, params: Parameters? = nil, success: HttpLogicRequestSuccessCallBack?, failed: HttpLogicRequestFailedCallBack?) {
        HttpBaseRequest.trtcRequest(baseUrl, method: .post, parameters: params, encoding: JSONEncoding.default, completionHandler: { (model: HttpJsonModel) in
            if model.errorCode == 0 {
                success?(model)
            } else {
                failed?(model.errorCode, model.errorMessage)
            }
        })
    }
}

// MARK: sdkAppId数据存储

extension HttpLogicRequest {
    static func updateSdkAppId(sdkAppId: Int32) {
        HttpLogicRequest.sdkAppId = sdkAppId
        UserDefaults.standard.setValue(String(sdkAppId), forKey: SDK_APP_ID_KEY)
        UserDefaults.standard.synchronize()
    }
}


// MARK: IM请求相关方法

public class IMLogicRequest {
    /// IM 登录
    /// - Parameters:
    ///   - currentUserModel: UserModel
    ///   - success: 成功
    ///   - failed: 失败
    static func imUserLogin(currentUserModel: UserModel?, success: HttpUserLoginRequestSuccessCallBack?, failed: HttpLogicRequestFailedCallBack?) {
        guard let userModel = currentUserModel else {
            failed?(-1, TRTCKaraokeLocalize("LoginNetwork.ProfileManager.loginfailed"))
            return
        }
        TUILogin.initWithSdkAppID(HttpLogicRequest.sdkAppId)
        TUILogin.login(userModel.userId, userSig: userModel.userSig) {
            debugPrint("login success")
            V2TIMManager.sharedInstance()?.getUsersInfo([userModel.userId], succ: { infos in
                if let info = infos?.first {
                    userModel.avatar = info.faceURL ?? ""
                    userModel.name = info.nickName ?? ""
                    if info.userID != nil {
                        userModel.userId = info.userID!
                    }
                    ProfileManager.sharedManager().saveUserDefaults(userModel)
                    success?(userModel)
                } else {
                    failed?(-1, TRTCKaraokeLocalize("LoginNetwork.ProfileManager.loginfailed"))
                }
            }, fail: { code, errorDes in
                failed?(code, errorDes)
            })
        } fail: { code, errorDes in
            failed?(code, errorDes)
        }
    }


    /// IM 退出登录
    /// - Parameters:
    ///   - currentUserModel: UserModel
    ///   - success: 成功
    ///   - failed: 失败
    static func imUserLogout(currentUserModel: UserModel?, success: HttpUserLoginRequestSuccessCallBack?, failed: HttpLogicRequestFailedCallBack?) {
        TUILogin.logout {
            success?(currentUserModel)
        } fail: { code, errorDes in
            failed?(code, errorDes)
        }
    }

    /// IM 更新
    /// - Parameters:
    ///   - currentUserModel: UserModel
    ///   - name: 昵称
    ///   - success: 成功
    ///   - failed: 失败
    static func synchronizUserInfo(currentUserModel: UserModel, name: String, success: HttpUserLoginRequestSuccessCallBack?, failed: HttpLogicRequestFailedCallBack?) {
        let userInfo = V2TIMUserFullInfo()
        userInfo.nickName = name
        userInfo.faceURL = currentUserModel.avatar
        V2TIMManager.sharedInstance()?.setSelfInfo(userInfo, succ: {
            currentUserModel.name = name
            success?(currentUserModel)
            ProfileManager.sharedManager().saveUserDefaults(currentUserModel)
            debugPrint("set profile success")
        }, fail: { code, errorDes in
            failed?(code, errorDes)
        })
    }

    /// IM 更新
    /// - Parameters:
    ///   - currentUserModel: UserModel
    ///   - avatar: 头像
    ///   - success: 成功
    ///   - failed: 失败
    static func synchronizUserInfo(currentUserModel: UserModel, avatar: String, success: HttpUserLoginRequestSuccessCallBack?, failed: HttpLogicRequestFailedCallBack?) {
        let userInfo = V2TIMUserFullInfo()
        userInfo.nickName = currentUserModel.name
        userInfo.faceURL = avatar
        V2TIMManager.sharedInstance()?.setSelfInfo(userInfo, succ: {
            currentUserModel.avatar = avatar
            success?(currentUserModel)
            ProfileManager.sharedManager().saveUserDefaults(currentUserModel)
            debugPrint("set profile success")
        }, fail: { code, errorDes in
            failed?(code, errorDes)
        })
    }
}

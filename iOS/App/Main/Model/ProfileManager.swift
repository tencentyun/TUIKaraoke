//
//  profileManager.swift
//  trtcScenesDemo
//
//  Created by xcoderliu on 12/23/19.
//  Copyright © 2019 xcoderliu. All rights reserved.
//

import Alamofire
import ImSDK_Plus
import UIKit

private let PER_USER_MODEL_KEY = "per_user_model"

@objcMembers
public class ProfileManager: NSObject {
    private var keepaliveTimer: DispatchSourceTimer?
    override private init() {}
    private static let staticInstance: ProfileManager = ProfileManager()
    static func sharedManager() -> ProfileManager { staticInstance }
    private(set) var userPublishVideoDate: String = ""
    // 懒加载
    private(set) var currentUserModel: UserModel? = {
        if let cacheData = UserDefaults.standard.object(forKey: PER_USER_MODEL_KEY) as? Data {
            do {
                let cacheUser = try JSONDecoder().decode(UserModel.self, from: cacheData)
                return cacheUser
            } catch {
                return nil
            }
        }
        return nil
    }()

    public func updateUserModel(_ currentUserModel: UserModel?) {
        self.currentUserModel = currentUserModel
    }

    public func getUserID() -> String? {
        guard let userID = currentUserModel?.userId else { return nil }
        return userID
    }

    public func getUserSig() -> String {
        guard let userSig = currentUserModel?.userSig else { return "" }
        return userSig
    }

    // Dispatch Timer
    public func startKeepaliveTimer() {
        guard keepaliveTimer == nil else {
            return
        }
        keepaliveTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        keepaliveTimer?.schedule(deadline: .now(), repeating: .seconds(10))
        keepaliveTimer?.setEventHandler(handler: { [weak self] in
            guard let self = self else { return }
            if self.currentUserModel != nil {
                HttpLogicRequest.user_keepalive(success: nil, failed: nil)
            }
        })
        keepaliveTimer?.resume()
    }
}

// MARK: 用户信息缓存
extension ProfileManager {
    
    public func saveUserDefaults(_ userModel: UserModel) {
        do {
            let cacheData = try JSONEncoder().encode(userModel)
            UserDefaults.standard.set(cacheData, forKey: PER_USER_MODEL_KEY)
        } catch {
            print("Save Failed")
        }
    }

    public func removeLoginCache() {
        currentUserModel = nil
        UserDefaults.standard.set(nil, forKey: PER_USER_MODEL_KEY)
    }
}


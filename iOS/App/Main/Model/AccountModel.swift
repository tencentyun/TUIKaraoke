//
//  AccountModel.swift
//  TRTCScene
//
//  Created by adams on 2021/5/20.
//

import UIKit

@objcMembers
public class UserModel: NSObject, Codable {
    var token: String
    var phone: String
    var name: String
    var avatar: String
    var userId: String
    var userSig: String = ""
    var apaasAppId: String = ""
    var apaasUserId: String = ""
    var sdkUserSig: String = ""
    
    enum CodingKeys: String, CodingKey {
        case token
        case phone
        case name
        case avatar
        case userId
        case userSig
        case apaasAppId
        case apaasUserId
        case sdkUserSig
    }
    public init(token: String,phone: String,name: String,avatar: String,userId: String,userSig: String,apaasAppId: String,apaasUserId: String,sdkUserSig: String) {
        self.token = token;
        self.phone = phone;
        self.name = name;
        self.avatar = avatar;
        self.userId = userId;
        self.userSig = userSig;
        self.apaasAppId = apaasAppId;
        self.apaasUserId = apaasUserId;
        self.sdkUserSig = sdkUserSig;
    }
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            name = try container.decode(String.self, forKey: .name)
        } catch {
            name = ""
        }
        
        do {
            phone = try container.decode(String.self, forKey: .phone)
        } catch {
            phone = ""
        }
        
        do {
            token = try container.decode(String.self, forKey: .token)
        } catch {
            token = ""
        }
        
        do {
            avatar = try container.decode(String.self, forKey: .avatar)
        } catch {
            avatar = ""
        }
        
        do {
            userId = try container.decode(String.self, forKey: .userId)
        } catch {
            userId = ""
        }
        
        do {
            userSig = try container.decode(String.self, forKey: .userSig)
        } catch {
            userSig = ""
        }
        
        do {
            apaasAppId = try container.decode(String.self, forKey: .apaasAppId)
        } catch {
            apaasAppId = ""
        }
        
        do {
            apaasUserId = try container.decode(String.self, forKey: .apaasUserId)
        } catch {
            apaasUserId = ""
        }
        
        do {
            sdkUserSig = try container.decode(String.self, forKey: .sdkUserSig)
        } catch {
            sdkUserSig = ""
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(phone, forKey: .phone)
        try container.encode(token, forKey: .token)
        try container.encode(name, forKey: .name)
        try container.encode(avatar, forKey: .avatar)
        try container.encode(userId, forKey: .userId)
        try container.encode(userSig, forKey: .userSig)
        try container.encode(apaasAppId, forKey: .apaasAppId)
        try container.encode(apaasUserId, forKey: .apaasUserId)
        try container.encode(sdkUserSig, forKey: .sdkUserSig)
    }
}


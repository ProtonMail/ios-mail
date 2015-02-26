//
//  APIService+SettingsExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

/// Settings extension
extension APIService {
    
    private struct SettingPath {
        static let base = "/setting"
    }
    
    func settingUpdateDisplayName(displayName: String, completion: CompletionBlock) {
        let path = SettingPath.base.stringByAppendingPathComponent("display")
        let parameters = ["DisplayName" : displayName]
        
        request(method: .PUT, path: path, parameters: parameters, completion: completion)
    }

    func settingUpdateMailboxPassword(newPassword: String, completion: CompletionBlock) {
        let path = SettingPath.base.stringByAppendingPathComponent("keypwd")
        // TODO: Add parameters for update mailbox password when defined in API
        let parameters = [:]

        request(method: .PUT, path: path, parameters: parameters, completion: completion)
    }
    
    func settingUpdateNotificationEmail(notificationEmail: String, completion: CompletionBlock) {
        let path = SettingPath.base.stringByAppendingPathComponent("noticeemail")
        let parameters = ["NotificationEmail" : notificationEmail]

        request(method: .PUT, path: path, parameters: parameters, completion: completion)
    }
    
    func settingUpdatePassword(newPassword: String, completion: CompletionBlock) {
        let path = SettingPath.base.stringByAppendingPathComponent("password")
        let parameters = [
            "username" : sharedUserDataService.username ?? "",
            "password" : newPassword,
            "client_id" : "demoapp",
            "response_type" : "password"]
        
        request(method: .PUT, path: path, parameters: parameters, completion: completion)
    }
    
    func settingUpdateSignature(signature: String, completion: CompletionBlock) {
        let path = SettingPath.base.stringByAppendingPathComponent("signature")
        let parameters = ["Signature" : signature]
        
        request(method: .PUT, path: path, parameters: parameters, completion: completion)
    }
}

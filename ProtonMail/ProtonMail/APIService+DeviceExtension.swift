//
//  APIService+DeviceExtension.swift
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

/// DeviceExtension

extension APIService {
    
    private struct DevicePath {
        static let basePath = "/Device"
    }
    
    func deviceRegisterWithToken(token: NSData, completion: CompletionBlock?) {
        let tokenString = stringFromToken(token)
        
        deviceToken = tokenString
        
        let parameters = [
            "device_uid" : deviceID,
            "device_token" : tokenString,
            "device_name" : UIDevice.currentDevice().name,
            "device_model" : UIDevice.currentDevice().model,
            "device_version" : UIDevice.currentDevice().systemVersion
        ]
        
        request(method: .POST, path: DevicePath.basePath, parameters: parameters, completion: completion)
    }
    
    func deviceUnregister(completion: CompletionBlock?) {
        if let deviceToken = deviceToken {
            let parameters = [
                "device_uid": deviceID,
                "device_token": deviceToken
            ]
            
            request(method: .DELETE, path: DevicePath.basePath, parameters: parameters, completion: completion)
        }
    }
    
    // MARK: - Private methods
    
    private struct DeviceKey {
        static let token = "DeviceTokenKey"
    }
    
    private var deviceID: String {
        return UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
    }
    
    private var deviceToken: String? {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(DeviceKey.token)
        }
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: DeviceKey.token)
        }
    }
    
    private func stringFromToken(token: NSData) -> String {
        let tokenChars = UnsafePointer<CChar>(token.bytes)
        var tokenString = ""
        
        for var i = 0; i < token.length; i++ {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }

        return tokenString
    }
}

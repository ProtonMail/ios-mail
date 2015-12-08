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
        static let basePath = "/device"
    }
    func deviceRegisterWithToken(token: NSData, completion: CompletionBlock?) {
        let tokenString = stringFromToken(token)
        deviceToken = tokenString
        
        //UIApplication.sharedApplication().release
        
        // 1 : ios dev
        // 2 : ios production
        // 3 : ios simulator
        
        // 10 : android
        
        // 20 : ios enterprice dev
        // 21 : ios enterprice production
        // 23 : ios enterprice simulator
        
    
        #if DEBUG
            let env = 20
        #else
            let env = 21
        #endif
        
        var ver = "1.0.0"
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            ver = version
        }
        let parameters = [
            "DeviceUID" : deviceID,
            "DeviceToken" : tokenString,
            "DeviceName" : UIDevice.currentDevice().name,
            "DeviceModel" : UIDevice.currentDevice().model,
            "DeviceVersion" : UIDevice.currentDevice().systemVersion,
            "AppVersion" : "iOS_\(ver)",
            "Environment" : env
        ]
        
        setApiVesion(1, appVersion: 1)
        request(method: .POST, path: DevicePath.basePath, parameters: parameters, completion: completion)
    }
    
    func deviceUnregister(completion: CompletionBlock? = nil) {
        if let deviceToken = deviceToken {
            let parameters = [
                "device_uid": deviceID,
                "device_token": deviceToken
            ]
            
            setApiVesion(1, appVersion: 1)
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

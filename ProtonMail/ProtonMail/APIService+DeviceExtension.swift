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
        deviceUID = deviceID
        PMLog.D("\(tokenString)")
        //UIApplication.sharedApplication().release
        
        // 1 : ios dev
        // 2 : ios production
        // 3 : ios simulator
        

        
        // 10 : android
        
        // 20 : ios enterprice dev
        // 21 : ios enterprice production
        // 23 : ios enterprice simulator

        #if Enterprise
            
            #if DEBUG
            let env = 20
            #else
            let env = 21
            #endif
            
        #else
            
            #if DEBUG
                let env = 1
                #else
                let env = 2
            #endif
            
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
        request(method: .POST, path: AppConstants.BaseAPIPath + DevicePath.basePath, parameters: parameters, completion: completion)
    }
    
    func deviceUnregister() {
        if !userCachedStatus.isForcedLogout {
            if !deviceToken.isEmpty {
                let parameters = [
                    "DeviceUID": deviceUID,
                    "DeviceToken": deviceToken
                ]
                let completionWrapper: CompletionBlock = {task, response, error in
                    if error != nil {
                        PMLog.D("\(error)")
                        self.badToken = self.deviceToken
                        self.badUID = self.deviceUID
                    } else {
                        PMLog.D("\(response)")
                        self.deviceUID = ""
                        self.deviceToken = ""
                    }
                }
                setApiVesion(1, appVersion: 1)
                request(method: HTTPMethod.POST, path: AppConstants.BaseAPIPath + DevicePath.basePath + "/delete", parameters: parameters, completion: completionWrapper)
            }
        }
    }
    
    func cleanBadKey(newToken : NSData) {
        let newTokenString = stringFromToken(newToken)
        let oldDeviceToken = self.deviceToken
        if !oldDeviceToken.isEmpty {
            if (!deviceUID.isEmpty && !deviceID.isEmpty && deviceUID != deviceID) || newTokenString != oldDeviceToken {
                let parameters = [
                    "DeviceUID": deviceUID,
                    "DeviceToken": oldDeviceToken
                ]
                
                let completionWrapper: CompletionBlock = {task, response, error in
                }
                setApiVesion(1, appVersion: 1)
                request(method: HTTPMethod.POST, path: AppConstants.BaseAPIPath + DevicePath.basePath + "/delete", parameters: parameters, completion: completionWrapper)
            }
        }
        
        if !badUID.isEmpty || !badToken.isEmpty {
            let parameters = [
                "DeviceUID": badUID,
                "DeviceToken": badToken
            ]
            
            setApiVesion(1, appVersion: 1)
            request(method: HTTPMethod.POST, path: AppConstants.BaseAPIPath + DevicePath.basePath + "/delete", parameters: parameters, completion:{ (task, response, error) -> Void in
                if error == nil {
                    self.badToken = ""
                    self.badUID = ""
                }
            })
        }
    }
    
    // MARK: - Private methods
    
    private struct DeviceKey {
        static let token = "DeviceTokenKey"
        static let UID = "DeviceUID"
        
        static let badToken = "DeviceBadToken"
        static let badUID = "DeviceBadUID"
    }
    
    private var deviceID: String {
        return UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
    }
    
    private var deviceToken: String {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(DeviceKey.token) ?? ""
        }
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: DeviceKey.token)
        }
    }
    private var deviceUID: String {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(DeviceKey.UID) ?? ""
        }
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: DeviceKey.UID)
        }
    }
    
    private var badToken: String {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(DeviceKey.badToken) ?? ""
        }
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: DeviceKey.badToken)
        }
    }
    private var badUID: String {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(DeviceKey.badUID) ?? ""
        }
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: DeviceKey.badUID)
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

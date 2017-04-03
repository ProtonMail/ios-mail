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
    
    fileprivate struct DevicePath {
        static let basePath = "/device"
    }
    func deviceRegisterWithToken(_ token: Data, completion: CompletionBlock?) {
        let tokenString = stringFromToken(token)
        deviceToken = tokenString
        deviceUID = deviceID

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
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            ver = version
        }
        let parameters = [
            "DeviceUID" : deviceID,
            "DeviceToken" : tokenString,
            "DeviceName" : UIDevice.current.name,
            "DeviceModel" : UIDevice.current.model,
            "DeviceVersion" : UIDevice.current.systemVersion,
            "AppVersion" : "iOS_\(ver)",
            "Environment" : env
        ] as [String : Any]
        
        //setApiVesion(1, appVersion: 1)
        request(method: .post, path: AppConstants.API_PATH + DevicePath.basePath, parameters: parameters, headers: ["x-pm-apiversion": 1], completion: completion)
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
                        //PMLog.D("\(error)")
                        self.badToken = self.deviceToken
                        self.badUID = self.deviceUID
                    } else {
                        //PMLog.D("\(response)")
                        self.deviceUID = ""
                        self.deviceToken = ""
                    }
                }
                //setApiVesion(1, appVersion: 1)
                request(method: HTTPMethod.post, path: AppConstants.API_PATH + DevicePath.basePath + "/delete", parameters: parameters, headers: ["x-pm-apiversion": 1], completion: completionWrapper)
            }
        }
    }
    
    func cleanBadKey(_ newToken : Data) {
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
               // setApiVesion(1, appVersion: 1)
                request(method: HTTPMethod.post, path: AppConstants.API_PATH + DevicePath.basePath + "/delete", parameters: parameters, headers: ["x-pm-apiversion": 1], completion: completionWrapper)
            }
        }
        
        if !badUID.isEmpty || !badToken.isEmpty {
            let parameters = [
                "DeviceUID": badUID,
                "DeviceToken": badToken
            ]
            
           // setApiVesion(1, appVersion: 1)
            request(method: HTTPMethod.post, path: AppConstants.API_PATH + DevicePath.basePath + "/delete", parameters: parameters, headers: ["x-pm-apiversion": 1], completion:{ (task, response, error) -> Void in
                if error == nil {
                    self.badToken = ""
                    self.badUID = ""
                }
            })
        }
    }
    
    // MARK: - Private methods
    
    fileprivate struct DeviceKey {
        static let token = "DeviceTokenKey"
        static let UID = "DeviceUID"
        
        static let badToken = "DeviceBadToken"
        static let badUID = "DeviceBadUID"
    }
    
    fileprivate var deviceID: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    fileprivate var deviceToken: String {
        get {
            return UserDefaults.standard.string(forKey: DeviceKey.token) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: DeviceKey.token)
        }
    }
    fileprivate var deviceUID: String {
        get {
            return UserDefaults.standard.string(forKey: DeviceKey.UID) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: DeviceKey.UID)
        }
    }
    
    fileprivate var badToken: String {
        get {
            return UserDefaults.standard.string(forKey: DeviceKey.badToken) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: DeviceKey.badToken)
        }
    }
    fileprivate var badUID: String {
        get {
            return UserDefaults.standard.string(forKey: DeviceKey.badUID) ?? ""
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: DeviceKey.badUID)
        }
    }
    
    fileprivate func stringFromToken(_ token: Data) -> String {
        let tokenChars = (token as NSData).bytes.bindMemory(to: CChar.self, capacity: token.count)
        var tokenString = ""
        for i in 0 ..< token.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        return tokenString
    }
}

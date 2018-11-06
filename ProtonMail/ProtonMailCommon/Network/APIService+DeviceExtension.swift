//
//  APIService+DeviceExtension.swift
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

/// DeviceExtension
//TODO:: here need a refactor
extension APIService {
    
    fileprivate struct DevicePath {
        static let basePath = "/devices"
    }
    func device(registerWith token: String, completion: CompletionBlock?) {
        deviceToken = token
        deviceUID = deviceID
        
//        var env = 4
//        if #available(iOS 10.0, *) { //encrypt
//            env = 4
//        } else { // not encrypt
//            env = 5
//        }
        
        #if Enterprise
            #if DEBUG
//                let env = 20
                let env = 7
            #else
//                let env = 21
                let env = 7
            #endif
        #else
            // const PROVIDER_FCM_IOS = 4;
            // const PROVIDER_FCM_IOS_BETA = 5;
            #if DEBUG
//                let env = 1
                let env = 6
            #else
//                let env = 2
                let env = 6
            #endif
            
        #endif
        var ver = "1.0.0"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            ver = version
        }
        let parameters = [
            "DeviceUID" : deviceID,
            "DeviceToken" : token,
            "DeviceName" : UIDevice.current.name,
            "DeviceModel" : UIDevice.current.model,
            "DeviceVersion" : UIDevice.current.systemVersion,
            "AppVersion" : "iOS_\(ver)",
            "Environment" : env
        ] as [String : Any]
        
        request(method: .post,
                path: AppConstants.API_PATH + DevicePath.basePath,
                parameters: parameters,
                headers: ["x-pm-apiversion": 3],
                completion: completion)
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
                        self.badToken = self.deviceToken
                        self.badUID = self.deviceUID
                    } else {
                        self.deviceUID = ""
                        self.deviceToken = ""
                    }
                }
                request(method: .delete,
                        path: AppConstants.API_PATH + DevicePath.basePath,
                        parameters: parameters,
                        headers: ["x-pm-apiversion": 3],
                        completion: completionWrapper)
            }
        }
    }
    
    func cleanBadKey(_ newToken : String) {
        let newTokenString = newToken // stringFromToken(newToken)
        let oldDeviceToken = self.deviceToken
        if !oldDeviceToken.isEmpty {
            if (!deviceUID.isEmpty && !deviceID.isEmpty && deviceUID != deviceID) || newTokenString != oldDeviceToken {
                let parameters = [
                    "DeviceUID": deviceUID,
                    "DeviceToken": oldDeviceToken
                ]
                
                let completionWrapper: CompletionBlock = {task, response, error in
                    
                }
                request(method: .delete,
                        path: AppConstants.API_PATH + DevicePath.basePath,
                        parameters: parameters,
                        headers: ["x-pm-apiversion": 3],
                        completion: completionWrapper)
            }
        }
        
        if !badUID.isEmpty || !badToken.isEmpty {
            let parameters = [
                "DeviceUID": badUID,
                "DeviceToken": badToken
            ]
            
            request(method: .delete,
                    path: AppConstants.API_PATH + DevicePath.basePath,
                    parameters: parameters,
                    headers: ["x-pm-apiversion": 3],
                    completion:{ (task, response, error) -> Void in
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
            return SharedCacheBase.getDefault().string(forKey: DeviceKey.token) ?? ""
        }
        set {
            SharedCacheBase.getDefault().setValue(newValue, forKey: DeviceKey.token)
        }
    }
    fileprivate var deviceUID: String {
        get {
            return SharedCacheBase.getDefault().string(forKey: DeviceKey.UID) ?? ""
        }
        set {
            SharedCacheBase.getDefault().setValue(newValue, forKey: DeviceKey.UID)
        }
    }
    
    fileprivate var badToken: String {
        get {
            return SharedCacheBase.getDefault().string(forKey: DeviceKey.badToken) ?? ""
        }
        set {
            SharedCacheBase.getDefault().setValue(newValue, forKey: DeviceKey.badToken)
        }
    }
    fileprivate var badUID: String {
        get {
            return SharedCacheBase.getDefault().string(forKey: DeviceKey.badUID) ?? ""
        }
        set {
            SharedCacheBase.getDefault().setValue(newValue, forKey: DeviceKey.badUID)
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

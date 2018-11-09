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
import Crypto

extension APIService {
    typealias EncryptionKit = PushSubscriptionSettings.EncryptionKit
    
    fileprivate struct DevicePath {
        static let basePath = "/devices"
    }
    
    func device(registerWith settings: PushSubscriptionSettings, completion: CompletionBlock?) {
        let env = 16 // FIXME: debug value only
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        let parameters = [
            "DeviceToken" : settings.token,
            "DeviceName" : UIDevice.current.name,
            "DeviceModel" : UIDevice.current.model,
            "DeviceVersion" : UIDevice.current.systemVersion,
            "AppVersion" : "iOS_\(ver)",
            "Environment" : env,
            "PublicKey" : settings.encryptionKit.publicKey
        ] as [String : Any]
        
        request(method: .post,
                path: AppConstants.API_PATH + DevicePath.basePath,
                parameters: parameters,
                headers: ["x-pm-apiversion": 3],
                completion: completion)
    }
    
    func deviceUnregister(_ settings: PushSubscriptionSettings, completion: @escaping CompletionBlock) {
        guard !userCachedStatus.isForcedLogout else {
            return
        }
        
        let parameters = [
            "DeviceToken": settings.token,
            "UID": settings.UID
        ]

        request(method: .delete,
                path: AppConstants.API_PATH + DevicePath.basePath,
                parameters: parameters,
                headers: ["x-pm-apiversion": 3],
                authenticated: false,
                completion: completion)
    }
}

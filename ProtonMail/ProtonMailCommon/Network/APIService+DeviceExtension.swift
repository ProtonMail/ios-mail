//
//  APIService+DeviceExtension.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import Crypto
import PMCommon

extension PMAPIService {
    fileprivate struct DevicePath {
        static let basePath = "/devices"
    }
    
    func device(registerWith settings: PushSubscriptionSettings,
                authCredential: AuthCredential?, completion: CompletionBlock?) {
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        #if Enterprise
        #if DEBUG
        //let env = 20
        let env = 17  /// Enterprise dev certification build (fabric beta)
        #else
        //let env = 21
        let env = 7 ///Enterprise release certification build
        #endif
        #else
        // const PROVIDER_FCM_IOS = 4; // google firebase live
        // const PROVIDER_FCM_IOS_BETA = 5; //google firebase beta
        #if DEBUG
        //let env = 1
        let env = 16 /// apple store certificaiton dev build (dev)
        #else
        //let env = 2
        let env = 6  /// apple store release build (for apple store submit)
        #endif
        
        #endif
        
        let deviceName = UIDevice.current.name
        let parameters = [
            "DeviceToken" : settings.token,
            "DeviceName" : deviceName.isEmpty ? "defaultName" : deviceName,
            "DeviceModel" : UIDevice.current.model,
            "DeviceVersion" : UIDevice.current.systemVersion,
            "AppVersion" : "iOS_\(ver)",
            "Environment" : env,
            "PublicKey" : settings.encryptionKit.publicKey
        ] as [String : Any]
        
        self.request(method: .post,
                     path: DevicePath.basePath,
                     parameters: parameters,
                     headers: [HTTPHeader.apiVersion: 3], //will be deprecated
                     authenticated: false,
                     autoRetry: true,
                     customAuthCredential: authCredential,
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
        self.request(method: .delete,
                     path: DevicePath.basePath,
                     parameters: parameters,
                     headers: [HTTPHeader.apiVersion: 3], //will be deprecated
                     authenticated: false,
                     autoRetry: true,
                     customAuthCredential: nil,
                     completion: completion)
    }
}

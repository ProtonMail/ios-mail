//
//  DeviceAPI.swift
//  ProtonMail - Created on 2/10/16.
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


final class DeviceUtil {
    
    fileprivate struct DeviceKey {
        static let token = "DeviceTokenKey"
    }
    
    static var deviceID: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
    
    static var deviceToken: String? {
        get {
            return SharedCacheBase.getDefault().string(forKey: DeviceKey.token)
        }
        set {
            SharedCacheBase.getDefault().setValue(newValue, forKey: DeviceKey.token)
        }
    }
    
}


// MARK : update right swipe action
final class RegisterDeviceRequest<T : ApiResponse> : ApiRequest<T> {
    let token: Data!
    
    init(token: Data) {
        self.token = token
    }
    
    override func toDictionary() -> [String : Any]? {
        let tokenString = token.stringFromToken()
        DeviceUtil.deviceToken = tokenString
        
        //UIApplication.sharedApplication().release
        
        // 1 : ios dev
        // 2 : ios production
        // 3 : ios simulator
        
        //        #if DEBUG
        //            let env = 1
        //            #else
        //            let env = 2
        //        #endif
        
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
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            ver = version
        }
        let parameters : [String : Any] = [
//            "DeviceUID" : DeviceUtil.deviceID,
            "DeviceToken" : tokenString,
//            "DeviceName" : UIDevice.current.name,
//            "DeviceModel" : UIDevice.current.model,
//            "DeviceVersion" : UIDevice.current.systemVersion,
//            "AppVersion" : "iOS_\(ver)",
            "Environment" : env
        ]
        return parameters
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return DeviceAPI.path
    }
    
    override func apiVersion() -> Int {
        return DeviceAPI.v_register_device
    }
}



final class UnRegisterDeviceRequest<T : ApiResponse> : ApiRequest<T> {

    override init() {
    }

    override func toDictionary() -> [String : Any]? {
        if let deviceToken = DeviceUtil.deviceToken {
            let parameters = [
                "device_uid": DeviceUtil.deviceID,
                "device_token": deviceToken
            ]
            return parameters
        }
        return nil
    }

    override func method() -> HTTPMethod {
        return .delete
    }

    override func path() -> String {
        return DeviceAPI.path
    }

    override func apiVersion() -> Int {
        return DeviceAPI.v_delete_device
    }
}

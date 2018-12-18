//
//  DeviceAPI.swift
//  ProtonMail - Created on 2/10/16.
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
            "DeviceUID" : DeviceUtil.deviceID,
            "DeviceToken" : tokenString,
            "DeviceName" : UIDevice.current.name,
            "DeviceModel" : UIDevice.current.model,
            "DeviceVersion" : UIDevice.current.systemVersion,
            "AppVersion" : "iOS_\(ver)",
            "Environment" : env
        ]
        print(parameters)
        return parameters
    }
    
    override func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func method() -> APIService.HTTPMethod {
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

    override func method() -> APIService.HTTPMethod {
        return .delete
    }

    override func path() -> String {
        return DeviceAPI.path
    }

    override func apiVersion() -> Int {
        return DeviceAPI.v_delete_device
    }
}

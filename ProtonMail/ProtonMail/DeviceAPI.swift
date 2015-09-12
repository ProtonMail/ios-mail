//
//  DeviceAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/10/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


public class DeviceUtil {
    
    private struct DeviceKey {
        static let token = "DeviceTokenKey"
    }
    
    static var deviceID: String {
        return UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
    }
    
     static var deviceToken: String? {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(DeviceKey.token)
        }
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: DeviceKey.token)
        }
    }

}


// MARK : update right swipe action
public class RegisterDeviceRequest<T : ApiResponse> : ApiRequest<T> {
    let token: NSData!
    
    init(token: NSData) {
        self.token = token
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
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
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            ver = version
        }
        let parameters : Dictionary<String, AnyObject> = [
            "DeviceUID" : DeviceUtil.deviceID,
            "DeviceToken" : tokenString,
            "DeviceName" : UIDevice.currentDevice().name,
            "DeviceModel" : UIDevice.currentDevice().model,
            "DeviceVersion" : UIDevice.currentDevice().systemVersion,
            "AppVersion" : "iOS_\(ver)",
            "Environment" : env
        ]
        
        return parameters
    }
    
    override public func getIsAuthFunction() -> Bool {
        return false
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .POST
    }
    
    override public func getRequestPath() -> String {
        return DeviceAPI.Path
    }
    
    override public func getVersion() -> Int {
        return DeviceAPI.V_RegisterDeviceRequest
    }
}



public class UnRegisterDeviceRequest<T : ApiResponse> : ApiRequest<T> {

    override init() {
    }

    override func toDictionary() -> Dictionary<String, AnyObject>? {
        if let deviceToken = DeviceUtil.deviceToken {
            let parameters = [
                "device_uid": DeviceUtil.deviceID,
                "device_token": deviceToken
            ]
            return parameters
        }
        return nil
    }

    override func getAPIMethod() -> APIService.HTTPMethod {
        return .DELETE
    }

    override public func getRequestPath() -> String {
        return DeviceAPI.Path
    }

    override public func getVersion() -> Int {
        return DeviceAPI.V_UnRegisterDeviceRequest
    }
}

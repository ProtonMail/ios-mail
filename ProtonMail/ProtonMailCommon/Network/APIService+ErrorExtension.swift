//
//  APIService+ErrorExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/22/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation


import Fabric
import Crashlytics


let AuthErrorTitle : String          = "AuthRefresh-Error"
let QueueErrorTitle : String         = "Queue-Error"
let CacheErrorTitle : String         = "LocalCache-Error"
let SendingErrorTitle : String       = "Sending-Error"
let ContactsErrorTitle : String      = "Contacts-Error"
let FetchUserInfoErrorTitle : String = "UserInfo-Error"

extension NSError {
    
    func upload(toFabric title : String ) -> Void {
        var ver = "1.0.0"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            ver = version
        }
        
        Answers.logCustomEvent(withName: title,
                                       customAttributes: [
                                        "name": sharedUserDataService.username ?? "unknow",
                                        "DeviceName" : UIDevice.current.name,
                                        "DeviceModel" : UIDevice.current.model,
                                        "DeviceVersion" : UIDevice.current.systemVersion,
                                        "AppVersion" : "iOS_\(ver)",
                                        "code" : code,
                                        "error_desc": description,
                                        "error_full": localizedDescription,
                                        "error_reason" : "\(String(describing: localizedFailureReason))"])
    }


    
    
}

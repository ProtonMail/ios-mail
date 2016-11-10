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


let AuthErrorTitle : String = "AuthRefresh-Error"
let QueueErrorTitle : String = "Queue-Error"
let CacheErrorTitle : String = "LocalCache-Error"
let SendingErrorTitle : String = "Sending-Error"
let ContactsErrorTitle : String = "Contacts-Error"


extension NSError {
    

    func uploadFabricAnswer(title : String ) -> Void {
        
        var ver = "1.0.0"
        if let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String {
            ver = version
        }
        
        Answers.logCustomEventWithName(title,
                                       customAttributes: [
                                        "name": sharedUserDataService.username ?? "unknow",
                                        "DeviceName" : UIDevice.currentDevice().name,
                                        "DeviceModel" : UIDevice.currentDevice().model,
                                        "DeviceVersion" : UIDevice.currentDevice().systemVersion,
                                        "AppVersion" : "iOS_\(ver)",
                                        "code" : code,
                                        "error_desc": description,
                                        "error_full": localizedDescription,
                                        "error_reason" : "\(localizedFailureReason)"])
    }


    
    
}

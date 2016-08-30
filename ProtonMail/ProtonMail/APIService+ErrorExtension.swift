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

extension NSError {

    func uploadFabricAnswer() -> Void {
        Answers.logCustomEventWithName("AuthRefresh-Error",
                                       customAttributes: [
                                        "name": sharedUserDataService.username ?? "unknow",
                                        "code" : code,
                                        "error_desc": description,
                                        "error_full": localizedDescription,
                                        "error_reason" : "\(localizedFailureReason)"])
    }


    
    
}
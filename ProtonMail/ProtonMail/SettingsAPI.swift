//
//  SettingAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



// MARK : update domain order
public class UpdateDomainOrder<T : ApiResponse> : ApiRequest<T> {
    let newOrder : Array<Int>!
    
    init(adds:Array<Int>!) {
        self.newOrder = adds
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        var out : [String : AnyObject] = ["Order" : self.newOrder]
    
        //self.domains.();
        PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
    
    override public func getRequestPath() -> String {
        return SettingsAPI.Path + "/addressorder" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return SettingsAPI.V_SettingsUpdateDomainRequest
    }
}



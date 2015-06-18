//
//  APIServiceRequest.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



public class ApiRequest {
    init () { }
    public func toJSON() -> Dictionary<String,AnyObject> {
        NSException(name:"name", reason:"reason", userInfo:nil).raise()
        return Dictionary<String,AnyObject>()
    }
    
    public func getVersion () -> Int {
        return 1
    }
    
    public func getRequestPath () -> String {
        NSException(name:"name", reason:"reason", userInfo:nil).raise()
        return "";
    }
}
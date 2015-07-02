//
//  APIServiceResponse.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class ApiResponse {
    public required init() {}
    
    public var code : Int! = 1000
    public var error : String?
    public var errorDetails : String?
    
    func CheckHttpStatus() -> Bool {
        return true
    }
    
    func CheckBodyStatus () -> Bool {
        return true
    }
    
    func ParseResponseError (response: Dictionary<String,AnyObject>!) -> Bool {
        code = response["Code"] as? Int
        error = response["Error"] as? String
        errorDetails = response["ErrorDescription"] as? String
        return code != 1000
    }
    
    func ParseResponse (response: Dictionary<String,AnyObject>!) -> Bool {
        return true
    }
}

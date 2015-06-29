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
    
    public var code : String? = "1000"
    public var error : String?
    
    func CheckHttpStatus() -> Bool {
        return true
    }
    
    func CheckBodyStatus () -> Bool {
        return true
    }
    
    func ParseResponseError (response: Dictionary<String,AnyObject>?) -> Bool {
        code = response?["Code"] as? String
        error = response?["Error"] as? String
        
        return true
    }
    
    func ParseResponse (response: Dictionary<String,AnyObject>!) -> Bool {
        return true
    }
}
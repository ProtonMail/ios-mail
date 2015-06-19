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
    
    func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            }
        }
        return ""
    }

}
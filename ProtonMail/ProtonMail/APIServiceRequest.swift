//
//  APIServiceRequest.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


//abstract api request base class
public class ApiRequest {
    init () { }
    
    
    /**
    conver requset object to dictionary
    
    :returns: request dictionary
    */
    public func toDictionary() -> Dictionary<String,AnyObject> {
        NSException(name:"name", reason:"reason", userInfo:nil).raise()
        return Dictionary<String,AnyObject>()
    }
    
    /**
    get current api request
    
    :returns: int version number
    */
    public func getVersion () -> Int {
        return 1
    }
    
    
    /**
    get request path
    
    :returns: String value
    */
    public func getRequestPath () -> String {
        NSException(name:"Not Implement", reason:"The class didn't implement yet", userInfo:nil).raise()
        return "";
    }
    
    
    /**
    base class for convert anyobject to a json string
    
    :param: value         AnyObject input value
    :param: prettyPrinted Bool is need pretty format
    
    :returns: String value
    */
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
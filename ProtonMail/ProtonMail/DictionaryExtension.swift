//
//  DictionaryExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/2/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation





extension Dictionary { //email name
    func getDisplayName() -> String {    //this function only for the To CC BCC list parsing
        if let key = "Name" as? Key {
            let name = self[key] as? String ?? ""
            if !name.isEmpty {
                return name
            }
        }
        if let key = "Address" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }
    
    func getAddress() -> String {    //this function only for the To CC BCC list parsing
        if let key = "Address" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }
    
    func getName() -> String {    //this function only for the To CC BCC list parsing
        if let key = "Name" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }
    
    
    /**
    base class for convert anyobject to a json string
    
    :param: value         AnyObject input value
    :param: prettyPrinted Bool is need pretty format
    
    :returns: String value
    */
    func JSONStringify(prettyPrinted: Bool = false) -> String {
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        let anyObject: AnyObject = self as! AnyObject
        if NSJSONSerialization.isValidJSONObject(anyObject) {
            if let data = NSJSONSerialization.dataWithJSONObject(anyObject, options: options, error: nil) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            }
        }
        return ""
    }
    
}


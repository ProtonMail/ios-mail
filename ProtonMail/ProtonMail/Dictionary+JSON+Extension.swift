//
//  DictionaryExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/2/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    /**
     base class for convert anyobject to a json string
     
     :param: value         AnyObject input value
     :param: prettyPrinted Bool is need pretty format
     
     :returns: String value
     */
    public func json(prettyPrinted : Bool = false) -> String {
        let options : JSONSerialization.WritingOptions = prettyPrinted ? .prettyPrinted : JSONSerialization.WritingOptions()
        let anyObject: Any = self
        if JSONSerialization.isValidJSONObject(anyObject) {
            do {
                let data = try JSONSerialization.data(withJSONObject: anyObject, options: options)
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
            } catch let ex as NSError {
                PMLog.D("\(ex)")
            }
        }
        return ""
    }
    
}


extension Array where Iterator.Element == [String: Any]  {
    /**
     base class for convert anyobject to a json string
     
     :param: value         AnyObject input value
     :param: prettyPrinted Bool is need pretty format
     
     :returns: String value
     */
    public func json(prettyPrinted : Bool = false) -> String {
        let options : JSONSerialization.WritingOptions = prettyPrinted ? .prettyPrinted : JSONSerialization.WritingOptions()
        let anyObject: Any = self
        if JSONSerialization.isValidJSONObject(anyObject) {
            do {
                let data = try JSONSerialization.data(withJSONObject: anyObject, options: options)
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
            } catch let ex as NSError {
                PMLog.D("\(ex)")
            }
        }
        return ""
    }
    
}



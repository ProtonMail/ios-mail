//
//  APIService+ResponseTransfor.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/22/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation
extension APIService {
    
    private struct TransType {
        static let boolean = "BoolTransformer"
        static let date = "DateTransformer"
        static let number = "NumberTransformer"
        static let jsonString = "JsonStringTransformer"
        static let jsonObject = "JsonToObjectTransformer"
        static let encodedData = "EncodedDataTransformer"
    }
    
    // MARK: - Private methods
    internal func setupValueTransforms() {
        NSValueTransformer.grt_setValueTransformerWithName(TransType.boolean) { (value) -> AnyObject? in
            if let bool = value as? NSString {
                return bool.boolValue
            } else if let bool = value as? Bool {
                return bool
            }
            return nil
        }
        
        NSValueTransformer.grt_setValueTransformerWithName(TransType.date) { (value) -> AnyObject? in
            if let timeString = value as? NSString {
                let time = timeString.doubleValue as NSTimeInterval
                if time != 0 {
                    return time.asDate()
                }
            } else if let date = value as? NSDate {
                return date.timeIntervalSince1970
            } else if let dateNumber = value as? NSNumber {
                let time = dateNumber.doubleValue as NSTimeInterval
                if time != 0 {
                    return time.asDate()
                }
            }
            return nil
        }
        
        NSValueTransformer.grt_setValueTransformerWithName(TransType.number) { (value) -> AnyObject? in
            if let number = value as? String {
                return number ?? 0 as NSNumber
            } else if let number = value as? NSNumber {
                return number
            }
            return nil
        }
        
        NSValueTransformer.grt_setValueTransformerWithName(TransType.jsonString) { (value) -> AnyObject? in
            do {
                if let tag = value as? NSArray {
                    let bytes : NSData = try NSJSONSerialization.dataWithJSONObject(tag, options: NSJSONWritingOptions())
                    let strJson : String = NSString(data: bytes, encoding: NSUTF8StringEncoding)! as String
                    return strJson
                }
            } catch let ex as NSError {
                PMLog.D("\(ex)")
            }
            return "";
        }
        
        NSValueTransformer.grt_setValueTransformerWithName(TransType.jsonObject) { (value) -> AnyObject? in
            do {
                if let tag = value as? [String:String] {
                    let bytes : NSData = try NSJSONSerialization.dataWithJSONObject(tag, options: NSJSONWritingOptions())
                    let strJson : String = NSString(data: bytes, encoding: NSUTF8StringEncoding)! as String
                    return strJson
                }
            } catch let ex as NSError {
                PMLog.D("\(ex)")
            }
            return "";
        }
        
        NSValueTransformer.grt_setValueTransformerWithName(TransType.encodedData) { (value) -> AnyObject? in
            if let tag = value as? String {
                if let data: NSData = NSData(base64EncodedString: tag, options: NSDataBase64DecodingOptions(rawValue: 0)) {
                    return data
                }
            }
            return nil;
        }
    }
}
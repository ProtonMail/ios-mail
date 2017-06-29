//
//  APIService+ResponseTransfor.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/22/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation
import ProtonMailCommon



extension APIService {
    
    fileprivate struct TransType {
        static let boolean = "BoolTransformer"
        static let date = "DateTransformer"
        static let number = "NumberTransformer"
        static let jsonString = "JsonStringTransformer"
        static let jsonObject = "JsonToObjectTransformer"
        static let encodedData = "EncodedDataTransformer"
    }
    
    // MARK: - Private methods
    internal func setupValueTransforms() {
        ValueTransformer.grt_setValueTransformer(withName: TransType.boolean) { (value) -> Any? in
            if let bool = value as? NSString {
                return bool.boolValue
            } else if let bool = value as? Bool {
                return bool
            }
            return nil
        }
        
        ValueTransformer.grt_setValueTransformer(withName: TransType.date) { (value) -> Any? in
            if let timeString = value as? NSString {
                let time = timeString.doubleValue as TimeInterval
                if time != 0 {
                    return time.asDate()
                }
            } else if let date = value as? Date {
                return date.timeIntervalSince1970
            } else if let dateNumber = value as? NSNumber {
                let time = dateNumber.doubleValue as TimeInterval
                if time != 0 {
                    return time.asDate()
                }
            }
            return nil
        }
        
        ValueTransformer.grt_setValueTransformer(withName: TransType.number) { (value) -> Any? in
            if let number = value as? String {
                return number
            } else if let number = value as? NSNumber {
                return number
            }
            return nil
        }
        
        ValueTransformer.grt_setValueTransformer(withName: TransType.jsonString) { (value) -> Any? in
            do {
                if let tag = value as? NSArray {
                    let bytes : Data = try JSONSerialization.data(withJSONObject: tag, options: JSONSerialization.WritingOptions())
                    let strJson : String = NSString(data: bytes, encoding: String.Encoding.utf8.rawValue)! as String
                    return strJson
                }
            } catch let ex as NSError {
                PMLog.D("\(ex)")
            }
            return ""
        }
        
        ValueTransformer.grt_setValueTransformer(withName: TransType.jsonObject) { (value) -> Any? in
            do {
                if let tag = value as? [String : String] {
                    let bytes : Data = try JSONSerialization.data(withJSONObject: tag, options: JSONSerialization.WritingOptions())
                    let strJson : String = NSString(data: bytes, encoding: String.Encoding.utf8.rawValue)! as String
                    return strJson
                }
            } catch let ex as NSError {
                PMLog.D("\(ex)")
            }
            return ""
        }
        
        ValueTransformer.grt_setValueTransformer(withName: TransType.encodedData) { (value) -> Any? in
            if let tag = value as? String {
                if let data: Data = Data(base64Encoded: tag, options: NSData.Base64DecodingOptions(rawValue: 0)) {
                    return data
                }
            }
            return nil
        }
    }
}

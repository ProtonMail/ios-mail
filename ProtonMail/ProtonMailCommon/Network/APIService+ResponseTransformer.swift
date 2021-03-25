//
//  APIService+ResponseTransfor.swift
//  ProtonMail - Created on 8/22/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

extension UsersManager {
    
    fileprivate struct TransType {
        static let boolean     = "BoolTransformer"
        static let date        = "DateTransformer"
        static let number      = "NumberTransformer"
        static let jsonString  = "JsonStringTransformer"
        static let jsonObject  = "JsonToObjectTransformer"
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

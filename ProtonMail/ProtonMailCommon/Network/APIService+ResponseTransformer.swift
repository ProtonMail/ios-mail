//
//  APIService+ResponseTransfor.swift
//  ProtonMail - Created on 8/22/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

extension APIService {
    
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

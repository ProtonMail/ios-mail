//
//  APIService+ResponseTransfor.swift
//  Proton Mail - Created on 8/22/16.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

extension UsersManager {

    fileprivate struct TransType {
        static let date                     = "DateTransformer"
        static let number                   = "NumberTransformer"
        static let jsonArrayToString        = "JsonArrayToStringTransformer"
        static let jsonDictionaryToString   = "JsonDictionaryToStringTransformer"
    }

    // MARK: - Private methods
    internal func setupValueTransforms() {
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

        ValueTransformer.grt_setValueTransformer(withName: TransType.jsonArrayToString) { (value) -> Any? in
            do {
                if let tag = value as? NSArray {
                    let bytes: Data = try JSONSerialization.data(withJSONObject: tag, options: JSONSerialization.WritingOptions())
                    let strJson: String = NSString(data: bytes, encoding: String.Encoding.utf8.rawValue)! as String
                    return strJson
                }
            } catch {
            }
            return ""
        }
        ValueTransformer.grt_setValueTransformer(withName: TransType.jsonDictionaryToString) { value -> Any? in
            let dictionary = value as? [String: Any]
            return dictionary?.toString() ?? ""
        }
    }
}

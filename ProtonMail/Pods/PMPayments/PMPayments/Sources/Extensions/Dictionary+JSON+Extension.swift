//
//  Dictionary+JSON+Extension.swift
//  PMPayments - Created on 7/2/15.
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
import PMLog

extension Dictionary where Key == String, Value == Any {
    /**
     base class for convert anyobject to a json string

     :param: value         AnyObject input value
     :param: prettyPrinted Bool is need pretty format

     :returns: String value
     */
    func json(prettyPrinted: Bool = false) -> String {
        let options = prettyPrinted ? .prettyPrinted : JSONSerialization.WritingOptions()
        let anyObject: Any = self
        if JSONSerialization.isValidJSONObject(anyObject) {
            do {
                let data = try JSONSerialization.data(withJSONObject: anyObject, options: options)
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
            } catch let error as NSError {
                PMLog.debug("\(error)")
            }
        }
        return ""
    }

}

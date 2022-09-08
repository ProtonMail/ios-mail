//
//  DictionaryExtension.swift
//  Proton Mail - Created on 7/2/15.
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

extension Dictionary where Key == String, Value == Any {

    func toString() -> String? {
        guard JSONSerialization.isValidJSONObject(self),
              let data = try? JSONSerialization.data(withJSONObject: self, options: .fragmentsAllowed) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static var empty: [String: Any] {
        return [:]
    }

    static func +<Key, Value> (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        var result = lhs
        rhs.forEach { result[$0] = $1 }
        return result
    }

    ///  Returns a new dictionary that each attachment has the ordering info from the API.
    /// - Returns: A new dictionary contains attachments which have the order info inferring their
    ///  ordering from the API.
    mutating func addAttachmentOrderField() {
        if var attachments = self["Attachments"] as? [[String: Any]] {
            for index in attachments.indices {
                attachments[index]["Order"] = index
            }
            self["Attachments"] = attachments
        }
    }
}

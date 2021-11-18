// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
final class ContactsUtils {
    /// Transfer EItem prefix to item prefix
    /// Some of data starts with EItem
    /// e.g. EItem1.EMAIL;TYPE=INTERNET,HOME,pref:home@mail.com
    /// We need to transfer the prefix to Item with the correct item order
    /// - Parameter vCard2Data: Original vCard2 string data
    /// - Returns: Transferred vCard2 string data
    static func removeEItem(vCard2Data: String) -> String {
        var splits = vCard2Data.split(separator: "\r\n").map { String($0) }
        let eItemIndex = splits.indices
            .filter { splits[$0].hasPrefix("EItem") }
        guard !eItemIndex.isEmpty else { return vCard2Data }

        let maxIndex = splits.filter { $0.hasPrefix("item") }
            .map { str -> Int in
                guard let itemStr = str.split(separator: ".").first else {
                    return -1
                }
                let index = itemStr.index(str.startIndex, offsetBy: 4)
                return Int(itemStr[index...]) ?? -1
            }
            .max() ?? -1
        var newIndex = maxIndex + 1
        for index in eItemIndex {
            let item = splits[index]
            guard let prefix = item.split(separator: ".").first,
                  let range = item.range(of: prefix) else {
                continue
            }

            let suffix = item[range.upperBound...]
            splits[index] = "item\(newIndex)\(suffix)"
            newIndex += 1
        }
        let newData = splits.joined(separator: "\r\n")
        return newData + "\r\n"
    }
}

// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

/// Object that merges a field with multiple values, overriding only the type when values match
final class FieldTypeMerger<T: TypeValueContactField> {

    private(set) var result: [T] = []

    /// Returns `true` if after the merge proton items are different than device items
    private(set) var resultHasChanges: Bool = false

    /// If `T.comparableValue` match and the `T.type` is different, this function will override the proton item type
    /// - Returns: the resulting items after merging
    func merge(device: [T], proton: [T]) {
        result = []

        // we update proton items' type if the comparableValue match
        for protonItem in proton {
            let deviceMatch = device.first(where: { $0.comparableValue == protonItem.comparableValue })
            if let deviceMatch, deviceMatch.type != protonItem.type {
                result.append(protonItem.copy(changingTypeTo: deviceMatch.type))
                resultHasChanges = true
            } else {
                result.append(protonItem)
            }
        }

        // obtaining the new items only found in the device
        let protonItems = Set(Dictionary(grouping: proton, by: \.comparableValue).map(\.key))
        let newDeviceItems = device.filter { !protonItems.contains($0.comparableValue) }
        result.append(contentsOf: newDeviceItems)
        if !newDeviceItems.isEmpty {
            resultHasChanges = true
        }
    }
}

protocol TypeValueContactField {
    var type: ContactFieldType { get }
    var comparableValue: String { get }

    func copy(changingTypeTo: ContactFieldType) -> Self
}

extension ContactField.Email: TypeValueContactField {
    var comparableValue: String { emailAddress }
}

extension ContactField.PhoneNumber: TypeValueContactField {
    var comparableValue: String { number }
}

extension ContactField.Url: TypeValueContactField {
    var comparableValue: String { url }
}

//
//  Dictionary+UniquelyMergeable.swift
//  ProtonCore-Utilities-Tests - Created on 13/01/2023.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

/// Adds automatic `UniquelyMergeable` conformance to dictionaries with `UniquelyMergeable` values.
extension Dictionary: UniquelyMergeable where Value: UniquelyMergeable {

    var uniqued: [Key: Value] {
        // A dictionary inherently has unique keys.
        return self
    }

    func appending(_ other: [Key: Value]) -> [Key: Value] {
        return merging(other, uniquingKeysWith: { $0.uniquelyMerging(with: $1) })
    }
}

extension Dictionary where Value: UniquelyMergeable {

    /// Removes the values stored under the `wildcardKey`, and appends them to values for all other keys.
    func flattened(removing wildcardKey: Key) -> Self {
        guard let commonValues = self[wildcardKey] else {
            return self
        }

        return self.filter { $0.key != wildcardKey }
            .mapValues { $0.uniquelyMerging(with: commonValues) }
    }
}

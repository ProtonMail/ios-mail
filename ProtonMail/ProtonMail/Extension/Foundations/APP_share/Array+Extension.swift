// Copyright (c) 2022 Proton AG
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

extension Array {
    /// Split an array to chunks by the given size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }

    /// Removes duplicates keeping the order of the array
    ///
    /// Use this function to use a custom attribute to determine whether 2 elements are duplicated or not.
    /// e.g. `customers.unique { $0.name }`
    func unique<T: Hashable>(uniqueIdentifier: ((Element) -> (T))) -> [Element] {
        var seen = Set<T>()
        return filter { item in
            let uniqueID = uniqueIdentifier(item)
            return seen.insert(uniqueID).inserted
        }
    }
}

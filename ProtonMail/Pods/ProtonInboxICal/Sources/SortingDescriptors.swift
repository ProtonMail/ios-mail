// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import Foundation

typealias SortingDescriptor<Value> = (Value, Value) -> Bool

extension Collection {

    subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    func sorted<Value>(
        by keyPath: KeyPath<Element, Value>,
        _ comparator: (_ lhs: Value, _ rhs: Value) -> Bool
    ) -> [Element] {
        sorted {
            comparator($0[keyPath: keyPath], $1[keyPath: keyPath])
        }
    }

}

enum SortingDescriptors {

    static func increasing<Value, Property>(
        by property: @escaping (Value) -> Property
    ) -> SortingDescriptor<Value> where Property: Comparable {
        sorting(by: property, comparator: <)
    }

    static func trueFirst<Value>(by property: @escaping (Value) -> Bool) -> SortingDescriptor<Value> {
        return { lhs, rhs in
            property(lhs) && !property(rhs)
        }
    }

    private static func sorting<Value, Property>(
        by property: @escaping (Value) -> Property,
        comparator: @escaping (_ lhs: Property, _ rhs: Property) -> Bool
    ) -> SortingDescriptor<Value> where Property: Comparable {
        return { lhs, rhs in
            comparator(property(lhs), property(rhs))
        }
    }

}

// Copyright (c) 2022 Proton Technologies AG
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

class Cache<KeyType: Hashable, ValueType: Cacheable> {
    private class Key: NSObject {
        let wrapped: KeyType

        override var hash: Int {
            wrapped.hashValue
        }

        init(wrapping wrapped: KeyType) {
            self.wrapped = wrapped
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? Self else {
                return false
            }

            return wrapped == other.wrapped
        }
    }

    private class Value {
        let wrapped: ValueType

        init(wrapping wrapped: ValueType) {
            self.wrapped = wrapped
        }
    }

    private let internalCache = NSCache<Key, Value>()

    init(totalCostLimit: Int) {
        internalCache.totalCostLimit = totalCostLimit
    }

    subscript(key: KeyType) -> ValueType? {
        get {
            let wrappedKey = Key(wrapping: key)
            return internalCache.object(forKey: wrappedKey)?.wrapped
        }
        set {
            let wrappedKey = Key(wrapping: key)
            if let newValue = newValue {
                internalCache.setObject(Value(wrapping: newValue), forKey: wrappedKey, cost: newValue.cost)
            } else {
                internalCache.removeObject(forKey: wrappedKey)
            }
        }
    }

    func purge() {
        internalCache.removeAllObjects()
    }
}

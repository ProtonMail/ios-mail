// Copyright (c) 2024 Proton Technologies AG
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

/// Keeps `maxElements` in memory. When the limit is reached evicts from the cache the oldest element
actor MemoryCache<Key: Hashable, Value> {
    private let maxElements: Int

    private var dictionary = [Key: Value]()
    private var fifoQueue = [Key]()

    init(maxElements: Int = 50) {
        self.maxElements = maxElements
    }

    func object(for key: Key) -> Value? {
        guard let object = dictionary[key] else {
            return nil
        }
        rearrangeFifoQueue(for: key)
        return object
    }

    func setObject(_ object: Value, for key: Key) {
        dictionary[key] = object
        rearrangeFifoQueue(for: key)
        if dictionary.count > maxElements {
            let lastKey = fifoQueue.removeLast()
            dictionary[lastKey] = nil
        }
    }

    private func rearrangeFifoQueue(for key: Key) {
        if let index = fifoQueue.firstIndex(of: key) {
            fifoQueue.rearrange(from: index, to: 0)
        } else {
            fifoQueue.insert(key, at: 0)
        }
    }
}

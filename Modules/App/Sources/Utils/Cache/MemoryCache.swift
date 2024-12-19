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

import InboxCore
import SwiftUI

/// Keeps `maxElements` in memory. When the limit is reached evicts from the cache the oldest element
final class MemoryCache<Key: Hashable & Sendable, Value: Sendable>: @unchecked Sendable {
    private let maxElements: Int
    private var dictionary = [Key: Value]()
    private var fifoQueue = [Key]()

    private let queue = DispatchQueue(label: "\(Bundle.defaultIdentifier).MemoryCache", attributes: .concurrent)

    init(maxElements: Int = 30) {
        self.maxElements = maxElements
    }

    func object(for key: Key) -> Value? {
        var result: Value?
        queue.sync {
            result = dictionary[key]
            if result != nil {
                rearrangeFifoQueue(for: key)
            }
        }
        return result
    }

    func setObject(_ object: Value, for key: Key) {
        queue.async(flags: .barrier) {
            self.dictionary[key] = object
            self.rearrangeFifoQueue(for: key)
            if self.dictionary.count > self.maxElements {
                let lastKey = self.fifoQueue.removeLast()
                self.dictionary[lastKey] = nil
            }
        }
    }

    // Private helper method to rearrange the FIFO queue
    private func rearrangeFifoQueue(for key: Key) {
        if let index = fifoQueue.firstIndex(of: key) {
            fifoQueue.remove(at: index)
        }
        fifoQueue.insert(key, at: 0)
    }
}

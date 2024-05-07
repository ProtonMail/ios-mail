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

import class SwiftUI.UIImage

/**
 Temporary cache until the Rust SDK provides one.

 This cache keeps in memory sender images to avoid unnecessary requests and avoid UI glitches
 */
actor SenderImageMemoryCache {
    static let shared = SenderImageMemoryCache()

    private var senderImages = [Int: UIImage]()
    private var fifoQueue = [Int]()
    private let maxQueue = 50

    func image(for key: Int) -> UIImage? {
        guard let image = senderImages[key] else {
            return nil
        }
        rearrangeFifoQueue(for: key)
        return image
    }

    func setImage(_ image: UIImage, for key: Int) {
        senderImages[key] = image
        rearrangeFifoQueue(for: key)
        if senderImages.count > maxQueue {
            let lastKey = fifoQueue.removeLast()
            senderImages[lastKey] = nil
        }
    }

    private func rearrangeFifoQueue(for key: Int) {
        if let index = fifoQueue.firstIndex(of: key) {
            fifoQueue.rearrange(from: index, to: 0)
        } else {
            fifoQueue.insert(key, at: 0)
        }
    }
}

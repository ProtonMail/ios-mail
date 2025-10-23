// Copyright (c) 2025 Proton Technologies AG
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

struct PaginatedListUpdate<Item: Equatable>: CustomStringConvertible {
    let isLastPage: Bool
    let value: PaginatedListUpdateType<Item>
    let completion: (() -> Void)?

    init(isLastPage: Bool, value: PaginatedListUpdateType<Item>, completion: (() -> Void)? = nil) {
        self.isLastPage = isLastPage
        self.value = value
        self.completion = completion
    }

    var description: String {
        "\(value), isLastPage = \(isLastPage)"
    }
}

enum PaginatedListUpdateType<Item>: CustomStringConvertible {
    case none
    case append(items: [Item])
    case replaceRange(from: Int, to: Int, items: [Item])
    case replaceFrom(index: Int, items: [Item])
    case replaceBefore(index: Int, items: [Item])
    case error(Error)

    var description: String {
        switch self {
        case .none: "none"
        case .append(let items): "append \(items.count) items"
        case .replaceRange(let from, let to, let items): "replaceRange from \(from) to \(to), \(items.count) items"
        case .replaceFrom(let index, let items): "replaceFrom index \(index), \(items.count) items"
        case .replaceBefore(let index, let items): "replaceBefore index \(index), \(items.count) items"
        case .error(let error): "error: \(error)"
        }
    }
}

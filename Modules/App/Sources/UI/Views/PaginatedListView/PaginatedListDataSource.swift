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

import Combine
import InboxCore
import SwiftUI

@MainActor
final class PaginatedListDataSource<Item: Equatable>: ObservableObject {
    typealias FetchMore = (_ isFetchingFirstPage: Bool) -> Void

    @Published private(set) var state: State
    private let fetchMore: FetchMore

    init(fetchMore: @escaping FetchMore) {
        self.state = .init()
        self.fetchMore = fetchMore
    }

    /// This function is for convenience to be able to show the initial state if the operation to have the fetchPage ready
    /// takes some time and we are not ready to call `fetchInitialPage`.
    func resetToInitialState() {
        resetState()
    }

    /// Resets the data and state and launches a new request to fetch the first page
    func fetchInitialPage() {
        resetState()
        fetchNextPageItems()
    }

    func fetchNextPageIfNeeded() {
        guard !state.isFetchingNextPage && !state.isLastPage else { return }
        fetchNextPageItems()
    }

    func handle(update: PaginatedListUpdate<Item>) {
        var newState = state
        newState.isFetchingNextPage = false
        newState.isFetchingFirstPage = false
        newState.isLastPage = update.isLastPage

        switch update.value {
        case .append(let items):
            newState.items.append(contentsOf: items)
        case .replaceRange(let from, let to, let items):
            guard isSafeIndex(from), isSafeIndex(to) else { break }
            newState.items.replaceSubrange(from..<to, with: items)
        case .replaceFrom(let index, let items):
            guard isSafeIndex(index) else { break }
            newState.items.replaceSubrange(index..<newState.items.endIndex, with: items)
        case .replaceBefore(let index, let items):
            guard isSafeIndex(index) else { break }
            newState.items.replaceSubrange(newState.items.startIndex..<index, with: items)
        case .none, .error:
            break
        }

        state = newState
        AppLogger.log(message: "handle update: \(update), total items = \(state.items.count)", category: .mailbox)
        update.completion?()
    }

    private func fetchNextPageItems() {
        updateStateMarkIsFetchingNextPage()
        fetchMore(state.isFetchingFirstPage)
    }

    private func isSafeIndex(_ index: Int) -> Bool {
        let isSafe = index >= 0 && index <= state.items.count
        if !isSafe {
            AppLogger.log(message: "wrong index \(index)", category: .mailbox, isError: true)
        }
        return isSafe
    }

    private func resetState() {
        state = State()
    }

    private func updateStateMarkIsFetchingNextPage() {
        state.isFetchingNextPage = true
    }
}

extension PaginatedListDataSource {
    struct State: Equatable, Copying {
        var items: [Item] = []
        var isFetchingFirstPage = true
        var isFetchingNextPage: Bool = true
        var isLastPage: Bool = false

        var viewState: PaginatedListViewState {
            if isFetchingFirstPage {
                return .fetchingInitialPage
            } else if items.isEmpty {
                if isLastPage {
                    return .data(.noItems)
                } else {
                    // This is to prevent glitching the `.data(.noItems)` state if the first PaginatedListUpdate
                    // is `.none` but more updates are coming.
                    return .fetchingInitialPage
                }
            } else {
                return .data(.items(isFetchingNextPage: isFetchingNextPage))
            }
        }
    }
}

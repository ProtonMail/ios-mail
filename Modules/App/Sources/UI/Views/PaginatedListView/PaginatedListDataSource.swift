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

struct PaginatedListProvider<Item: Equatable & Sendable> {
    let updatePublisher: AnyPublisher<PaginatedListUpdate<Item>, Never>
    let fetchMore: (_ currentPage: Int) -> Void
}

@MainActor
final class PaginatedListDataSource<Item: Equatable & Sendable>: ObservableObject, @unchecked Sendable {
    @Published private(set) var state: State
    private let provider: PaginatedListProvider<Item>
    private let idKey: ((Item) -> String)?
    private var cancellables = Set<AnyCancellable>()

    init(paginatedListProvider: PaginatedListProvider<Item>, idKey: ((Item) -> String)? = nil) {
        self.state = .init()
        self.provider = paginatedListProvider
        self.idKey = idKey
        provider.updatePublisher.receive(on: DispatchQueue.main).sink { [weak self] update in
            self?.handle(update: update)
        }.store(in: &cancellables)
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

    /// Optimistically removes items with matching IDs from local state so the row collapse animates smoothly.
    /// Requires `idKey`; this is a UI-only change (no network/provider call).
    ///
    /// - Parameter keys: String IDs produced using the same `idKey`.
    /// - Complexity: O(n) over `state.items`.
    func removeLocally(keys: some Sequence<String>) {
        guard let idKey else { return }
        let keySet = Set(keys)
        state.items.removeAll { item in keySet.contains(idKey(item)) }
    }

    private func fetchNextPageItems() {
        updateStateMarkIsFetchingNextPage()
        provider.fetchMore(state.currentPage)
    }

    // MARK: Modifiers

    private func handle(update: PaginatedListUpdate<Item>) {
        var newState = state
        newState.isFetchingNextPage = false
        newState.isLastPage = update.isLastPage

        switch update.value {
        case .append(let items):
            newState.items.append(contentsOf: items)
            newState.currentPage += 1
        case let .replaceFrom(index, items):
            guard isSafeIndex(index) else { break }
            newState.items.replaceSubrange(index..<newState.items.endIndex, with: items)
        case let .replaceBefore(index, items):
            guard isSafeIndex(index) else { break }
            newState.items.replaceSubrange(newState.items.startIndex..<index, with: items)
        case .none, .error:
            break
        }

        state = newState
        AppLogger.log(message: "handle update: \(update), total items = \(state.items.count)", category: .mailbox)
        update.completion?()
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

    struct State: Equatable {
        var items: [Item] = []
        var currentPage: Int = 0
        var isFetchingNextPage: Bool = true
        var isLastPage: Bool = false

        var viewState: PaginatedListViewState {
            let isFetchingFirstPage = isFetchingNextPage && currentPage == 0

            guard !isFetchingFirstPage else {
                return .fetchingInitialPage
            }

            return .data(items.isEmpty ? .placeholder : .items(isLastPage: isLastPage))
        }
    }
}

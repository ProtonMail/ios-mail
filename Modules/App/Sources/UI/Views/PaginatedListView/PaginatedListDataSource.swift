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

import SwiftUI

final class PaginatedListDataSource<Item: Equatable & Sendable>: ObservableObject, @unchecked Sendable {
    typealias FetchPage = (_ currentPage: Int, _ pageSize: Int) async -> NextPageResult

    @Published private(set) var state: State
    private let pageSize: Int
    private let fetchPage: FetchPage

    init(pageSize: Int = 50, fetchPage: @escaping FetchPage) {
        self.state = .init()
        self.pageSize = pageSize
        self.fetchPage = fetchPage
    }

    /// This function is for convenience to be able to show the initial state if the operation to have the fetchPage ready
    /// takes some time and we are not ready to call `fetchInitialPage`.
    func resetToInitialState() async {
        await resetState()
    }

    /// Resets the data and state and launches a new request to fetch the first page
    func fetchInitialPage() async {
        await resetState()
        await fetchNextPageItems()
    }

    func fetchNextPageIfNeeded() async {
        guard !state.isFetchingNextPage && !state.isLastPage else { return }
        await fetchNextPageItems()
    }

    /// Use this function to refresh the items' values by overwriting the existing item list.
    /// - Parameter updatedItems: new list of items. The list can't be empty
    @MainActor
    func updateItems(_ updatedItems: [Item]) async {
        state.items = updatedItems
    }

    private func fetchNextPageItems() async {
        await updateStateMarkIsFetchingNextPage()
        let result = await fetchPage(state.currentPage, pageSize)

        do {
            try Task.checkCancellation()
            await updateState(with: result)
        } catch {
            ()
        }
    }

    // MARK: Modifiers

    @MainActor
    private func resetState() {
        state = State()
    }

    @MainActor
    private func updateStateMarkIsFetchingNextPage() {
        state.isFetchingNextPage = true
    }

    @MainActor
    private func updateState(with result: NextPageResult) {
        var newState = state
        newState.isFetchingNextPage = false
        newState.items.append(contentsOf: result.newItems)
        newState.currentPage += 1
        newState.isLastPage = result.isLastPage
        state = newState
    }
}

extension PaginatedListDataSource {

    struct State {
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

extension PaginatedListDataSource {

    struct NextPageResult {
        let newItems: [Item]
        let isLastPage: Bool
    }
}

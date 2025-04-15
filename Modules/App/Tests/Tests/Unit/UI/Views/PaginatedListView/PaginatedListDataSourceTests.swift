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
@testable import ProtonMail
import XCTest

final class PaginatedListDataSourceTests: XCTestCase {
    private var sut: PaginatedListDataSource<String>!
    private let dummyItemsForEachPage = ["Item 1", "Item 2"]
    private var pageResult: PaginatedListDataSource<String>.NextPageResult!
    private var fetchPage: PaginatedListDataSource<String>.FetchPage!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        pageResult = PaginatedListDataSource<String>.NextPageResult(newItems: dummyItemsForEachPage, isLastPage: false)
        fetchPage = createMockFetchPage(result: pageResult)
        sut = PaginatedListDataSource(fetchPage: fetchPage)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        pageResult = nil
        fetchPage = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: init

    func testInit_whenDefaultStateIsPassed_viewStateIsFetchingInitialPage() async {
        XCTAssertEqual(sut.state.viewState, .fetchingInitialPage)
    }

    // MARK: fetchInitialPage

    func testFetchInitialPage_whenThereIsNoItem_stateBecomesDataWithPlaceholder() async {
        let pageResult = PaginatedListDataSource<String>.NextPageResult(newItems: [], isLastPage: false)
        let fetchPage = createMockFetchPage(result: pageResult)
        sut = PaginatedListDataSource(fetchPage: fetchPage)

        var capturedStates: [PaginatedListViewState] = []
        sut.$state.map(\.viewState).removeDuplicates().sink { viewState in
            capturedStates.append(viewState)
        }
        .store(in: &cancellables)

        await sut.fetchInitialPage()

        XCTAssertEqual(sut.state.items, pageResult.newItems)
        XCTAssertEqual(capturedStates, [.fetchingInitialPage, .data(.placeholder)])
    }

    func testFetchInitialPage_whenThereIsAtLeastOneItem_stateBecomesDataWithItems() async {
        var capturedStates: [PaginatedListViewState] = []
        sut.$state.map(\.viewState).removeDuplicates().sink { viewState in
            capturedStates.append(viewState)
        }
        .store(in: &cancellables)

        await sut.fetchInitialPage()

        XCTAssertEqual(sut.state.items, pageResult.newItems)
        XCTAssertEqual(capturedStates, [.fetchingInitialPage, .data(.items(isLastPage: false))])
    }

    func testFetchInitialPage_whenPageIsLast_stateShouldBecomeDataAndIsLastPage() async {
        pageResult = PaginatedListDataSource<String>.NextPageResult(newItems: dummyItemsForEachPage, isLastPage: true)
        fetchPage = createMockFetchPage(result: pageResult)

        sut = PaginatedListDataSource(pageSize: 4, fetchPage: fetchPage)

        var capturedStates: [PaginatedListViewState] = []
        sut.$state.map(\.viewState).removeDuplicates().sink { viewState in
            capturedStates.append(viewState)
        }
        .store(in: &cancellables)

        await sut.fetchInitialPage()

        XCTAssertEqual(sut.state.items, pageResult.newItems)
        XCTAssertEqual(capturedStates, [.fetchingInitialPage, .data(.items(isLastPage: true))])
    }

    func testFetchInitialPage_whenStateIsData_stateShouldGoThorughFetchingInitialStateAgain() async {
        var capturedStates: [PaginatedListViewState] = []
        sut.$state.map(\.viewState).removeDuplicates().sink { viewState in
            capturedStates.append(viewState)
        }
        .store(in: &cancellables)

        await sut.fetchInitialPage()
        await sut.fetchNextPageIfNeeded()
        XCTAssertEqual(sut.state.items, ["Item 1", "Item 2", "Item 1", "Item 2"])
        XCTAssertEqual(capturedStates, [.fetchingInitialPage, .data(.items(isLastPage: false))])

        await sut.fetchInitialPage()
        XCTAssertEqual(sut.state.items, ["Item 1", "Item 2"])
        XCTAssertEqual(capturedStates, [
            .fetchingInitialPage,
            .data(.items(isLastPage: false)),
            .fetchingInitialPage,
            .data(.items(isLastPage: false))
        ])
    }

    // MARK: fetchNextPage

    func testFetchNextPageIfNeeded_whenMoreThanOnePageAvailable_stateShouldBecomeDataWithItems() async {
        var capturedStates: [PaginatedListViewState] = []
        sut.$state.map(\.viewState).removeDuplicates().sink { viewState in
            capturedStates.append(viewState)
        }
        .store(in: &cancellables)

        await sut.fetchInitialPage()
        await sut.fetchNextPageIfNeeded()

        XCTAssertEqual(sut.state.items, ["Item 1", "Item 2", "Item 1", "Item 2"])
        XCTAssertEqual(capturedStates, [.fetchingInitialPage, .data(.items(isLastPage: false))])
    }

    func testFetchNextPageIfNeeded_whenAllPagesFetched_stateShouldBecomeDataWithIsLastPage() async {
        sut = PaginatedListDataSource(fetchPage: { currentPage, pageSize in
            if currentPage == 0 {
                return .init(newItems: ["Item 1", "Item 2"], isLastPage: false)
            } else if currentPage == 1 {
                return .init(newItems: ["Item 3", "Item 4"], isLastPage: false)
            } else if currentPage == 2 {
                return .init(newItems: ["Item 5", "Item 6"], isLastPage: true)
            }
            XCTFail("unexpected call")
            return .init(newItems: [], isLastPage: Bool.random())
        })

        var capturedStates: [PaginatedListViewState] = []
        sut.$state.map(\.viewState).removeDuplicates().sink { viewState in
            capturedStates.append(viewState)
        }
        .store(in: &cancellables)

        await sut.fetchInitialPage()
        await sut.fetchNextPageIfNeeded()
        await sut.fetchNextPageIfNeeded()

        XCTAssertEqual(sut.state.items, ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6"])
        XCTAssertEqual(capturedStates, [
            .fetchingInitialPage,
            .data(.items(isLastPage: false)),
            .data(.items(isLastPage: true))
        ])
    }

    // MARK: updateItems

    func testUpdateItems_itShouldOverwriteExistingItems() async {
        sut = PaginatedListDataSource(pageSize: 2, fetchPage: fetchPage)
        await sut.fetchInitialPage()
        XCTAssertEqual(sut.state.items, ["Item 1", "Item 2"])

        let updatedItems = ["New Item 1", "New Item 2"]
        await sut.updateItems(updatedItems)

        XCTAssertEqual(sut.state.items, updatedItems)
    }
}

extension PaginatedListDataSourceTests {

    private func createMockFetchPage(result: PaginatedListDataSource<String>.NextPageResult) -> PaginatedListDataSource<String>.FetchPage {
        return { _, _ in
            return result
        }
    }
}

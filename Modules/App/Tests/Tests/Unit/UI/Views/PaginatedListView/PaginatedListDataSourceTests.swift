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
import XCTest
import proton_app_uniffi

@testable import ProtonMail

@MainActor
final class PaginatedListDataSourceTests: XCTestCase {
    private var sut: PaginatedListDataSource<String>!
    private let dummyItemsForEachPage = ["Item 1", "Item 2"]
    private var cancellables: Set<AnyCancellable> = .init()
    private var fetchMoreCallCounter: Int = 0

    @MainActor
    override func setUp() {
        sut = PaginatedListDataSource(fetchMore: { [unowned self] currentPage in
            self.fetchMoreCallCounter += 1
        })
    }

    // MARK: init

    func testInit_whenDefaultStateIsPassed_viewStateIsFetchingInitialPage() async {
        XCTAssertTrue(sut.state.viewState == .fetchingInitialPage)
    }

    // MARK: fetchInitialPage

    func testFetchInitialPage_itCallsFetchMore() async {
        sut.fetchInitialPage()
        XCTAssertEqual(fetchMoreCallCounter, 1)
    }

    func testFetchInitialPage_whenStateIsData_stateShouldGoToInitialStateAgain() async {
        sut.fetchInitialPage()
        sut.handle(update: .init(isLastPage: false, value: .append(items: dummyItemsForEachPage)))
        XCTAssertEqual(sut.state.viewState, .data(.items(isFetchingNextPage: false)))

        sut.fetchInitialPage()
        XCTAssertEqual(sut.state.viewState, .fetchingInitialPage)
    }

    // MARK: fetchNextPageIfNeeded

    func testFetchNextPageIfNeeded_whenNotLastPage_itCallsFetchMore() async {
        sut.fetchInitialPage()
        sut.handle(update: .init(isLastPage: false, value: .append(items: dummyItemsForEachPage)))
        XCTAssertEqual(fetchMoreCallCounter, 1)

        sut.fetchNextPageIfNeeded()
        XCTAssertEqual(fetchMoreCallCounter, 2)
    }

    func testFetchNextPageIfNeeded_whenLastPage_itDoesNotCallFetchMore() async {
        sut.fetchInitialPage()
        sut.handle(update: .init(isLastPage: true, value: .append(items: dummyItemsForEachPage)))
        XCTAssertEqual(fetchMoreCallCounter, 1)

        sut.fetchNextPageIfNeeded()
        XCTAssertEqual(fetchMoreCallCounter, 1)
    }

    // MARK: sut.handle(update:)

    func testHandleUpdate_none_whenIsFirstUpdate_andNotLastPage_stateIsFetchingInitialPage() async {
        sut.fetchInitialPage()
        sut.handle(update: .init(isLastPage: false, value: .none))

        XCTAssertEqual(sut.state.isFetchingNextPage, false)
        XCTAssertEqual(sut.state.viewState, .fetchingInitialPage)
    }

    func testHandleUpdate_none_whenIsFirstUpdate_andLastPage_stateBecomesNoItems() async {
        sut.fetchInitialPage()
        XCTAssertEqual(sut.state.viewState, .fetchingInitialPage)
        sut.handle(update: .init(isLastPage: true, value: .none))

        XCTAssertEqual(sut.state.isFetchingNextPage, false)
        XCTAssertEqual(sut.state.viewState, .data(.noItems))
    }

    func testHandleUpdate_append_whenNoItems_andNotLastPage_stateIsFetchingInitialPage() async {
        sut.fetchInitialPage()
        sut.handle(update: .init(isLastPage: false, value: .append(items: [])))

        XCTAssertEqual(sut.state.items, [])
        XCTAssertEqual(sut.state.viewState, .fetchingInitialPage)
    }

    func testHandleUpdate_append_whenNoItems_andLastPage_stateBecomesNoItems() async {
        sut.fetchInitialPage()
        XCTAssertEqual(sut.state.viewState, .fetchingInitialPage)

        sut.handle(update: .init(isLastPage: true, value: .append(items: [])))
        XCTAssertEqual(sut.state.items, [])
        XCTAssertEqual(sut.state.viewState, .data(.noItems))
    }

    func testHandleUpdate_append_whenItems_stateBecomesDataWithItems() async {
        sut.fetchInitialPage()
        XCTAssertEqual(sut.state.viewState, .fetchingInitialPage)

        sut.handle(update: .init(isLastPage: false, value: .append(items: dummyItemsForEachPage)))
        XCTAssertEqual(sut.state.items, dummyItemsForEachPage)
        XCTAssertEqual(sut.state.viewState, .data(.items(isFetchingNextPage: false)))
    }

    func testHandleUpdate_append_whenItems_andLastPage_stateBecomesDataAndIsLastPage() async {
        sut.fetchInitialPage()
        XCTAssertEqual(sut.state.viewState, .fetchingInitialPage)

        sut.handle(update: .init(isLastPage: true, value: .append(items: dummyItemsForEachPage)))
        XCTAssertEqual(sut.state.viewState, .data(.items(isFetchingNextPage: false)))
        XCTAssertEqual(sut.state.items, dummyItemsForEachPage)
        XCTAssertTrue(sut.state.isLastPage)
    }

    func testHandleUpdate_replaceRange_whenAddingItems() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: ["1", "2", "3", "4"])))

        sut.handle(update: .init(isLastPage: true, value: .replaceRange(from: 1, to: 3, items: ["A", "B", "C"])))
        XCTAssertEqual(sut.state.items, ["1", "A", "B", "C", "4"])
    }

    func testHandleUpdate_replaceRange_whenAddingItemsUsingTheSameIndex_itInsertsNewElements() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: ["1", "2", "3", "4"])))

        sut.handle(update: .init(isLastPage: true, value: .replaceRange(from: 1, to: 1, items: ["A", "B"])))
        XCTAssertEqual(sut.state.items, ["1", "A", "B", "2", "3", "4"])
    }

    func testHandleUpdate_replaceRange_whenRemovingItems() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: ["1", "2", "3", "4"])))

        sut.handle(update: .init(isLastPage: true, value: .replaceRange(from: 1, to: 3, items: [])))
        XCTAssertEqual(sut.state.items, ["1", "4"])
    }

    func testHandleUpdate_replaceRange_whenRemovingAllItems() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: ["1", "2", "3"])))

        sut.handle(update: .init(isLastPage: true, value: .replaceRange(from: 0, to: 3, items: [])))
        XCTAssertEqual(sut.state.items, [])
    }

    func testHandleUpdate_replaceRange_whenInvalidIndices_itDoesNotCrash() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: [])))
        sut.handle(update: .init(isLastPage: false, value: .replaceRange(from: 1, to: 1, items: ["1"])))
        sut.handle(update: .init(isLastPage: false, value: .replaceRange(from: -1, to: 0, items: ["1"])))
        sut.handle(update: .init(isLastPage: true, value: .replaceRange(from: 0, to: -1, items: ["1"])))

        XCTAssertEqual(sut.state.items, [])
    }

    func testHandleUpdate_replaceFrom_whenAddingItems() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: ["1", "2"])))

        sut.handle(update: .init(isLastPage: true, value: .replaceFrom(index: 1, items: ["3", "4"])))
        XCTAssertEqual(sut.state.items, ["1", "3", "4"])
    }

    func testHandleUpdate_replaceFrom_whenRemovingItems() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: ["1", "2"])))

        sut.handle(update: .init(isLastPage: true, value: .replaceFrom(index: 1, items: [])))
        XCTAssertEqual(sut.state.items, ["1"])
    }

    func testHandleUpdate_replaceFrom_whenRemovingAllItems() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: ["1", "2"])))

        sut.handle(update: .init(isLastPage: true, value: .replaceFrom(index: 0, items: [])))
        XCTAssertEqual(sut.state.items, [])
    }

    func testHandleUpdate_replaceFrom_whenInvalidIndex_itDoesNotCrash() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: [])))

        sut.handle(update: .init(isLastPage: false, value: .replaceFrom(index: 1, items: ["1"])))
        sut.handle(update: .init(isLastPage: true, value: .replaceFrom(index: -1, items: ["1"])))
        XCTAssertEqual(sut.state.items, [])
    }

    func testHandleUpdate_replaceBefore_whenAddingItems() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: ["1", "2"])))

        sut.handle(update: .init(isLastPage: true, value: .replaceBefore(index: 1, items: ["3", "4"])))
        XCTAssertEqual(sut.state.items, ["3", "4", "2"])
    }

    func testHandleUpdate_replaceBefore_whenRemovingItems() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: ["1", "2"])))

        sut.handle(update: .init(isLastPage: true, value: .replaceBefore(index: 1, items: [])))
        XCTAssertEqual(sut.state.items, ["2"])
    }

    func testHandleUpdate_replaceBefore_whenRemovingAllItems() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: ["1", "2"])))

        sut.handle(update: .init(isLastPage: true, value: .replaceBefore(index: 2, items: [])))
        XCTAssertEqual(sut.state.items, [])
    }

    func testHandleUpdate_replaceBefore_whenInvalidIndex_itDoesNotCrash() async {
        sut.handle(update: .init(isLastPage: false, value: .append(items: [])))

        sut.handle(update: .init(isLastPage: false, value: .replaceBefore(index: 1, items: ["1"])))
        sut.handle(update: .init(isLastPage: true, value: .replaceBefore(index: -1, items: ["1"])))
        XCTAssertEqual(sut.state.items, [])
    }

    func testHandleUpdate_error_itUpdateStateToNotFetchingNextPage() async {
        sut.fetchInitialPage()

        sut.handle(update: .init(isLastPage: true, value: .error(MailScrollerError.other(.network))))
        XCTAssertEqual(sut.state.isFetchingNextPage, false)
    }

    func testHandleUpdate_whenIsFetchingNextPage_anyUpdate_setsIsFetchingToFalse() async {
        sut.fetchInitialPage()
        sut.fetchNextPageIfNeeded()
        XCTAssertTrue(sut.state.isFetchingNextPage)

        let updateList: [PaginatedListUpdateType] = [
            .none,
            .append(items: dummyItemsForEachPage),
            .replaceBefore(index: 0, items: dummyItemsForEachPage),
            .replaceFrom(index: 0, items: dummyItemsForEachPage),
            .replaceRange(from: 0, to: 0, items: dummyItemsForEachPage),
            .error(MailScrollerError.reason(.notSynced)),
        ]

        for update in updateList {
            sut.handle(update: .init(isLastPage: Bool.random(), value: update))
            XCTAssertFalse(sut.state.isFetchingNextPage, "For update: \(update)")
        }
    }
}

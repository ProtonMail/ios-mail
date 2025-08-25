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
import proton_app_uniffi
@testable import ProtonMail
import XCTest

@MainActor
final class PaginatedListDataSourceTests: XCTestCase {
    private var sut: PaginatedListDataSource<String>!
    private var provider: PaginatedListProvider<String>!
    private let dummyItemsForEachPage = ["Item 1", "Item 2"]
    private let updateSubject: PassthroughSubject<PaginatedListUpdate<String>, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    private var fetchMoreCallCounter: Int = 0

    @MainActor
    override func setUp() {
        provider = PaginatedListProvider(
            updatePublisher: updateSubject.eraseToAnyPublisher(),
            fetchMore: { [unowned self] currentPage in
                self.fetchMoreCallCounter += 1
            }
        )
        sut = PaginatedListDataSource(paginatedListProvider: provider)
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
        let capturedStates = await expectViewStateStates(count: 2) {
            sut.fetchInitialPage()
            updateSubject.send(.init(isLastPage: false, value: .append(items: dummyItemsForEachPage)))
        }
        XCTAssertEqual(capturedStates, [.fetchingInitialPage, .data(.items(isLastPage: false))])

        sut.fetchInitialPage()
        XCTAssertEqual(sut.state.viewState, .fetchingInitialPage)
    }

    // MARK: fetchNextPageIfNeeded

    func testFetchNextPageIfNeeded_whenNotLastPage_itCallsFetchMore() async {
        await expectViewStateStates(count: 2) {
            sut.fetchInitialPage()
            updateSubject.send(.init(isLastPage: false, value: .append(items: dummyItemsForEachPage)))
        }
        XCTAssertEqual(fetchMoreCallCounter, 1)
        sut.fetchNextPageIfNeeded()
        XCTAssertEqual(fetchMoreCallCounter, 2)
    }

    func testFetchNextPageIfNeeded_whenLastPage_itDoesNotCallFetchMore() async {
        await expectViewStateStates(count: 2) {
            sut.fetchInitialPage()
            updateSubject.send(.init(isLastPage: true, value: .append(items: dummyItemsForEachPage)))
        }
        XCTAssertEqual(fetchMoreCallCounter, 1)
        sut.fetchNextPageIfNeeded()
        XCTAssertEqual(fetchMoreCallCounter, 1)
    }

    // MARK: updatePublisher

    func testUpdatePublisher_none_whenIsFirstUpdate_andNotLastPage_stateIsFetchingInitialPage() async {
        let capturedStates = await expectViewStateStates(count: 1) {
            sut.fetchInitialPage()
            updateSubject.send(.init(isLastPage: false, value: .none))
        }

        XCTAssertEqual(sut.state.isFetchingNextPage, false)
        XCTAssertEqual(capturedStates, [.fetchingInitialPage])
    }

    func testUpdatePublisher_none_whenIsFirstUpdate_andLastPage_stateBecomesNoItems() async {
        let capturedStates = await expectViewStateStates(count: 2) {
            sut.fetchInitialPage()
            updateSubject.send(.init(isLastPage: true, value: .none))
        }

        XCTAssertEqual(sut.state.isFetchingNextPage, false)
        XCTAssertEqual(capturedStates, [.fetchingInitialPage, .data(.noItems)])
    }

    func testUpdatePublisher_append_whenNoItems_andNotLastPage_stateIsFetchingInitialPage() async {
        let capturedStates = await expectViewStateStates(count: 1) {
            sut.fetchInitialPage()
            updateSubject.send(.init(isLastPage: false, value: .append(items: [])))
        }

        XCTAssertEqual(sut.state.items, [])
        XCTAssertEqual(capturedStates, [.fetchingInitialPage])
    }

    func testUpdatePublisher_append_whenNoItems_andLastPage_stateBecomesNoItems() async {
        let capturedStates = await expectViewStateStates(count: 2) {
            sut.fetchInitialPage()
            updateSubject.send(.init(isLastPage: true, value: .append(items: [])))
        }

        XCTAssertEqual(sut.state.items, [])
        XCTAssertEqual(capturedStates, [.fetchingInitialPage, .data(.noItems)])
    }

    func testUpdatePublisher_append_whenItems_stateBecomesDataWithItems() async {
        let capturedStates = await expectViewStateStates(count: 2) {
            sut.fetchInitialPage()
            updateSubject.send(.init(isLastPage: false, value: .append(items: dummyItemsForEachPage)))
        }

        XCTAssertEqual(sut.state.items, dummyItemsForEachPage)
        XCTAssertEqual(capturedStates, [.fetchingInitialPage, .data(.items(isLastPage: false))])
    }

    func testUpdatePublisher_append_whenItems_andLastPage_stateBecomesDataAndIsLastPage() async {
        let capturedStates = await expectViewStateStates(count: 2) {
            sut.fetchInitialPage()
            updateSubject.send(.init(isLastPage: true, value: .append(items: dummyItemsForEachPage)))
        }

        XCTAssertEqual(sut.state.items, dummyItemsForEachPage)
        XCTAssertEqual(capturedStates, [.fetchingInitialPage, .data(.items(isLastPage: true))])
    }

    func testUpdatePublisher_replaceFrom_whenAddingItems() async {
        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: false, value: .append(items: ["1", "2"])))
            updateSubject.send(.init(isLastPage: true, value: .replaceFrom(index: 1, items: ["3", "4"])))
        }

        XCTAssertEqual(sut.state.items, ["1", "3", "4"])
    }

    func testUpdatePublisher_replaceFrom_whenRemovingItems() async {
        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: false, value: .append(items: ["1", "2"])))
            updateSubject.send(.init(isLastPage: true, value: .replaceFrom(index: 1, items: [])))
        }

        XCTAssertEqual(sut.state.items, ["1"])
    }

    func testUpdatePublisher_replaceFrom_whenRemovingAllItems() async {
        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: false, value: .append(items: ["1", "2"])))
            updateSubject.send(.init(isLastPage: true, value: .replaceFrom(index: 0, items: [])))
        }

        XCTAssertEqual(sut.state.items, [])
    }

    func testUpdatePublisher_replaceFrom_whenhInvalidIndex_itDoesNotCrash() async {
        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: false, value: .append(items: [])))
            updateSubject.send(.init(isLastPage: false, value: .replaceFrom(index: 1, items: ["1"])))
            updateSubject.send(.init(isLastPage: true, value: .replaceFrom(index: -1, items: ["1"])))
        }

        XCTAssertEqual(sut.state.items, [])
    }

    func testUpdatePublisher_replaceBefore_whenAddingItems() async {
        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: false, value: .append(items: ["1", "2"])))
            updateSubject.send(.init(isLastPage: true, value: .replaceBefore(index: 1, items: ["3", "4"])))
        }

        XCTAssertEqual(sut.state.items, ["3", "4", "2"])
    }

    func testUpdatePublisher_replaceBefore_whenRemovingItems() async {
        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: false, value: .append(items: ["1", "2"])))
            updateSubject.send(.init(isLastPage: true, value: .replaceBefore(index: 1, items: [])))
        }

        XCTAssertEqual(sut.state.items, ["2"])
    }

    func testUpdatePublisher_replaceBefore_whenRemovingAllItems() async {
        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: false, value: .append(items: ["1", "2"])))
            updateSubject.send(.init(isLastPage: true, value: .replaceBefore(index: 2, items: [])))
        }

        XCTAssertEqual(sut.state.items, [])
    }

    func testUpdatePublisher_replaceBefore_whenhInvalidIndex_itDoesNotCrash() async {
        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: false, value: .append(items: [])))
            updateSubject.send(.init(isLastPage: false, value: .replaceBefore(index: 1, items: ["1"])))
            updateSubject.send(.init(isLastPage: true, value: .replaceBefore(index: -1, items: ["1"])))
        }

        XCTAssertEqual(sut.state.items, [])
    }

    func testUpdatePublisher_error_itUpdateStateToNotFetchingNextPage() async {
        await expectViewStateStates(count: 2) {
            sut.fetchInitialPage()
            updateSubject.send(.init(isLastPage: true, value: .error(MailScrollerError.other(.network))))
        }

        XCTAssertEqual(sut.state.isFetchingNextPage, false)
    }

    // MARK: removeLocally

    func testRemoveItemsLocally_WhenIdKeyIsNil_ItDoesNothing() async {
        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: true, value: .append(items: ["1", "2", "3"])))
        }

        sut.removeItemsLocally(ids: [.init(value: 1)])

        XCTAssertEqual(sut.state.items, ["1", "2", "3"])
    }

    func testRemoveItemsLocally_WhenIdKeyProvided_ItRemovesMatchingSingleID() async {
        sut = PaginatedListDataSource(paginatedListProvider: provider, id: { ID(value: UInt64($0)!) })

        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: true, value: .append(items: ["1", "2", "3"])))
        }

        sut.removeItemsLocally(ids: [.init(value: 2)])

        XCTAssertEqual(sut.state.items, ["1", "3"])
    }

    func testRemoveItemsLocally_WhenIdKeyProvided_ItRemovesMultipleAndIgnoresUnknown() async {
        sut = PaginatedListDataSource(paginatedListProvider: provider, id: { ID(value: UInt64($0)!) })

        await expectIsLastPage {
            updateSubject.send(.init(isLastPage: true, value: .append(items: ["1", "2", "3", "4"])))
        }

        sut.removeItemsLocally(ids: [.init(value: 3), .init(value: 42)])

        XCTAssertEqual(sut.state.items, ["1", "2", "4"])
    }
}

private extension PaginatedListDataSourceTests {

    func expectIsLastPage(timeout: TimeInterval = 1.0, perform: () -> Void) async {
        let expectation = XCTestExpectation(description: "Wait for isLastPage")

        sut.$state
            .removeDuplicates()
            .sink { state in
                if state.isLastPage {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        perform()

        await fulfillment(of: [expectation], timeout: timeout)
    }

    @discardableResult
    func expectViewStateStates(
        count expectedCount: Int,
        timeout: TimeInterval = 1.0,
        perform: () -> Void
    ) async -> [PaginatedListViewState] {
        let expectation = XCTestExpectation(description: "Wait for \(expectedCount) state updates")
        var capturedStates: [PaginatedListViewState] = []

        sut.$state
            .map(\.viewState)
            .removeDuplicates()
            .sink { viewState in
                capturedStates.append(viewState)
                if capturedStates.count == expectedCount {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        perform()

        await fulfillment(of: [expectation], timeout: timeout)
        return capturedStates
    }
}

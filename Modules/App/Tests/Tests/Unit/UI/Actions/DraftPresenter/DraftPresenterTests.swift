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

@testable import ProtonMail
import Combine
import InboxTesting
import proton_app_uniffi
import XCTest

final class DraftPresenterTests: BaseTestCase {
    private var sut: DraftPresenter!
    private var stubbedResult: NewDraftResult!
    private let emptyErrorCallback: (DraftError) -> Void = { _ in }
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        sut = .init(
            userSession: .dummy,
            draftProvider: .init(makeDraft: { [unowned self] session, createMode in stubbedResult })
        )
        cancellables = .init()
    }

    override func tearDown() {
        sut = nil
        stubbedResult = nil
        cancellables = nil

        super.tearDown()
    }

    // MARK: openDraft

    @MainActor
    func testOpenDraft_itShouldPublishADraftToPresent() {
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let dummyMessageId: ID = .random()
        sut.openDraft(withId: dummyMessageId)
        XCTAssertEqual(capturedDraftToPresent.count, 1)

        switch capturedDraftToPresent.first! {
        case .new: 
            XCTFail("unexpected draft to present")
        case .openDraftId(let messageId):
            XCTAssertEqual(messageId, dummyMessageId)
        }
    }

    // MARK: openNewDraft

    @MainActor
    func testOpenNewDraft_whenDraftIsCreated_itShouldPublishADraftToPresent() async {
        stubbedResult = .ok(.dummyDraft)
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        await sut.openNewDraft(onError: emptyErrorCallback)
        XCTAssertEqual(capturedDraftToPresent.count, 1)
    }

    @MainActor
    func testOpenNewDraft_whenDraftFailsToCreate_itShouldNotPublishAnything() async {
        stubbedResult = .error(.other(.sessionExpired))
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        await sut.openNewDraft(onError: { error in
            XCTAssertEqual(error, .other(.sessionExpired))
        })
        XCTAssertEqual(capturedDraftToPresent.count, 0)
    }

    // MARK: handleReplyAction

    @MainActor
    func testHandleReplyAction_whenDraftForMessageReplyIsCreated_itShouldPublishADraftToPresent() async {
        stubbedResult = .ok(.dummyDraft)
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let dummyMessageId: ID = .random()
        await sut.handleReplyAction(for: dummyMessageId, action: .reply, onError: emptyErrorCallback)
        XCTAssertEqual(capturedDraftToPresent.count, 1)
    }

    @MainActor
    func testHandleReplyAction_whenDraftFailsToCreate_itShouldNotPublishAnything() async {
        stubbedResult = .error(.other(.network))
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let dummyMessageId: ID = .random()
        await sut.handleReplyAction(for: dummyMessageId, action: .reply, onError: { error in
            XCTAssertEqual(error, .other(.network))
        })
        XCTAssertEqual(capturedDraftToPresent.count, 0)
    }
}

private extension Draft {

    static var dummyDraft: Draft { .init(noPointer: .init()) }
}

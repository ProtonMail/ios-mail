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
import InboxContacts
import InboxTesting
import proton_app_uniffi
import XCTest

final class DraftPresenterTests: BaseTestCase, @unchecked Sendable {
    private var sut: DraftPresenter!
    private let emptyErrorCallback: (DraftOpenError) -> Void = { _ in }
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        MainActor.assumeIsolated {
            sut = makeSUT()
        }
        cancellables = .init()
    }

    override func tearDown() {
        sut = nil
        cancellables = nil

        super.tearDown()
    }

    // MARK: openDraft

    @MainActor
    func testOpenDraft_itShouldPublishADraftToPresent() async {
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let dummyMessageId: ID = .random()
        sut.openDraft(withId: dummyMessageId)

        XCTAssertEqual(capturedDraftToPresent.count, 1)
        XCTAssertEqual(capturedDraftToPresent.first, .openDraftId(messageId: dummyMessageId, lastScheduledTime: .none))
    }

    // MARK: openNewDraft

    @MainActor
    func testOpenNewDraft_whenDraftIsCreated_itShouldPublishADraftToPresent() async {
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        await sut.openNewDraft(onError: emptyErrorCallback)
        XCTAssertEqual(capturedDraftToPresent.count, 1)
    }

    @MainActor
    func testOpenNewDraft_whenDraftFailsToCreate_itShouldNotPublishAnything() async {
        sut = makeSUT(stubbedNewDraftResult: .error(.other(.network)))
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        await sut.openNewDraft(onError: { error in
            XCTAssertEqual(error, .other(.network))
        })
        XCTAssertEqual(capturedDraftToPresent.count, 0)
    }

    // MARK: - Open new draft with contact

    @MainActor
    func testOpenDraftWithContact_ItCreatesEmptyDraftAddRecipientAndOpensDraft() async throws {
        let draftSpy = DraftSpy(noPointer: .init())
        sut = makeSUT(stubbedNewDraftResult: .ok(draftSpy))

        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let contact = ContactDetailsEmail(name: "John", email: "john.maxon@pm.me")

        try await sut.openDraft(with: contact)

        XCTAssertEqual(
            draftSpy.toRecipientsCalls.addSingleRecipientCalls,
            [
                .init(name: "John", email: "john.maxon@pm.me")
            ]
        )
        XCTAssertEqual(capturedDraftToPresent.count, 1)
        XCTAssertEqual(capturedDraftToPresent.first, .new(draft: draftSpy))
    }

    // MARK: handleReplyAction

    @MainActor
    func testHandleReplyAction_whenDraftForMessageReplyIsCreated_itShouldPublishADraftToPresent() async {
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let dummyMessageId: ID = .random()
        await sut.handleReplyAction(for: dummyMessageId, action: .reply, onError: emptyErrorCallback)
        XCTAssertEqual(capturedDraftToPresent.count, 1)
    }

    @MainActor
    func testHandleReplyAction_whenDraftFailsToCreate_itShouldNotPublishAnything() async {
        sut = makeSUT(stubbedNewDraftResult: .error(.other(.network)))
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let dummyMessageId: ID = .random()
        await sut.handleReplyAction(
            for: dummyMessageId, action: .reply,
            onError: { error in
                XCTAssertEqual(error, .other(.network))
            })
        XCTAssertEqual(capturedDraftToPresent.count, 0)
    }

    // MARK: undoSentMessageAndOpenDraft

    @MainActor
    func testUndoSentMessageAndOpenDraft_whenDraftForMessageReplyIsCreated_itShouldPublishADraftToPresent() async throws {
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let dummyMessageId: ID = .random()
        try await sut.undoSentMessageAndOpenDraft(for: dummyMessageId)
        XCTAssertEqual(capturedDraftToPresent.count, 1)
    }

    @MainActor
    func testUndoSentMessageAndOpenDraft_whenUndoFails_itShouldThrowAndNotPublishAnything() async {
        sut = makeSUT(stubbedUndoSendError: .reason(.messageCanNotBeUndoSent))

        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        do {
            try await sut.undoSentMessageAndOpenDraft(for: .random())
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error, .reason(.messageCanNotBeUndoSent))
        }
        XCTAssertEqual(capturedDraftToPresent.count, 0)
    }

    // MARK: cancelScheduledMessageAndOpenDraft

    @MainActor
    func testcancelScheduledMessageAndOpenDraft_whenDraftForMessageReplyIsCreated_itShouldPublishADraftToPresent() async throws {
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let dummyMessageId: ID = .random()
        try await sut.cancelScheduledMessageAndOpenDraft(for: dummyMessageId)
        XCTAssertEqual(capturedDraftToPresent.count, 1)
    }

    @MainActor
    func testcancelScheduledMessageAndOpenDraft_whenUndoScheduleFails_itShouldThrowAndNotPublishAnything() async {
        sut = makeSUT(stubbedCancelScheduleResult: .error(.reason(.messageNotScheduled)))

        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        do {
            try await sut.cancelScheduledMessageAndOpenDraft(for: .random())
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error, .reason(.messageNotScheduled))
        }
        XCTAssertEqual(capturedDraftToPresent.count, 0)
    }

    @MainActor
    func testOpenDraftWithContactGroup_ItCreatesEmptyDraftAddGroupAndOpensDraft() async throws {
        let draftSpy = DraftSpy(noPointer: .init())
        sut = makeSUT(stubbedNewDraftResult: .ok(draftSpy))

        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let group = ContactGroupItem(
            id: 2,
            name: "Business Group",
            avatarColor: "#A1FF33",
            contactEmails: [
                .init(id: 1, email: "a@pm.me", name: "A"),
                .init(id: 2, email: "b@pm.me", name: "B"),
                .init(id: 3, email: "c@pm.me", name: "C"),
                .init(id: 4, email: "d@pm.me", name: "D"),
            ]
        )

        try await sut.openDraft(with: group)

        XCTAssertEqual(
            draftSpy.toRecipientsCalls.addGroupRecipientCalls,
            [
                .init(
                    name: "Business Group",
                    recipients: [
                        .init(name: "A", email: "a@pm.me"),
                        .init(name: "B", email: "b@pm.me"),
                        .init(name: "C", email: "c@pm.me"),
                        .init(name: "D", email: "d@pm.me"),
                    ],
                    totalCount: 4
                )
            ]
        )

        let messageID = try XCTUnwrap(try draftSpy.stubbedMessageID.get())

        XCTAssertEqual(capturedDraftToPresent.count, 1)
        XCTAssertEqual(capturedDraftToPresent.first, .new(draft: draftSpy))
    }
}

extension DraftPresenterTests {

    @MainActor
    func makeSUT(
        stubbedNewDraftResult: NewDraftResult = .ok(.dummyDraft),
        stubbedUndoSendError: DraftUndoSendError? = nil,
        stubbedCancelScheduleResult: DraftCancelScheduleSendResult = .ok(.init(lastScheduledTime: 1747728129))
    ) -> DraftPresenter {
        DraftPresenter(
            userSession: .dummy,
            draftProvider: .init(makeDraft: { session, createMode in stubbedNewDraftResult }),
            undoSendProvider: .mockInstance(stubbedResult: stubbedUndoSendError),
            undoScheduleSendProvider: .mockInstance(stubbedResult: stubbedCancelScheduleResult)
        )
    }
}

private extension Draft {
    static var dummyDraft: Draft { .init(noPointer: .init()) }
}

private class DraftSpy: Draft, @unchecked Sendable {
    var stubbedMessageID: DraftMessageIdResult = .ok(.init(value: 9_091))
    var toRecipientsCalls: ComposerRecipientListSpy = .init(noPointer: .init())

    // MARK: - Draft

    override func messageId() async -> DraftMessageIdResult {
        stubbedMessageID
    }

    override func toRecipients() -> ComposerRecipientList {
        toRecipientsCalls
    }
}

private class ComposerRecipientListSpy: ComposerRecipientList, @unchecked Sendable {
    struct Group: Equatable {
        let name: String
        let recipients: [SingleRecipientEntry]
        let totalCount: UInt64
    }

    private(set) var addSingleRecipientCalls: [SingleRecipientEntry] = []
    private(set) var addGroupRecipientCalls: [Group] = []

    // MARK: - ComposerRecipientList

    override func addSingleRecipient(recipient: SingleRecipientEntry) -> AddSingleRecipientError {
        addSingleRecipientCalls.append(recipient)

        return .ok
    }

    override func addGroupRecipient(
        groupName: String,
        recipients: [SingleRecipientEntry],
        totalContactsInGroup: UInt64
    ) -> AddGroupRecipientError {
        addGroupRecipientCalls.append(.init(name: groupName, recipients: recipients, totalCount: totalContactsInGroup))

        return .ok
    }
}

extension DraftToPresent: @retroactive Equatable {

    public static func == (lhs: ProtonMail.DraftToPresent, rhs: ProtonMail.DraftToPresent) -> Bool {
        switch (lhs, rhs) {
        case (.new(let leftDraft), .new(let rightDraft)):
            return leftDraft === rightDraft
        case (.openDraftId(let leftID, let leftTime), .openDraftId(let rightID, let rightTime)):
            return leftID == rightID && leftTime == rightTime
        case (.new, .openDraftId), (.openDraftId, .new):
            return false
        }
    }

}

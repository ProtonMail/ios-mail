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

import Combine
import InboxContacts
import InboxTesting
import XCTest
import proton_app_uniffi

@testable import ProtonMail

final class DraftPresenterTests: BaseTestCase, @unchecked Sendable {
    private var sut: DraftPresenter!
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
    func testOpenNewDraft_whenDraftIsCreated_itShouldPublishADraftToPresent() async throws {
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        try await sut.openNewDraft()
        XCTAssertEqual(capturedDraftToPresent.count, 1)
    }

    @MainActor
    func testOpenNewDraft_whenDraftFailsToCreate_itShouldNotPublishAnything() async {
        sut = makeSUT(stubbedNewDraftResult: .error(.other(.network)))
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        do {
            try await sut.openNewDraft()
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error as? DraftOpenError, .other(.network))
        }
        XCTAssertEqual(capturedDraftToPresent.count, 0)
    }

    // MARK: - Open new draft with contact

    @MainActor
    func testOpenDraftWithContact_ItCreatesEmptyDraftAddRecipientAndOpensDraft() async throws {
        let draftSpy = DraftSpy(noPointer: .init())
        sut = makeSUT(stubbedNewDraftResult: .ok(draftSpy))

        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let recipient = SingleRecipientEntry(name: "John Maxon", email: "john.maxon@pm.me")

        try await sut.openDraft(with: recipient)

        XCTAssertEqual(draftSpy.toRecipientsCalls.addSingleRecipientCalls, [recipient])
        XCTAssertEqual(capturedDraftToPresent.count, 1)
        XCTAssertEqual(capturedDraftToPresent.first, .new(draft: draftSpy))
    }

    @MainActor
    func testOpenDraftWithContact_AndCreatingDraftFails_ItThrowsAnError() async {
        sut = makeSUT(stubbedNewDraftResult: .error(.reason(.messageIsNotADraft)))

        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let recipient = SingleRecipientEntry(name: "John Maxon", email: "john.maxon@pm.me")

        do {
            try await sut.openDraft(with: recipient)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error, .reason(.messageIsNotADraft))
        }
        XCTAssertEqual(capturedDraftToPresent.count, 0)
    }

    // MARK: - Open new draft with contact group

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
        XCTAssertEqual(capturedDraftToPresent.count, 1)
        XCTAssertEqual(capturedDraftToPresent.first, .new(draft: draftSpy))
    }

    @MainActor
    func testOpenDraftWithContactGroup_AndCreatingDraftFails_ItThrowsAnError() async {
        sut = makeSUT(stubbedNewDraftResult: .error(.reason(.messageDoesNotExist)))

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

        do {
            try await sut.openDraft(with: group)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error, .reason(.messageDoesNotExist))
        }
        XCTAssertEqual(capturedDraftToPresent.count, 0)
    }

    // MARK: handleReplyAction

    @MainActor
    func testHandleReplyAction_whenDraftForMessageReplyIsCreated_itShouldPublishADraftToPresent() async throws {
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let dummyMessageId: ID = .random()
        try await sut.handleReplyAction(for: dummyMessageId, action: .reply)
        XCTAssertEqual(capturedDraftToPresent.count, 1)
    }

    @MainActor
    func testHandleReplyAction_whenDraftFailsToCreate_itShouldNotPublishAnything() async {
        sut = makeSUT(stubbedNewDraftResult: .error(.other(.network)))
        var capturedDraftToPresent: [DraftToPresent] = []
        sut.draftToPresent.sink { capturedDraftToPresent.append($0) }.store(in: &cancellables)

        let dummyMessageId: ID = .random()
        do {
            try await sut.handleReplyAction(for: dummyMessageId, action: .reply)
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(error, .other(.network))
        }
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
}

extension DraftPresenterTests {
    @MainActor
    func makeSUT(
        stubbedNewDraftResult: NewDraftResult = .ok(.dummyDraft),
        stubbedUndoSendError: DraftUndoSendError? = nil,
        stubbedCancelScheduleResult: DraftCancelScheduleSendResult = .ok(.init(lastScheduledTime: 1747728129))
    ) -> DraftPresenter {
        DraftPresenter(
            userSession: MailUserSessionSpy(id: ""),
            draftProvider: .init(makeDraft: { _, _ in stubbedNewDraftResult }),
            undoSendProvider: .mockInstance(stubbedResult: stubbedUndoSendError),
            undoScheduleSendProvider: .mockInstance(stubbedResult: stubbedCancelScheduleResult)
        )
    }
}

private extension Draft {
    static var dummyDraft: Draft { .init(noPointer: .init()) }
}

private class DraftSpy: Draft, @unchecked Sendable {
    let toRecipientsCalls: ComposerRecipientListSpy = .init(noPointer: .init())
    let ccRecipientsCalls: ComposerRecipientListSpy = .init(noPointer: .init())
    let bccRecipientsCalls: ComposerRecipientListSpy = .init(noPointer: .init())
    private(set) var setSubjectCalls: [String] = []
    private(set) var setBodyCalls: [String] = []

    // MARK: - Draft

    override func toRecipients() -> ComposerRecipientList {
        toRecipientsCalls
    }

    override func ccRecipients() -> ComposerRecipientList {
        ccRecipientsCalls
    }

    override func bccRecipients() -> ComposerRecipientList {
        bccRecipientsCalls
    }

    override func subject() -> String {
        setSubjectCalls.last ?? .empty
    }

    override func body() -> String {
        setBodyCalls.last ?? .empty
    }

    override func setSubject(subject: String) -> VoidDraftSaveResult {
        setSubjectCalls.append(subject)
        return .ok
    }

    override func setBody(body: String) -> VoidDraftSaveResult {
        setBodyCalls.append(body)
        return .ok
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

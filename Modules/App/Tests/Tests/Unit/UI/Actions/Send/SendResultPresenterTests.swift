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
import InboxComposer
import InboxCoreUI
import InboxTesting
import proton_app_uniffi
import XCTest

final class SendResultPresenterTests: BaseTestCase {
    private let regularDuration: TimeInterval = .toastDefaultDuration
    private let mediumDuration: TimeInterval = .toastMediumDuration

    private var sut: SendResultPresenter!
    private let scheduledTime = Date.distantFuture
    private let scheduleDateFormatter = ScheduleSendDateFormatter()
    private var cancellables: Set<AnyCancellable>!
    private var capturedToastActions: [SendResultToastAction]!
    private var capturedDraftsToPresent: [DraftToPresent]!
    private let mockDraftUndoSendError: DraftUndoSendError = .reason(.sendCanNoLongerBeUndone)
    private var mockDraftUndoScheduleResult: DraftCancelScheduleSendResult { .error(mockDraftUndoScheduleError) }
    private let mockDraftUndoScheduleError: DraftCancelScheduleSendError = .reason(.messageNotScheduled)

    override func setUp() {
        super.setUp()

        self.capturedToastActions = .init()
        self.capturedDraftsToPresent = .init()
        self.cancellables = .init()
        sut = makeSut()
    }

    override func tearDown() {
        sut = nil
        capturedToastActions = nil
        capturedDraftsToPresent = nil
        cancellables = nil

        super.tearDown()
    }

    // MARK: presentResultInfo

    @MainActor
    func testPresentResultInfo_whenSending_itShouldPresentAToast() async {
        sut.presentResultInfo(.init(messageId: .random(), type: .sending))
        XCTAssertEqual(capturedToastActions.count, 1)

        XCTAssertTrue(capturedToastActions.first!.isSame(as: .present(.sendingMessage(duration: regularDuration))))
    }

    @MainActor
    func testPresentResultInfo_whenSending_andThenSentForTheSameMessageId_itShouldDismissToastFirstAndThenPresentAToast() async {
        let messageId: ID = .random()
        sut.presentResultInfo(.init(messageId: messageId, type: .sending))

        sut.presentResultInfo(.init(messageId: messageId, type: .sent))
        XCTAssertEqual(capturedToastActions.count, 3)

        XCTAssertTrue(
            capturedToastActions.isSame(as: [
                .present(.sendingMessage(duration: regularDuration)),
                .dismiss(.sendingMessage(duration: regularDuration)),
                .present(.messageSent(duration: mediumDuration, undoAction: {})),
            ]))
    }

    @MainActor
    func testPresentResultInfo_whenSending_andThenErrorForTheSameMessageId_itShouldDismissToastFirstAndThenPresentAToast() async {
        let messageId: ID = .random()
        let dummyError = DraftSendFailure.send(.messageDoesNotExist)
        sut.presentResultInfo(.init(messageId: messageId, type: .sending))

        sut.presentResultInfo(.init(messageId: messageId, type: .error(dummyError)))
        XCTAssertEqual(capturedToastActions.count, 3)

        XCTAssertTrue(
            capturedToastActions.isSame(as: [
                .present(.sendingMessage(duration: regularDuration)),
                .dismiss(.sendingMessage(duration: regularDuration)),
                .present(.error(message: dummyError.localizedDescription).duration(mediumDuration)),
            ]))
    }

    @MainActor
    func testPresentResultInfo_whenSending_andThenErrorThatShouldNotBeDisplayed_itShouldNotPresentTheErrorToast() async {
        let messageId: ID = .random()
        let dummyError = DraftSendFailure.send(.alreadySent)
        sut.presentResultInfo(.init(messageId: messageId, type: .sending))

        sut.presentResultInfo(.init(messageId: messageId, type: .error(dummyError)))
        XCTAssertEqual(capturedToastActions.count, 1)

        XCTAssertTrue(
            capturedToastActions.isSame(as: [
                .present(.sendingMessage(duration: regularDuration))
            ]))
    }

    // MARK: undoSendAction

    @MainActor
    func testUndoSendAction_whenSentHasBeenPresented_itShouldDismissSent() async {
        let messageId: ID = .random()
        sut.presentResultInfo(.init(messageId: messageId, type: .sent))

        await sut.undoSendActionForTestingPurposes()(messageId)

        XCTAssertEqual(capturedToastActions.count, 2)
        XCTAssertTrue(
            capturedToastActions.isSame(as: [
                .present(.messageSent(duration: mediumDuration, undoAction: {})),
                .dismiss(.messageSent(duration: mediumDuration, undoAction: {})),
            ]))
    }

    @MainActor
    func testUndoSendAction_whenSentHasBeenPresented_itShouldOpenDraftForTheMessageId() async {
        let messageId: ID = .random()
        sut.presentResultInfo(.init(messageId: messageId, type: .sent))

        await sut.undoSendActionForTestingPurposes()(messageId)

        XCTAssertEqual(capturedToastActions.count, 2)
        XCTAssertEqual(capturedDraftsToPresent.count, 1)
        XCTAssertEqual(capturedDraftsToPresent.first!.messageIdToOpen, messageId)
    }

    @MainActor
    func testUndoSendAction_whenSentHasBeenPresented_andUndoReturnsError_itShouldDismissSentAndPresentError() async {
        sut = makeSut(draftPresenter: .dummy(undoSendProvider: .mockInstance(stubbedResult: mockDraftUndoSendError)))

        let messageId: ID = .random()
        sut.presentResultInfo(.init(messageId: messageId, type: .sent))

        await sut.undoSendActionForTestingPurposes()(messageId)

        XCTAssertEqual(capturedToastActions.count, 3)
        XCTAssertTrue(
            capturedToastActions.isSame(as: [
                .present(.messageSent(duration: mediumDuration, undoAction: {})),
                .dismiss(.messageSent(duration: mediumDuration, undoAction: {})),
                .present(.error(message: mockDraftUndoSendError.localizedDescription).duration(mediumDuration)),
            ]))
    }

    // MARK: undoScheduleSendAction

    @MainActor
    func testUndoScheduleSendAction_whenScheduledHasBeenPresented_itShouldDismissScheduled() async {
        let messageId: ID = .random()
        sut.presentResultInfo(.init(messageId: messageId, type: .scheduled(date: scheduledTime)))
        await sut.undoScheduleSendActionForTestingPurposes()(messageId)

        let expectedToast: Toast = .scheduledMessage(
            duration: mediumDuration,
            scheduledTime: scheduleDateFormatter.string(from: scheduledTime, format: .long),
            undoAction: {}
        )
        XCTAssertEqual(capturedToastActions.count, 2)
        XCTAssertTrue(
            capturedToastActions.isSame(as: [
                .present(expectedToast),
                .dismiss(expectedToast),
            ]))
    }

    @MainActor
    func testUndoScheduleSendAction_whenScheduledHasBeenPresented_itShouldOpenDraftForTheMessageId() async {
        let messageId: ID = .random()
        sut.presentResultInfo(.init(messageId: messageId, type: .scheduled(date: scheduledTime)))

        await sut.undoScheduleSendActionForTestingPurposes()(messageId)

        XCTAssertEqual(capturedToastActions.count, 2)
        XCTAssertEqual(capturedDraftsToPresent.count, 1)
        XCTAssertEqual(capturedDraftsToPresent.first!.messageIdToOpen, messageId)
    }

    @MainActor
    func testUndoScheduleSendAction_whenScheduledHasBeenPresented_andUndoReturnsError_itShouldDismissScheduledAndPresentError() async throws {
        sut = makeSut(draftPresenter: .dummy(undoScheduleSendProvider: .mockInstance(stubbedResult: mockDraftUndoScheduleResult)))

        let messageId: ID = .random()
        sut.presentResultInfo(.init(messageId: messageId, type: .scheduled(date: scheduledTime)))

        await sut.undoScheduleSendActionForTestingPurposes()(messageId)

        let expectedToast: Toast = .scheduledMessage(
            duration: mediumDuration,
            scheduledTime: scheduleDateFormatter.string(from: scheduledTime, format: .long),
            undoAction: {}
        )
        XCTAssertEqual(capturedToastActions.count, 3)
        XCTAssertTrue(
            capturedToastActions.isSame(as: [
                .present(expectedToast),
                .dismiss(expectedToast),
                .present(.error(message: mockDraftUndoScheduleError.localizedDescription).duration(mediumDuration)),
            ]))
    }
}

private extension SendResultPresenterTests {

    func makeSut(draftPresenter: DraftPresenter = .dummy()) -> SendResultPresenter {
        let sut = SendResultPresenter(draftPresenter: draftPresenter)
        sut.toastAction.sink { self.capturedToastActions.append($0) }.store(in: &cancellables)
        draftPresenter.draftToPresent.sink { self.capturedDraftsToPresent.append($0) }.store(in: &cancellables)

        return sut
    }
}

private extension SendResultToastAction {

    var isPresent: Bool {
        switch self {
        case .present: true
        case .dismiss: false
        }
    }

    var isDismiss: Bool {
        switch self {
        case .present: false
        case .dismiss: true
        }
    }

    var toastHash: Int {
        switch self {
        case .present(let toast): toast.hashValue
        case .dismiss(let toast): toast.hashValue
        }
    }

    func isSameAction(as other: SendResultToastAction) -> Bool {
        (self.isPresent && other.isPresent) || (self.isDismiss && other.isDismiss)
    }

    func isSame(as other: SendResultToastAction) -> Bool {
        self.isSameAction(as: other) && self.toastHash == other.toastHash
    }
}

private extension Array where Element == SendResultToastAction {

    func isSame(as other: [SendResultToastAction]) -> Bool {
        guard self.count == other.count else { return false }

        for (action1, action2) in zip(self, other) {
            if !action1.isSame(as: action2) {
                return false
            }
        }
        return true
    }
}

private extension DraftToPresent {

    var messageIdToOpen: ID? {
        switch self {
        case .new:
            return nil
        case .openDraftId(let id, _):
            return id
        }
    }
}

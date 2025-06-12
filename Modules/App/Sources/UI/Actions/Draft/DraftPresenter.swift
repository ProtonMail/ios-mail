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
import Foundation
import InboxCore
import proton_app_uniffi

@MainActor
struct DraftPresenter: ContactsDraftPresenter {
    private let draftToPresentSubject = PassthroughSubject<DraftToPresent, Never>()
    private let userSession: MailUserSession
    private let draftProvider: DraftProvider
    private let undoSendProvider: UndoSendProvider
    private let undoScheduleSendProvider: UndoScheduleSendProvider

    var draftToPresent: AnyPublisher<DraftToPresent, Never> {
        draftToPresentSubject.eraseToAnyPublisher()
    }

    init(
        userSession: MailUserSession,
        draftProvider: DraftProvider,
        undoSendProvider: UndoSendProvider,
        undoScheduleSendProvider: UndoScheduleSendProvider
    ) {
        self.userSession = userSession
        self.draftProvider = draftProvider
        self.undoSendProvider = undoSendProvider
        self.undoScheduleSendProvider = undoScheduleSendProvider
    }

    func openNewDraft(onError: (DraftOpenError) -> Void) async {
        AppLogger.log(message: "open new draft", category: .composer)
        await openNewDraft(createMode: .empty, onError: onError)
    }

    func openDraft(withId messageId: ID, lastScheduledTime: UInt64? = nil) {
        AppLogger.log(message: "open existing draft", category: .composer)
        draftToPresentSubject.send(.openDraftId(messageId: messageId, lastScheduledTime: lastScheduledTime))
    }

    func openDraft(with contact: ContactDetailsEmail) async throws {
        AppLogger.log(message: "open new draft with contact details", category: .composer)

        await openNewEmptyDraft { toRecipients in
            let recipient = SingleRecipientEntry(name: contact.name, email: contact.email)
            _ = toRecipients.addSingleRecipient(recipient: recipient)
        }
    }

    func openDraft(with group: ContactGroupItem) async throws {
        await openNewEmptyDraft { toRecipients in
            let recipients = group.contactEmails.map { contact in
                SingleRecipientEntry(name: contact.name, email: contact.email)
            }

            _ = toRecipients.addGroupRecipient(
                groupName: group.name,
                recipients: recipients,
                totalContactsInGroup: UInt64(recipients.count)
            )
        }
    }

    func handleReplyAction(for messageId: ID, action: ReplyAction, onError: (DraftOpenError) -> Void) async {
        switch action {
        case .reply:
            await openReplyDraft(for: messageId, onError: onError)
        case .replyAll:
            await openReplyAllDraft(for: messageId, onError: onError)
        case .forward:
            await openForwardDraft(for: messageId, onError: onError)
        }
    }

    func undoSentMessageAndOpenDraft(for messageId: ID) async throws(DraftUndoSendError) {
        if let error = await undoSendProvider.undoSend(messageId) {
            throw error
        }
        openDraft(withId: messageId)
    }

    func cancelScheduledMessageAndOpenDraft(for messageId: ID) async throws(DraftCancelScheduleSendError) {
        let result = await undoScheduleSendProvider.undoScheduleSend(messageId)
        let lastScheduledTime = try result.get().lastScheduledTime
        openDraft(withId: messageId, lastScheduledTime: lastScheduledTime)
    }
}

extension DraftPresenter {

    private func openReplyDraft(for messageId: ID, onError: (DraftOpenError) -> Void) async {
        AppLogger.log(message: "open reply draft", category: .composer)
        await openNewDraft(createMode: .reply(messageId), onError: onError)
    }

    private func openReplyAllDraft(for messageId: ID, onError: (DraftOpenError) -> Void) async {
        AppLogger.log(message: "open reply all draft", category: .composer)
        await openNewDraft(createMode: .replyAll(messageId), onError: onError)
    }

    private func openForwardDraft(for messageId: ID, onError: (DraftOpenError) -> Void) async {
        AppLogger.log(message: "open forward draft", category: .composer)
        await openNewDraft(createMode: .forward(messageId), onError: onError)
    }

    private func openNewDraft(
        createMode: DraftCreateMode,
        updateDraft: ((Draft) -> Void)? = nil,
        onError: (DraftOpenError) -> Void
    ) async {
        switch await draftProvider.makeDraft(userSession, createMode) {
        case .ok(let draft):
            updateDraft?(draft)
            draftToPresentSubject.send(.new(draft: draft))
        case .error(let error):
            AppLogger.log(error: error, category: .composer)
            onError(error)
        }
    }

    private func openNewEmptyDraft(updateToRecipients: @escaping (ComposerRecipientList) -> Void) async {
        let updateDraft: (Draft) -> Void = { draft in
            updateToRecipients(draft.toRecipients())
        }

        await openNewDraft(createMode: .empty, updateDraft: updateDraft, onError: { _ in })
    }

}

extension DraftPresenter {

    static func dummy(
        undoSendProvider: UndoSendProvider = .mockInstance,
        undoScheduleSendProvider: UndoScheduleSendProvider = .mockInstance
    ) -> DraftPresenter {
        .init(
            userSession: .init(noPointer: .init()),
            draftProvider: .dummy,
            undoSendProvider: undoSendProvider,
            undoScheduleSendProvider: undoScheduleSendProvider
        )
    }

}

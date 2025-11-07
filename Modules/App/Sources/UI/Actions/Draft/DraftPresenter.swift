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

    func openNewDraft() async throws(DraftOpenError) {
        AppLogger.log(message: "open new draft", category: .composer)
        try await openNewDraft(createMode: .empty, updateDraft: .none)
    }

    func openDraft(withId messageId: ID, lastScheduledTime: UInt64? = nil) {
        AppLogger.log(message: "open existing draft", category: .composer)
        draftToPresentSubject.send(.openDraftId(messageId: messageId, lastScheduledTime: lastScheduledTime))
    }

    func openDraft(with recipient: SingleRecipientEntry) async throws(DraftOpenError) {
        AppLogger.log(message: "open new draft with single recipient", category: .composer)

        try await openNewEmptyDraft { toRecipients in
            _ = toRecipients.addSingleRecipient(recipient: recipient)
        }
    }

    func openDraft(with group: ContactGroupItem) async throws(DraftOpenError) {
        AppLogger.log(message: "open new draft with contact group details", category: .composer)

        try await openNewEmptyDraft { toRecipients in
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

    func openNewDraft(with mailtoData: MailtoData) async throws {
        AppLogger.log(message: "open new draft from mailto:", category: .composer)

        let updateDraft: (Draft) -> Void = { draft in
            addRecipients(from: mailtoData, under: \.to, to: draft.toRecipients)
            addRecipients(from: mailtoData, under: \.cc, to: draft.ccRecipients)
            addRecipients(from: mailtoData, under: \.bcc, to: draft.bccRecipients)

            do {
                if let subject = mailtoData.subject {
                    try draft.setSubject(subject: subject).get()
                }

                if let body = mailtoData.body {
                    try draft.setBody(body: body).get()
                }
            } catch {
                AppLogger.log(error: error, category: .composer)
            }
        }

        try await openNewDraft(createMode: .empty, updateDraft: updateDraft)
    }

    private func addRecipients(
        from mailtoData: MailtoData,
        under keyPath: KeyPath<MailtoData, [String]>,
        to recipientList: () -> ComposerRecipientList
    ) {
        let rawValues = mailtoData[keyPath: keyPath]
        let recipients = rawValues.map { email in SingleRecipientEntry(name: nil, email: email) }
        let list = recipientList()

        for recipient in recipients {
            let result = list.addSingleRecipient(recipient: recipient)

            if result != .ok {
                AppLogger.log(message: "\(result)", category: .composer, isError: true)
            }
        }
    }

    func openDraftForShareExtension() async throws {
        AppLogger.log(message: "open draft for Share extension", category: .composer)
        try await openNewDraft(createMode: .fromIosShareExtension, updateDraft: .none)
    }

    func handleReplyAction(for messageId: ID, action: ReplyAction) async throws(DraftOpenError) {
        AppLogger.log(message: action.logDescription, category: .composer)
        try await openNewDraft(createMode: action.createMode(messageId: messageId), updateDraft: .none)
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

    private func openNewDraft(
        createMode: DraftCreateMode,
        updateDraft: ((Draft) -> Void)?
    ) async throws(DraftOpenError) {
        switch await draftProvider.makeDraft(userSession, createMode, .safe) {
        case .ok(let draft):
            updateDraft?(draft)
            draftToPresentSubject.send(.new(draft: draft))
        case .error(let error):
            AppLogger.log(error: error, category: .composer)
            throw error
        }
    }

    private func openNewEmptyDraft(updateToRecipients: @escaping (ComposerRecipientList) -> Void) async throws(DraftOpenError) {
        let updateDraft: (Draft) -> Void = { draft in
            updateToRecipients(draft.toRecipients())
        }

        try await openNewDraft(createMode: .empty, updateDraft: updateDraft)
    }

}

private extension ReplyAction {
    var logDescription: String {
        switch self {
        case .reply: "open reply draft"
        case .replyAll: "open reply all draft"
        case .forward: "open forward draft"
        }
    }

    func createMode(messageId: ID) -> DraftCreateMode {
        switch self {
        case .reply: .reply(messageId)
        case .replyAll: .replyAll(messageId)
        case .forward: .forward(messageId)
        }
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

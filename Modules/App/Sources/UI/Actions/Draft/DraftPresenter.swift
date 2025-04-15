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
import InboxCore
import proton_app_uniffi

struct DraftPresenter {
    private let draftToPresentSubject = PassthroughSubject<DraftToPresent, Never>()
    private let userSession: MailUserSession
    private let draftProvider: DraftProvider

    var draftToPresent: AnyPublisher<DraftToPresent, Never> {
        draftToPresentSubject.eraseToAnyPublisher()
    }

    init(userSession: MailUserSession, draftProvider: DraftProvider) {
        self.userSession = userSession
        self.draftProvider = draftProvider
    }

    @MainActor
    func openNewDraft(onError: (DraftOpenError) -> Void) async {
        AppLogger.log(message: "open new draft", category: .composer)
        await publishDraftToPresent(createMode: .empty, onError: onError)
    }

    @MainActor
    func openDraft(withId messageId: ID) {
        AppLogger.log(message: "open existing draft", category: .composer)
        draftToPresentSubject.send(.openDraftId(messageId: messageId))
    }

    @MainActor
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
}

extension DraftPresenter {

    @MainActor
    private func openReplyDraft(for messageId: ID, onError: (DraftOpenError) -> Void) async {
        AppLogger.log(message: "open reply draft", category: .composer)
        await publishDraftToPresent(createMode: .reply(messageId), onError: onError)
    }

    @MainActor
    private func openReplyAllDraft(for messageId: ID, onError: (DraftOpenError) -> Void) async {
        AppLogger.log(message: "open reply all draft", category: .composer)
        await publishDraftToPresent(createMode: .replyAll(messageId), onError: onError)
    }

    @MainActor
    private func openForwardDraft(for messageId: ID, onError: (DraftOpenError) -> Void) async {
        AppLogger.log(message: "open forward draft", category: .composer)
        await publishDraftToPresent(createMode: .forward(messageId), onError: onError)
    }

    @MainActor
    private func publishDraftToPresent(createMode: DraftCreateMode, onError: (DraftOpenError) -> Void) async {
        switch await draftProvider.makeDraft(userSession, createMode) {
        case .ok(let draft):
            draftToPresentSubject.send(.new(draft: draft))
        case .error(let error):
            AppLogger.log(error: error, category: .composer)
            onError(error)
        }
    }
}

extension DraftPresenter {

    static var dummy: DraftPresenter {
        .init(userSession: .init(noPointer: .init()), draftProvider: .dummy)
    }
}

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
import InboxCoreUI
import InboxComposer

/**
 This class handles all toast notifications related to sending a message, from the moment
 the user presses send. More specifically in manages the toast presentation and dismissal for each
 message being sent.
*/
final class SendResultPresenter {
    private typealias MessageID = ID
    private let sendingMessageDuration: TimeInterval = 10.0
    private let regularDuration: TimeInterval = 5.0
    private var toasts = [MessageID: Toast]()
    private let subject = PassthroughSubject<SendResultToastAction, Never>()
    private let undoSendProvider: UndoSendProvider
    private let draftPresenter: DraftPresenter

    init(undoSendProvider: UndoSendProvider, draftPresenter: DraftPresenter) {
        self.undoSendProvider = undoSendProvider
        self.draftPresenter = draftPresenter
    }

    var toastAction: AnyPublisher<SendResultToastAction, Never> {
        subject.eraseToAnyPublisher()
    }

    @MainActor
    func presentResultInfo(_ info: SendResultInfo) {
        switch info.type {
        case .sending:
            handleToast(.sendingMessage(duration: sendingMessageDuration), for: info.messageId)

        case .sent:
            let toast: Toast = .messageSent(duration: regularDuration) { [weak self] in
                Task { await self?.undoAction(for: info.messageId) }
            }
            handleToast(toast, for: info.messageId)

        case .error(let error):
            if error.shouldBeDisplayed {
                handleToast(.error(message: error.localizedDescription), for: info.messageId)
            }
        }
    }

    @MainActor
    func undoActionForTestingPurposes() -> (ID) async -> Void {
        self.undoAction
    }
}

// MARK: Private methods

@MainActor
extension SendResultPresenter {

    private func undoAction(for messageId: MessageID) async {
        removeAndDismissToastReference(for: messageId)

        let error = await undoSendProvider.undoSend(messageId)
        guard error == nil else {
            present(toast: .error(message: error!.localizedDescription))
            return
        }
        await draftPresenter.openDraft(withId: messageId)
    }

    private func handleToast(_ toast: Toast, for messageId: MessageID) {
        removeAndDismissToastReference(for: messageId)
        storeToastReference(toast, for: messageId)
        present(toast: toast)
    }

    private func removeAndDismissToastReference(for messageId: MessageID) {
        if let existingToast = toasts[messageId] {
            dismiss(toast: existingToast)
            toasts[messageId] = nil
        }
    }

    private func storeToastReference(_ toast: Toast, for messageId: MessageID) {
        toasts[messageId] = toast
    }

    private func present(toast: Toast) {
        subject.send(.present(toast))
    }

    private func dismiss(toast: Toast) {
        subject.send(.dismiss(toast))
    }
}

enum SendResultToastAction {
    case present(Toast)
    case dismiss(Toast)
}

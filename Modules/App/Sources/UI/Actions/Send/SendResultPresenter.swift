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
import enum proton_app_uniffi.DraftSendFailure

/**
 This class handles all toast notifications related to sending a message, from the moment
 the user presses send. More specifically it manages the toast presentation and dismissal for each
 message being sent.
*/
final class SendResultPresenter {
    private typealias MessageID = ID
    private let regularDuration: TimeInterval = .toastDefaultDuration
    private let extendedDuration: TimeInterval = 3.0
    private var toasts = [MessageID: Toast]()
    private let subject = PassthroughSubject<SendResultToastAction, Never>()
    private let draftPresenter: DraftPresenter

    init(draftPresenter: DraftPresenter) {
        self.draftPresenter = draftPresenter
    }

    var toastAction: AnyPublisher<SendResultToastAction, Never> {
        subject.eraseToAnyPublisher()
    }

    @MainActor
    func presentResultInfo(_ info: SendResultInfo) {
        switch info.type {
        case .scheduling:
            handleToast(.schedulingMessage(duration: regularDuration), for: info.messageId)

        case .scheduled(let deliveryTime):
            let formattedTime = ScheduleSendDateFormatter().string(from: deliveryTime, format: .long)
            let toast: Toast = .scheduledMessage(duration: extendedDuration, scheduledTime: formattedTime) { [weak self] in
                Task { await self?.undoScheduleSendAction(for: info.messageId) }
            }
            handleToast(toast, for: info.messageId)

        case .sending:
            handleToast(.sendingMessage(duration: regularDuration), for: info.messageId)

        case .sent(let secondsToUndo):
            let duration = min(TimeInterval(secondsToUndo), extendedDuration)
            let toast: Toast
            if duration > 0 {
                toast = .messageSent(duration: duration) { [weak self] in
                    Task { await self?.undoSendAction(for: info.messageId) }
                }
            } else {
                toast = .messageSentWithoutUndo(duration: regularDuration)
            }
            handleToast(toast, for: info.messageId)

        case .error(let error):
            if error.shouldBeDisplayed {
                handleToast(.error(message: error.localizedDescription).duration(.toastMediumDuration), for: info.messageId)
            }
        }
    }

    @MainActor
    func undoSendActionForTestingPurposes() -> (ID) async -> Void {
        self.undoSendAction
    }

    @MainActor
    func undoScheduleSendActionForTestingPurposes() -> (ID) async -> Void {
        self.undoScheduleSendAction
    }

}

// MARK: Private methods

@MainActor
extension SendResultPresenter {

    private func undoSendAction(for messageId: MessageID) async {
        do {
            removeAndDismissToastReference(for: messageId)
            try await draftPresenter.undoSentMessageAndOpenDraft(for: messageId)
        } catch {
            present(toast: .error(message: error.localizedDescription).duration(.toastMediumDuration))
        }
    }

    private func undoScheduleSendAction(for messageId: MessageID) async {
        do {
            removeAndDismissToastReference(for: messageId)
            try await draftPresenter.cancelScheduledMessageAndOpenDraft(for: messageId)
        } catch {
            present(toast: .error(message: error.localizedDescription).duration(.toastMediumDuration))
        }
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

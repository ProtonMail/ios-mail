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

import InboxCore
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

@MainActor
final class EventLoopErrorCoordinator: ObservableObject {
    private let toastStateStore: ToastStateStore
    private var handle: EventLoopErrorObserverHandle?

    private lazy var eventLoopErrorCallback = EventLoopErrorCallbackWrapper { [weak self] error in
        guard let self else { return }
        await MainActor.run {
            self.onEventLoopError(error: error)
        }
    }

    init(userSession: MailUserSession, toastStateStore: ToastStateStore) {
        self.toastStateStore = toastStateStore
        do {
            handle = try userSession.observeEventLoopErrors(callback: eventLoopErrorCallback).get()
        } catch {
            let errorMessage = "Failed to start observation for event loop due to: \(error.localizedDescription)"
            let eventError: EventError = .other(.otherReason(.other(errorMessage)))
            onEventLoopError(error: eventError)
        }
    }

    private func onEventLoopError(error: EventError) {
        AppLogger.log(error: error)
        let toast = Toast(
            title: nil,
            message: L10n.EventLoopError.eventLoopErrorMessage.string,
            button: nil,
            style: .error,
            duration: 10
        )
        toastStateStore.present(toast: toast)
    }

    deinit {
        handle?.disconnect()
    }
}

private final class EventLoopErrorCallbackWrapper: Sendable, EventLoopErrorObserver {
    private let callback: @Sendable (EventError) async -> Void

    init(callback: @escaping @Sendable (EventError) async -> Void) {
        self.callback = callback
    }

    func onEventLoopError(error: EventError) async {
        await callback(error)
    }
}

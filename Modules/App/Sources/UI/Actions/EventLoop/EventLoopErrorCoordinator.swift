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

final class EventLoopErrorCoordinator: Sendable, ObservableObject {
    private let userSession: MailUserSession
    private let toastStateStore: ToastStateStore
    private let handle: EventLoopErrorObserverHandle
    private let eventLoopErrorCallback: EventLoopErrorCallbackWrapper = .init()

    init(userSession: MailUserSession, toastStateStore: ToastStateStore) {
        self.userSession = userSession
        self.toastStateStore = toastStateStore
        self.handle = userSession.observeEventLoopErrors(callback: eventLoopErrorCallback)
        eventLoopErrorCallback.delegate = { [weak self] error in
            AppLogger.log(error: error)
            let toast = Toast(
                title: nil,
                message: L10n.EventLoopError.eventLoopErrorMessage.string,
                button: nil,
                style: .error,
                duration: 10
            )
            self?.toastStateStore.present(toast: toast)
        }
    }

    deinit {
        handle.disconnect()
    }
}

final class EventLoopErrorCallbackWrapper: @unchecked Sendable, EventLoopErrorObserver {
    var delegate: ((EventError) -> Void)?

    func onEventLoopError(error: EventError) async {
        delegate?(error)
    }
}

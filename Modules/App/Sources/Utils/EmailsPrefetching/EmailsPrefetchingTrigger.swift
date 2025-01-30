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

class EmailsPrefetchingTrigger: @unchecked Sendable, ObservableObject {

    private let emailsPrefetchingNotifier: EmailsPrefetchingNotifier
    private let sessionProvider: SessionProvider
    private var emailsPrefetchingNotifierCancellable: AnyCancellable?
    private let prefetch: (MailUserSession) async -> PrefetchResult

    init(
        emailsPrefetchingNotifier: EmailsPrefetchingNotifier,
        sessionProvider: SessionProvider,
        prefetch: @escaping (MailUserSession) async -> PrefetchResult
    ) {
        self.emailsPrefetchingNotifier = emailsPrefetchingNotifier
        self.sessionProvider = sessionProvider
        self.prefetch = prefetch
    }

    func setUpSubscription() {
        emailsPrefetchingNotifierCancellable = emailsPrefetchingNotifier.observation
            .debounce(for: Dispatcher.timeInSeconds(1), scheduler: Dispatcher.globalQueue(.utility))
            .sink(receiveValue: { [weak self] in self?.prefetchEmails() })
    }

    // MARK: - Private

    private func prefetchEmails() {
        guard sessionProvider.sessionState.isAuthorized else { return }
        let mailUserSession = sessionProvider.userSession
        Task {
            await prefetch(mailUserSession)
        }
    }

}

// Copyright (c) 2024 Proton Technologies AG
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
import proton_mail_uniffi

final class AppState: ObservableObject {
    @Published private (set) var activeSession: Bool = false

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = .init()

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
        dependencies
            .sessionProvider
            .activeUserStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.activeSession = status.hasActiveUser
            }
            .store(in: &cancellables)
    }

    var hasAuthenticatedSession: Bool {
        dependencies.sessionProvider.activeUserStatusPublisher.value.hasActiveUser
    }

    func logoutActiveSession() async {
        do {
            try await dependencies.sessionProvider.logoutActiveUserSession()
        } catch {
            AppLogger.log(error: error, category: .rustLibrary)
        }
    }
}

extension AppState {

    struct Dependencies {
        let sessionProvider: SessionProvider

        init(sessionProvider: SessionProvider = AppContext.shared) {
            self.sessionProvider = sessionProvider
        }
    }
}

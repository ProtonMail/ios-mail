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

import Foundation
import proton_mail_uniffi

final class AppState: ObservableObject {
    @Published private (set) var activeSession: Bool = false

    weak var appContext: AppContext?

    var hasAuthenticatedSession: Bool {
        appContext?.activeSession != nil
    }

    @MainActor
    func refresh() {
        activeSession = hasAuthenticatedSession
    }

    func removeActiveSession() {
        guard let appContext else { return }
        Task {
            await appContext.removeSession()
        }
    }
}

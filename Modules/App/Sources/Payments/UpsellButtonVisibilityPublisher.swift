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

import Foundation
import InboxCore
import proton_app_uniffi

@MainActor
final class UpsellButtonVisibilityPublisher: ObservableObject {
    @Published private(set) var isUpsellButtonVisible = false

    private var watchHandle: WatchHandle?

    init(userSession: MailUserSession) {
        let callback = AsyncLiveQueryCallbackWrapper { [weak self] in
            await self?.updateHeaderVisibility(userSession: userSession)
        }

        Task {
            await updateHeaderVisibility(userSession: userSession)

            do {
                watchHandle = try userSession.watchUser(callback: callback).get()
            } catch {
                AppLogger.log(error: error, category: .payments)
            }
        }
    }

    init(constant: Bool) {
        isUpsellButtonVisible = constant
    }

    deinit {
        watchHandle?.disconnect()
    }

    private func updateHeaderVisibility(userSession: MailUserSession) async {
        do {
            let user = try await userSession.user().get()
            isUpsellButtonVisible = user.subscribed == 0
        } catch {
            AppLogger.log(error: error, category: .payments)
        }
    }
}

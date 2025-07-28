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
@preconcurrency import PaymentsNG
import proton_app_uniffi

@MainActor
final class UpsellButtonVisibilityPublisher: ObservableObject {
    @Published private(set) var isUpsellButtonVisible = false

    private let userSession: MailUserSession

    init(userSession: MailUserSession) {
        self.userSession = userSession
    }

    func start() {
        Task {
            isUpsellButtonVisible = await isUserOnFreePlan()

            // FIXME: replace this with User watcher once the SDK exposes one
            if isUpsellButtonVisible {
                await waitUntilUserCompletesAPurchase()
                isUpsellButtonVisible = false
            }
        }
    }

    private func isUserOnFreePlan() async -> Bool {
        do {
            let user = try await userSession.user().get()
            return user.subscribed == 0
        } catch {
            AppLogger.log(error: error, category: .payments)
            return false
        }
    }

    private func waitUntilUserCompletesAPurchase() async {
        for await transactionStatus in TransactionsObserver.shared.$transactionStatus.values {
            if transactionStatus == .successful {
                break
            }
        }
    }
}

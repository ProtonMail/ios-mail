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
import StoreKit

@MainActor
final class UpsellEligibilityPublisher: ObservableObject {
    @Published private(set) var state: UpsellEligibility = .notEligible

    private var watchHandles: [WatchHandle] = []

    init(mailSession: MailSession, userSession: MailUserSession) {
        let callback = AsyncLiveQueryCallbackWrapper { [weak self] in
            await self?.updateState(mailSession: mailSession, userSession: userSession)
        }

        Task {
            await updateState(mailSession: mailSession, userSession: userSession)

            do {
                watchHandles = [
                    try userSession.watchUpsellEligibility(callback: callback).get(),
                    try await mailSession.watchFeatureFlagsAsync(callback: callback).get().handle,
                ]
            } catch {
                AppLogger.log(error: error, category: .payments)
            }
        }
    }

    init(constant: UpsellEligibility) {
        state = constant
    }

    deinit {
        for watchHandle in watchHandles {
            watchHandle.disconnect()
        }

        watchHandles.removeAll()
    }

    private func updateState(mailSession: MailSession, userSession: MailUserSession) async {
        do {
            let upsellEligibility = try await userSession.upsellEligibility().get()
            state = await upsellEligibility.limitingBlackFridayToUSA()
        } catch {
            AppLogger.log(error: error, category: .payments)
        }
    }
}

private extension UpsellEligibility {
    func limitingBlackFridayToUSA() async -> Self {
        if case .eligible(.blackFriday) = self, await Storefront.current?.countryCode != "USA" {
            .eligible(.standard)
        } else {
            self
        }
    }
}

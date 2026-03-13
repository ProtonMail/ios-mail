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

import InboxAttribution
import InboxCore
import InboxIAP
import PaymentsNG
import PaymentsUI
import SwiftUI
import proton_app_uniffi

struct SubscriptionsScreen: View {
    @StateObject var viewModel: AvailablePlansViewModel
    @EnvironmentObject var userAttributionService: UserAttributionService
    let paymentsManager: ProtonPlansManager

    init(mailUserSession: MailUserSession, presentationMode: PaymentsUI.PresentationMode) {
        _viewModel = .init(
            wrappedValue: .init(
                appVersion: AppDetails.mail.backendFacingVersion,
                presentationMode: presentationMode,
                rustSession: mailUserSession
            ))
        self.paymentsManager = .init(rustSession: mailUserSession)
    }

    var body: some View {
        AvailablePlansView(viewModel: viewModel)
            .onReceive(viewModel.transactionProgress) { transactionProgress in
                guard transactionProgress == .transactionCompleted else { return }
                Task {
                    let currentPlan = try await paymentsManager.getCurrentPlan()

                    if let planMetadata = currentPlan.metadata {
                        await userAttributionService.handle(event: .subscribed(metadata: planMetadata))
                    } else {
                        AppLogger.log(
                            message: "Failed to map API subscription: planName=\(currentPlan.name ?? "nil"), cycle=\(currentPlan.cycle?.description ?? "nil")",
                            category: .adAttribution
                        )
                    }
                }
            }
    }
}

private extension CurrentSubscriptionResponse {
    var metadata: SubscriptionPlanMetadata? {
        guard let plan, let duration else { return nil }
        return .init(plan: plan, duration: duration)
    }

    private var plan: SubscriptionPlan? {
        switch name {
        case SubscriptionPlanVariant.plus:
            .plus
        case SubscriptionPlanVariant.unlimited:
            .unlimited
        default:
            nil
        }
    }

    private var duration: SubscriptionDuration? {
        switch cycle {
        case 1:
            .month
        case 12:
            .year
        default:
            nil
        }
    }
}

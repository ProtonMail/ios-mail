//
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
import PaymentsNG
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

@MainActor
final class PurchaseActionPerformer {
    private let eventLoopPolling: EventLoopPolling
    private let planPurchasing: PlanPurchasing
    private let telemetryReporting: TelemetryReporting
    private let userAttributionService: UserAttributionService

    init(
        eventLoopPolling: EventLoopPolling,
        planPurchasing: PlanPurchasing,
        telemetryReporting: TelemetryReporting,
        userAttributionService: UserAttributionService
    ) {
        self.eventLoopPolling = eventLoopPolling
        self.planPurchasing = planPurchasing
        self.telemetryReporting = telemetryReporting
        self.userAttributionService = userAttributionService
    }

    func purchase(
        storeKitProductID: String,
        isBusy: Binding<Bool>,
        toastStateStore: ToastStateStore,
        dismiss: () -> Void
    ) async {
        AppLogger.log(message: "Attempting to purchase \(storeKitProductID)", category: .payments)
        await telemetryReporting.upgradeAttempt(storeKitProductID: storeKitProductID)

        isBusy.wrappedValue = true

        defer {
            isBusy.wrappedValue = false
        }

        do {
            try await planPurchasing.purchase(storeKitProductId: storeKitProductID)

            AppLogger.log(message: "Purchase successful", category: .payments)

            async let telemetry: () = telemetryReporting.upgradeSuccess(storeKitProductID: storeKitProductID)
            async let eventLoop: () = eventLoopPolling.forceEventLoopPollAndWait().logError()

            if let metadata = StoreKitProductIDMapper.map(storeKitProductID: storeKitProductID) {
                async let attribution: () = userAttributionService.handle(event: .subscribed(metadata: metadata))
                _ = await (telemetry, attribution, eventLoop)
            } else {
                AppLogger.log(
                    message: "Unable to map product ID '\(storeKitProductID)' for attribution",
                    category: .adAttribution
                )
                _ = await (telemetry, eventLoop)
            }

            dismiss()
        } catch ProtonPlansManagerError.transactionCancelledByUser {
            await telemetryReporting.upgradeCancelled(storeKitProductID: storeKitProductID)
        } catch let error as IAPsNotAvailableInTestFlightError {
            toastStateStore.present(toast: .information(message: error.localizedDescription))
        } catch {
            AppLogger.log(error: error, category: .payments)
            toastStateStore.present(toast: .error(message: error.localizedDescription))
            await telemetryReporting.upgradeError(storeKitProductID: storeKitProductID)
        }
    }
}

private extension VoidEventResult {
    func logError() async {
        switch self {
        case .ok:
            break
        case .error(let eventError):
            AppLogger.log(message: "\(eventError)", category: .payments, isError: true)
        }
    }
}

extension PurchaseActionPerformer {
    static let dummy = PurchaseActionPerformer(
        eventLoopPolling: DummyEventLoopPolling(),
        planPurchasing: DummyPlanPurchasing(),
        telemetryReporting: DummyTelemetryReporting(),
        userAttributionService: .init(userSettingsProvider: { .mock() }, userDefaults: UserDefaults())
    )
}

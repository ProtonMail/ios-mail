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

import InboxCoreUI
import PaymentsNG
import SwiftUI

@MainActor
@Observable
public final class OnboardingUpsellScreenModel: Identifiable {
    var selectedCycle: BillingCycle
    private var isBusy = false

    let availableCycles: [BillingCycle] = [
        .yearly,
        .monthly,
    ]

    var visiblePlanTiles: [PlanTileModel] {
        allPlanTiles
            .filter { $0.cycleInMonths == selectedCycle.lengthInMonths }
    }

    private let allPlanTiles: [PlanTileModel]
    private let purchaseActionPerformer: PurchaseActionPerformer

    private var highestDiscount: Int? {
        allPlanTiles.compactMap(\.discount?.percentageValue).max()
    }

    init(planTiles: [PlanTileData], purchaseActionPerformer: PurchaseActionPerformer) {
        allPlanTiles = planTiles.map(PlanTileModel.init)
        self.purchaseActionPerformer = purchaseActionPerformer

        selectedCycle = availableCycles[0]
    }

    func label(for billingCycle: BillingCycle) -> LocalizedStringResource {
        switch billingCycle {
        case .monthly:
            L10n.BillingCycle.monthly
        case .yearly:
            if let highestDiscount {
                L10n.BillingCycle.yearly(discount: highestDiscount)
            } else {
                L10n.BillingCycle.yearlyNoDiscount
            }
        }
    }

    func onGetPlanTapped(storeKitProductID: String?, toastStateStore: ToastStateStore, dismiss: () -> Void) async {
        guard !isBusy else {
            return
        }

        guard let storeKitProductID else {
            dismiss()
            return
        }

        await purchaseActionPerformer.purchase(
            storeKitProductID: storeKitProductID,
            isBusy: .init(get: { self.isBusy }, set: { self.isBusy = $0 }),
            toastStateStore: toastStateStore,
            dismiss: dismiss
        )
    }
}

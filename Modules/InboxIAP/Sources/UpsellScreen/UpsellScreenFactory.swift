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
@preconcurrency import PaymentsNG
import proton_app_uniffi
import StoreKit

public final class UpsellScreenFactory {
    private let planPurchasing: PlanPurchasing

    init(planPurchasing: PlanPurchasing) {
        self.planPurchasing = planPurchasing
    }

    @MainActor
    public func upsellScreenModel(basedOn upsellOffer: UpsellOffer) -> UpsellScreenModel {
        let plansSortedByPriceAscending = upsellOffer.composedPlans.sorted(using: KeyPathComparator(\.storePricePerMonth, order: .forward))
        let mostExpensiveInstance = plansSortedByPriceAscending.last!

        let displayablePlanInstances: [DisplayablePlanInstance] = plansSortedByPriceAscending.map { composedPlan in
            .init(
                storeKitProductId: composedPlan.instance.vendors.apple?.productID ?? "<missing vendor>",
                cycleInMonths: composedPlan.instance.cycle,
                monthlyPrice: composedPlan.pricePerMonthLabel,
                discount: composedPlan.discount(comparedTo: mostExpensiveInstance)
            )
        }

        return .init(
            planName: mostExpensiveInstance.plan.title,
            planInstances: displayablePlanInstances,
            planPurchasing: planPurchasing
        )
    }
}

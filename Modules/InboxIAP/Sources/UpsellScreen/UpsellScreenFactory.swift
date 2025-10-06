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

final class UpsellScreenFactory {
    private let purchaseActionPerformer: PurchaseActionPerformer

    init(purchaseActionPerformer: PurchaseActionPerformer) {
        self.purchaseActionPerformer = purchaseActionPerformer
    }

    @MainActor
    func upsellScreenModel(
        showingPlan planName: String,
        basedOn availablePlans: [ComposedPlan],
        entryPoint: UpsellScreenEntryPoint
    ) throws -> UpsellScreenModel {
        let (plansSortedByPriceAscending, mostExpensiveInstance) = try sortedInstancesWithMostExpensiveInstance(
            ofPlanNamed: planName,
            basedOn: availablePlans
        )

        let displayablePlanInstances: [DisplayablePlanInstance] = plansSortedByPriceAscending.map { composedPlan in
            .init(
                storeKitProductId: composedPlan.storeKitProductID ?? "<missing vendor>",
                cycleInMonths: composedPlan.instance.cycle,
                monthlyPrice: composedPlan.pricePerMonthLabel,
                discount: composedPlan.discount(comparedTo: mostExpensiveInstance)
            )
        }

        return .init(
            planName: mostExpensiveInstance.plan.title,
            planInstances: displayablePlanInstances,
            entryPoint: entryPoint,
            purchaseActionPerformer: purchaseActionPerformer
        )
    }

    @MainActor
    func onboardingUpsellScreenModel(
        showingPlans planNames: [String],
        basedOn availablePlans: [ComposedPlan]
    ) throws -> OnboardingUpsellScreenModel {
        let paidPlanTilesData: [PlanTileData] = try planNames.flatMap { planName in
            try planTilesData(forPlanNamed: planName, basedOn: availablePlans)
        }

        let freePlanTilesData = BillingCycle.allCases.map { billingCycle in
            PlanTileData.free(
                priceFormatStyle: availablePlans[0].product.priceFormatStyle,
                cycleInMonths: billingCycle.lengthInMonths
            )
        }

        return .init(planTiles: paidPlanTilesData + freePlanTilesData, purchaseActionPerformer: purchaseActionPerformer)
    }

    @MainActor
    private func planTilesData(forPlanNamed planName: String, basedOn availablePlans: [ComposedPlan]) throws -> [PlanTileData] {
        let (plansSortedByPriceAscending, mostExpensiveInstance) = try sortedInstancesWithMostExpensiveInstance(
            ofPlanNamed: planName,
            basedOn: availablePlans
        )

        return plansSortedByPriceAscending.map { composedPlan in
            .init(
                storeKitProductID: composedPlan.storeKitProductID,
                planName: composedPlan.plan.title,
                cycleInMonths: composedPlan.instance.cycle,
                discount: discount(of: composedPlan, comparedTo: mostExpensiveInstance),
                entitlements: composedPlan.plan.entitlements.compactMap(\.asDescription),
                formattedPrice: composedPlan.product.displayPrice
            )
        }
    }

    private func discount(of composedPlan: ComposedPlan, comparedTo mostExpensiveInstance: ComposedPlan) -> PlanTileData.Discount? {
        guard let percentageValue = composedPlan.discount(comparedTo: mostExpensiveInstance) else {
            return nil
        }

        let savedAmount = (mostExpensiveInstance.storePricePerMonth - composedPlan.storePricePerMonth) * 12
        let savedAmountLabel = composedPlan.product.priceFormatStyle.format(savedAmount)

        return .init(
            percentageValue: percentageValue,
            savedAmount: savedAmountLabel
        )
    }

    private func sortedInstancesWithMostExpensiveInstance(
        ofPlanNamed planName: String,
        basedOn availablePlans: [ComposedPlan]
    ) throws -> ([ComposedPlan], ComposedPlan) {
        let relevantPlans = availablePlans.filter { $0.plan.name == planName }
        let plansSortedByPriceAscending = relevantPlans.sorted(using: KeyPathComparator(\.storePricePerMonth, order: .forward))

        guard let mostExpensiveInstance = plansSortedByPriceAscending.last else {
            throw UpsellScreenFactoryError.planNotFound
        }

        return (plansSortedByPriceAscending, mostExpensiveInstance)
    }
}

enum UpsellScreenFactoryError: LocalizedError {
    case planNotFound

    var errorDescription: String? {
        switch self {
        case .planNotFound:
            L10n.Error.planNotFound.string
        }
    }
}

private extension ComposedPlan {
    var storeKitProductID: String? {
        instance.vendors.apple?.productID
    }
}

private extension Entitlement {
    var asDescription: DescriptionEntitlement? {
        switch self {
        case .description(let descriptionEntitlement):
            descriptionEntitlement
        default:
            nil
        }
    }
}

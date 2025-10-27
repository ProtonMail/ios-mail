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
import PaymentsNG
import proton_app_uniffi
import StoreKit

final class UpsellScreenFactory {
    private let purchaseActionPerformer: PurchaseActionPerformer
    private let webCheckout: WebCheckout

    init(purchaseActionPerformer: PurchaseActionPerformer, webCheckout: WebCheckout) {
        self.purchaseActionPerformer = purchaseActionPerformer
        self.webCheckout = webCheckout
    }

    @MainActor
    func upsellScreenModel(
        showingPlan planName: String,
        basedOn availablePlans: [ComposedPlan],
        entryPoint: UpsellEntryPoint,
        upsellType: UpsellType
    ) throws -> UpsellScreenModel {
        let (plansSortedByPriceAscending, mostExpensiveInstance) = try sortedInstancesWithMostExpensiveInstance(
            ofPlanNamed: planName,
            basedOn: availablePlans
        )

        let displayablePlanInstances = try displayableInstances(
            basedOn: plansSortedByPriceAscending,
            mostExpensiveInstance: mostExpensiveInstance,
            upsellType: upsellType
        )

        return .init(
            planName: mostExpensiveInstance.plan.title,
            planInstances: displayablePlanInstances,
            entryPoint: entryPoint,
            upsellType: upsellType,
            purchaseActionPerformer: purchaseActionPerformer,
            webCheckout: webCheckout
        )
    }

    private func displayableInstances(
        basedOn availablePlans: [ComposedPlan],
        mostExpensiveInstance: ComposedPlan,
        upsellType: UpsellType
    ) throws -> [DisplayablePlanInstance] {
        switch upsellType {
        case .standard:
            availablePlans.map { composedPlan in
                .init(
                    storeKitProductId: composedPlan.storeKitProductID ?? "<missing vendor>",
                    cycleInMonths: composedPlan.instance.cycle,
                    pricing: .regular(monthlyPrice: composedPlan.pricePerMonthLabel),
                    discount: composedPlan.discount(comparedTo: mostExpensiveInstance)
                )
            }
        case .blackFriday(let wave):
            [
                try promotionalPlanInstance(basedOn: availablePlans, wave: wave)
            ]
        }
    }

    private func promotionalPlanInstance(
        basedOn availablePlans: [ComposedPlan],
        wave: BlackFridayWave
    ) throws -> DisplayablePlanInstance {
        guard
            let (monthlyInstance, monthlyPrice) = findInstanceAndUSDPrice(forCycle: 1, among: availablePlans),
            let (yearlyInstance, yearlyPrice) = findInstanceAndUSDPrice(forCycle: 12, among: availablePlans)
        else {
            throw UpsellScreenFactoryError.planNotFound
        }

        let priceFormatStyle = yearlyInstance.product.priceFormatStyle
        let discountedMonthlyPrice = monthlyPrice / wave.discountFactor

        switch wave {
        case .wave1:
            return .init(
                storeKitProductId: yearlyInstance.storeKitProductID ?? "<missing vendor>",
                cycleInMonths: yearlyInstance.instance.cycle,
                pricing: .discountedYearlyPlan(
                    discountedMonthlyPrice: formatPrice(discountedMonthlyPrice, using: priceFormatStyle),
                    discountedYearlyPrice: formatPrice(discountedMonthlyPrice * 12, using: priceFormatStyle),
                    renewalPrice: formatPrice(yearlyPrice, using: priceFormatStyle)
                ),
                discount: wave.discount
            )
        case .wave2:
            let specialPriceFormat = priceFormatStyle.precision(.fractionLength(0))

            return .init(
                storeKitProductId: monthlyInstance.storeKitProductID ?? "<missing vendor>",
                cycleInMonths: monthlyInstance.instance.cycle,
                pricing: .discountedMonthlyPlan(
                    discountedPrice: formatPrice(discountedMonthlyPrice, using: specialPriceFormat),
                    renewalPrice: formatPrice(monthlyPrice, using: priceFormatStyle)
                ),
                discount: wave.discount
            )
        }
    }

    private func findInstanceAndUSDPrice(forCycle cycle: Int, among availablePlans: [ComposedPlan]) -> (ComposedPlan, Int)? {
        guard
            let instance = availablePlans.first(where: { $0.instance.cycle == cycle }),
            let price = instance.instance.price.first(where: { $0.currency == "USD" })
        else {
            return nil
        }

        return (instance, price.current)
    }

    private func formatPrice(_ price: Int, using formatStyle: Decimal.FormatStyle.Currency) -> String {
        formatStyle.format(Decimal(price) / 100)
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

private extension BlackFridayWave {
    var discountFactor: Int {
        switch self {
        case .wave1:
            2
        case .wave2:
            5
        }
    }

    var discount: Int {
        .init((1 - 1 / Double(discountFactor)) * 100)
    }
}

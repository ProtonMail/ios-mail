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

import ProtonCorePayments
import ProtonMailUI

struct UpsellPageFactory {
    typealias Dependencies = AnyObject & HasStoreKitManagerProtocol

    private unowned let dependencies: Dependencies

    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    // product team decided to replace the dynamic list of all entitlements with these most important ones
    private let hardCodedPerks: [UpsellPageModel.Perk] = [
        .init(icon: \.storage, description: L10n.PremiumPerks.storage),
        .init(icon: \.inbox, description: String(format: L10n.PremiumPerks.emailAddresses, 10)),
        .init(icon: \.globe, description: L10n.PremiumPerks.customEmailDomain),
        .init(icon: \.rocket, description: L10n.PremiumPerks.desktopApp),
        .init(icon: \.tag, description: L10n.Snooze.folderBenefit)
    ]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    @MainActor
    func makeUpsellPageModel(for plan: AvailablePlans.AvailablePlan) -> UpsellPageModel {
        let storeKitManager = dependencies.storeKitManager

        let billingCycles: [SubscriptionBillingCycle] = plan.instances.compactMap { instance in
            guard
                let iapPlan = InAppPurchasePlan(availablePlanInstance: instance),
                let priceLabel = iapPlan.priceLabel(from: storeKitManager),
                let storeKitProductId = iapPlan.storeKitProductId
            else {
                return nil
            }

            let monthlyPrice = priceLabel.value.doubleValue / Double(instance.cycle)

            priceFormatter.locale = priceLabel.locale

            guard let formattedMonthlyPrice = priceFormatter.string(from: NSNumber(value: monthlyPrice)) else {
                return nil
            }

            return .init(
                months: instance.cycle,
                monthlyPrice: monthlyPrice,
                formattedMonthlyPrice: formattedMonthlyPrice,
                storeKitProductId: storeKitProductId
            )
        }

        let mostExpensiveCycle = billingCycles.max { $0.monthlyPrice < $1.monthlyPrice }

        let purchasingOptions: [UpsellPageModel.PurchasingOption] = billingCycles.map { billingCycle in
            let discount: Int?
            if let mostExpensiveCycle, billingCycle != mostExpensiveCycle {
                discount = billingCycle.discount(comparedTo: mostExpensiveCycle)
            } else {
                discount = nil
            }

            return .init(
                identifier: billingCycle.storeKitProductId,
                cycleInMonths: billingCycle.months,
                monthlyPrice: billingCycle.formattedMonthlyPrice,
                isHighlighted: discount != nil,
                discount: discount
            )
        }

        return .init(
            plan: .init(
                name: plan.title,
                perks: hardCodedPerks,
                purchasingOptions: purchasingOptions
            )
        )
    }
}

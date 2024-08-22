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

struct OnboardingUpsellPageFactory {
    typealias Dependencies = AnyObject & HasUpsellPageFactory

    private unowned let dependencies: Dependencies

    private let unlimitedPlanPerks: [UpsellPageModel.Perk] = [
        .init(icon: \.storage, description: "Up to 500 GB of storage"),
        .init(icon: \.storage, description: "Up to 500 GB of storage"),
        .init(icon: \.storage, description: "Up to 500 GB of storage"),
        .init(icon: \.storage, description: "Up to 500 GB of storage"),
        .init(icon: \.storage, description: "Up to 500 GB of storage"),
        .init(icon: \.storage, description: "Up to 500 GB of storage")
    ]

    private let plusPlanPerks: [UpsellPageModel.Perk] = [
        .init(icon: \.storage, description: L10n.PremiumPerks.storage),
        .init(icon: \.inbox, description: String(format: L10n.PremiumPerks.emailAddresses, 10)),
        .init(icon: \.globe, description: L10n.PremiumPerks.customEmailDomain)
    ]

    private let freePlanPerks: [UpsellPageModel.Perk] = [
        .init(icon: \.storage, description: "1 GB Storage and 1 email")
    ]

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    @MainActor
    func makeOnboardingUpsellPageModel(for plans: [AvailablePlans.AvailablePlan]) -> OnboardingUpsellPageModel {
        let upsellPageModels: [UpsellPageModel] = plans.map {
            dependencies.upsellPageFactory.makeUpsellPageModel(for: $0)
        }

        let tiles: [OnboardingUpsellPageModel.TileModel] = upsellPageModels.compactMap { upsellPageModel in
            let plan = upsellPageModel.plan
            let isUnlimited = plan.name.lowercased().contains("unlimited")

            let monthlyPricesPerCycle: [Int: String] = plan.purchasingOptions.reduce(into: [:]) { acc, element in
                acc[element.cycleInMonths] = element.monthlyPrice
            }

            let storeKitProductIDsPerCycle: [Int: String] = plan.purchasingOptions.reduce(into: [:]) { acc, element in
                acc[element.cycleInMonths] = element.identifier
            }

            let billingPricesPerCycle: [Int: String] = plan.purchasingOptions.reduce(into: [:]) { acc, element in
                acc[element.cycleInMonths] = element.billingPrice
            }

            return .init(
                planName: plan.name,
                perks: isUnlimited ? unlimitedPlanPerks : plusPlanPerks,
                monthlyPricesPerCycle: monthlyPricesPerCycle,
                isBestValue: isUnlimited,
                alwaysVisiblePerks: isUnlimited ? 3 : 2,
                storeKitProductIDsPerCycle: storeKitProductIDsPerCycle,
                billingPricesPerCycle: billingPricesPerCycle
            )
        }

        let freePlanTile = OnboardingUpsellPageModel.TileModel(
            planName: "Proton Free",
            perks: freePlanPerks,
            monthlyPricesPerCycle: [:],
            isBestValue: false,
            alwaysVisiblePerks: 1,
            storeKitProductIDsPerCycle: [:],
            billingPricesPerCycle: [:]
        )

        let maxDiscount = upsellPageModels.flatMap(\.plan.purchasingOptions).compactMap(\.discount).max()

        return OnboardingUpsellPageModel(tiles: tiles + [freePlanTile], maxDiscount: maxDiscount)
    }
}

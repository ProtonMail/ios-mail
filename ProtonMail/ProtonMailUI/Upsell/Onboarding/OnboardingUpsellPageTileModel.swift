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

import ProtonCoreDataModel
import ProtonCoreUIFoundations
import SwiftUI

extension OnboardingUpsellPageModel {
    public struct TileModel: Equatable {
        let planName: String
        let perks: [UpsellPageModel.Perk]
        let monthlyPricesPerCycle: [Int: String]
        let isBestValue: Bool
        let maxDiscount: Int?
        let alwaysVisiblePerks: Int
        let storeKitProductIDsPerCycle: [Int: String]
        let billingPricesPerCycle: [Int: String]
        let includedProducts: [ClientApp]?
        var isExpanded: Bool

        var showExpandButton: Bool {
            perks.count > alwaysVisiblePerks
        }

        var expandButtonIcon: Image {
            isExpanded ? IconProvider.chevronUp : IconProvider.chevronDown
        }

        var visiblePerks: [UpsellPageModel.Perk] {
            isExpanded ? perks : Array(perks.prefix(alwaysVisiblePerks))
        }

        var nMoreFeaturesLabel: String {
            String(format: L10n.Upsell.nMoreFeatures, perks.count - alwaysVisiblePerks)
        }

        public init(
            planName: String,
            perks: [UpsellPageModel.Perk],
            monthlyPricesPerCycle: [Int: String],
            isBestValue: Bool,
            maxDiscount: Int?,
            alwaysVisiblePerks: Int,
            storeKitProductIDsPerCycle: [Int: String],
            billingPricesPerCycle: [Int: String],
            includedProducts: [ClientApp]?
        ) {
            self.planName = planName
            self.perks = perks
            self.monthlyPricesPerCycle = monthlyPricesPerCycle
            self.isBestValue = isBestValue
            self.maxDiscount = maxDiscount
            self.alwaysVisiblePerks = alwaysVisiblePerks
            self.storeKitProductIDsPerCycle = storeKitProductIDsPerCycle
            self.billingPricesPerCycle = billingPricesPerCycle
            self.includedProducts = includedProducts

            isExpanded = false
        }

        func monthlyPriceBeforeDiscount(cycle: OnboardingUpsellPageModel.Cycle) -> String? {
            switch cycle {
            case .monthly:
                return nil
            case .annual:
                return monthlyPricesPerCycle[1]
            }
        }

        func monthlyPriceAfterDiscount(cycle: OnboardingUpsellPageModel.Cycle) -> String? {
            monthlyPricesPerCycle[cycle.lengthInMonths]
        }
    }
}

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
import ProtonCorePayments
import ProtonCorePaymentsUI
import ProtonMailUI

struct OnboardingUpsellPageFactory {
    typealias Dependencies = AnyObject & HasUpsellPageFactory

    private unowned let dependencies: Dependencies

    private let unlimitedPlanPerks: [UpsellPageModel.Perk] = [
        .init(
            icon: \.storage,
            description: String(
                format: PUITranslations.plan_details_storage.l10n,
                Measurement<UnitInformationStorage>(value: 500, unit: .gigabytes).formatted()
            )
        ),
        .init(icon: \.lock, description: L10n.PremiumPerks.endToEndEncryption),
        .init(icon: \.envelope, description: String(format: PUITranslations.plan_details_n_addresses.l10n, 15)),
        .init(icon: \.globe, description: String(format: PUITranslations._details_n_custom_email_domains.l10n, 3)),
        .init(icon: \.tag, description: PUITranslations._details_unlimited_folders_labels_filters.l10n),
        .init(icon: \.calendarCheckmark, description: String(format: L10n.PremiumPerks.personalCalendars, 25)),
        .init(icon: \.shield, description: String(format: PUITranslations._details_vpn_on_n_devices.l10n, 10))
    ]

    private let plusPlanPerks: [UpsellPageModel.Perk] = [
        .init(icon: \.storage, description: L10n.PremiumPerks.storage),
        .init(icon: \.lock, description: L10n.PremiumPerks.endToEndEncryption),
        .init(icon: \.envelope, description: String(format: PUITranslations.plan_details_n_addresses.l10n, 10)),
        .init(icon: \.globe, description: String(format: PUITranslations._details_n_custom_email_domains.l10n, 1)),
        .init(icon: \.tag, description: PUITranslations._details_unlimited_folders_labels_filters.l10n),
        .init(icon: \.calendarCheckmark, description: String(format: L10n.PremiumPerks.personalCalendars, 25))
    ]

    private let freePlanPerks: [UpsellPageModel.Perk] = [
        .init(icon: \.storage, description: L10n.PremiumPerks.freePlanPerk),
        .init(icon: \.lock, description: L10n.PremiumPerks.endToEndEncryption)
    ]

    private var unlimitedPlanProducts: [ClientApp] {
        plusPlanProducts + [.drive, .vpn, .pass]
    }

    private var plusPlanProducts: [ClientApp] {
        [.mail, .calendar]
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    @MainActor
    func makeOnboardingUpsellPageModel(for plans: [AvailablePlans.AvailablePlan]) -> OnboardingUpsellPageModel {
        let upsellPageModels: [UpsellPageModel] = plans.map {
            dependencies.upsellPageFactory.makeUpsellPageModel(for: $0, entryPoint: .postOnboarding)
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

            let maxDiscount = plan.purchasingOptions.compactMap(\.discount).max()

            return .init(
                planName: plan.name,
                perks: isUnlimited ? unlimitedPlanPerks : plusPlanPerks,
                monthlyPricesPerCycle: monthlyPricesPerCycle,
                isBestValue: isUnlimited,
                maxDiscount: maxDiscount,
                alwaysVisiblePerks: isUnlimited ? 4 : 3,
                storeKitProductIDsPerCycle: storeKitProductIDsPerCycle,
                billingPricesPerCycle: billingPricesPerCycle,
                includedProducts: isUnlimited ? unlimitedPlanProducts : plusPlanProducts
            )
        }

        let freePlanTile = OnboardingUpsellPageModel.TileModel(
            planName: "Proton Free",
            perks: freePlanPerks,
            monthlyPricesPerCycle: [:],
            isBestValue: false,
            maxDiscount: nil,
            alwaysVisiblePerks: 2,
            storeKitProductIDsPerCycle: [:],
            billingPricesPerCycle: [:],
            includedProducts: nil
        )

        return OnboardingUpsellPageModel(tiles: tiles + [freePlanTile])
    }
}

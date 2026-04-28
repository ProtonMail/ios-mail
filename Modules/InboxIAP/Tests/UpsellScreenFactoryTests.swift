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

import PaymentsNG
import StoreKit
import Testing
import proton_app_uniffi

@testable import InboxIAP

@MainActor
final class UpsellScreenFactoryTests {
    private lazy var sut = UpsellScreenFactory(purchaseActionPerformer: .dummy)
    private let availablePlans = [AvailablePlan.mailPlus, .unlimited].flatMap(\.asComposedPlans)
    private let configuration = UpsellConfiguration.dummy
    private let entryPoint: UpsellEntryPoint = .mailboxTopBar

    @Test
    func upsellScreenModelGeneration() throws {
        let upsellScreenModel = try sut.upsellScreenModel(
            showingPlan: SubscriptionPlanVariant.plus,
            basedOn: availablePlans,
            entryPoint: entryPoint,
            upsellType: .mailPlus
        )

        #expect(upsellScreenModel.planName == "Mail Plus")
        #expect(upsellScreenModel.planInstances == DisplayablePlanInstance.previews)
    }

    @Test
    func yearlyMailPlusInstanceCarriesYearlyTotalAndMonthlyEquivalent() throws {
        let upsellScreenModel = try sut.upsellScreenModel(
            showingPlan: SubscriptionPlanVariant.plus,
            basedOn: availablePlans,
            entryPoint: entryPoint,
            upsellType: .mailPlus
        )

        let yearlyInstance = try #require(upsellScreenModel.planInstances.first { $0.cycleInMonths == 12 })

        #expect(yearlyInstance.pricing == .discountedYearlyPlan(
            discountedMonthlyPrice: "$3.99",
            discountedYearlyPrice: "$47.88",
            renewalPrice: "$47.88"
        ))
    }

    @Test
    func monthlyMailPlusInstanceUsesRegularPricing() throws {
        let upsellScreenModel = try sut.upsellScreenModel(
            showingPlan: SubscriptionPlanVariant.plus,
            basedOn: availablePlans,
            entryPoint: entryPoint,
            upsellType: .mailPlus
        )

        let monthlyInstance = try #require(upsellScreenModel.planInstances.first { $0.cycleInMonths == 1 })

        #expect(monthlyInstance.pricing == .regular(monthlyPrice: "$4.99"))
    }

    @Test
    func unlimitedUpsellScreenModelGeneration() throws {
        let upsellScreenModel = try sut.upsellScreenModel(
            showingPlan: SubscriptionPlanVariant.unlimited,
            basedOn: availablePlans,
            entryPoint: entryPoint,
            upsellType: .unlimited
        )

        #expect(upsellScreenModel.planName == "Proton Unlimited")
    }

    @Test
    func yearlyUnlimitedInstanceCarriesYearlyTotalAndMonthlyEquivalent() throws {
        let upsellScreenModel = try sut.upsellScreenModel(
            showingPlan: SubscriptionPlanVariant.unlimited,
            basedOn: availablePlans,
            entryPoint: entryPoint,
            upsellType: .unlimited
        )

        let yearlyInstance = try #require(upsellScreenModel.planInstances.first { $0.cycleInMonths == 12 })

        #expect(yearlyInstance.pricing == .discountedYearlyPlan(
            discountedMonthlyPrice: "$9.99",
            discountedYearlyPrice: "$119.88",
            renewalPrice: "$119.88"
        ))
    }

    @Test
    func onboardingUpsellScreenModelGeneration() throws {
        let upsellScreenModel = try sut.onboardingUpsellScreenModel(
            showingPlans: configuration.onboardingPlans,
            basedOn: availablePlans
        )

        let expectedPlanTiles: [PlanTileData] = [
            PlanTileData.previews[0],
            PlanTileData.previews[2],
            PlanTileData.previews[4],
        ]

        #expect(upsellScreenModel.visiblePlanTiles.map(\.planTileData) == expectedPlanTiles)
    }
}

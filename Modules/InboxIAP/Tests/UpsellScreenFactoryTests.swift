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

@testable import InboxIAP

@MainActor
final class UpsellScreenFactoryTests {
    private lazy var sut = UpsellScreenFactory(planPurchasing: DummyPlanPurchasing())
    private let availablePlans = [AvailablePlan.mailPlus, .unlimited].flatMap(\.asComposedPlans)

    @Test
    func upsellScreenModelGeneration() throws {
        let upsellScreenModel = try sut.upsellScreenModel(
            showingPlan: "mail2022",
            basedOn: availablePlans,
            entryPoint: .header
        )

        #expect(upsellScreenModel.planName == "Mail Plus")
        #expect(upsellScreenModel.planInstances == DisplayablePlanInstance.previews)
    }

    @Test
    func onboardingUpsellScreenModelGeneration() throws {
        let upsellScreenModel = try sut.onboardingUpsellScreenModel(
            showingPlans: ["bundle2022", "mail2022"],
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

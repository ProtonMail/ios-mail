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
import Testing

@testable import InboxIAP

final class UpsellOfferProviderTests {
    private let plansComposer = PlansComposerSpy()
    private lazy var sut = UpsellOfferProvider(plansComposer: plansComposer)

    @Test
    func offerOnlyContainsComposedPlansForInstancesOfTheRequestedPlan() async throws {
        plansComposer.stubbedAvailablePlans = [AvailablePlan.mailPlus, .unlimited].flatMap(\.asComposedPlans)

        try await #expect(sut.findOffer(for: "mail2022") == .init(composedPlans: AvailablePlan.mailPlus.asComposedPlans))
        try await #expect(sut.findOffer(for: "bundle2022") == .init(composedPlans: AvailablePlan.unlimited.asComposedPlans))
    }

    @Test
    func doesNotReturnEmptyOffers() async {
        plansComposer.stubbedAvailablePlans = []

        await #expect(throws: UpsellOfferProviderError.self) {
            try await sut.findOffer(for: "mail2022")
        }
    }
}

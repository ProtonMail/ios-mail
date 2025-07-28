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

import Foundation
@preconcurrency import PaymentsNG
import proton_app_uniffi

final class UpsellOfferProvider {
    private let plansComposer: PlansComposerProviding

    init(plansComposer: PlansComposerProviding) {
        self.plansComposer = plansComposer
    }

    func findOffer(for planName: String) async throws -> UpsellOffer {
        let availableComposedPlans = try await plansComposer.fetchAvailablePlans()
        let composedPlanToUpsell = availableComposedPlans.filter { $0.plan.name == planName }

        guard !composedPlanToUpsell.isEmpty else {
            throw UpsellOfferProviderError.planNotFound
        }

        return .init(composedPlans: composedPlanToUpsell)
    }
}

enum UpsellOfferProviderError: LocalizedError {
    case planNotFound

    var errorDescription: String? {
        switch self {
        case .planNotFound:
            L10n.Error.planNotFound.string
        }
    }
}

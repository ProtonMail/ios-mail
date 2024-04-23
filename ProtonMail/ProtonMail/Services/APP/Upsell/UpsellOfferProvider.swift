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

import Combine
import ProtonCorePayments

final class UpsellOfferProvider {
    typealias Dependencies = AnyObject & HasPayments

    @Published var availablePlan: AvailablePlans.AvailablePlan?

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func update() async throws {
        availablePlan = try await findPlanToOffer()
    }

    private func findPlanToOffer() async throws -> AvailablePlans.AvailablePlan? {
        let plansDataSource: PlansDataSourceProtocol
        switch dependencies.payments.planService {
        case .left:
            return nil
        case .right(let pdsp):
            plansDataSource = pdsp
        }

        try await plansDataSource.fetchAvailablePlans()

        return plansDataSource.availablePlans?.plans.first { $0.name == "mail2022" }
    }
}

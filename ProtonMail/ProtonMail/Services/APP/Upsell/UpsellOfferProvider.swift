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

protocol UpsellOfferProvider {
    var availablePlan: AvailablePlans.AvailablePlan? { get }

    // remove this if Swift ever supports property wrappers in protocols
    var availablePlanPublisher: Published<AvailablePlans.AvailablePlan?>.Publisher { get }

    func update() async throws
}

final class UpsellOfferProviderImpl: UpsellOfferProvider {
    typealias Dependencies = AnyObject & HasPlanService

    @Published private(set) var availablePlan: AvailablePlans.AvailablePlan?

    var availablePlanPublisher: Published<AvailablePlans.AvailablePlan?>.Publisher {
        $availablePlan
    }

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func update() async throws {
        availablePlan = try await findPlanToOffer()
    }

    private func findPlanToOffer() async throws -> AvailablePlans.AvailablePlan? {
        let plansDataSource: PlansDataSourceProtocol
        switch dependencies.planService {
        case .left:
            return nil
        case .right(let pdsp):
            plansDataSource = pdsp
        }

        try await plansDataSource.fetchAvailablePlans()

        if let availablePlans = plansDataSource.availablePlans, !availablePlans.plans.isEmpty {
            /*
             knowing the current plan is not necessary for the upsell itself (yet), but we must know it for telemetry
             purposes for when the user taps the upsell button
             */
            try await plansDataSource.fetchCurrentPlan()
            try await plansDataSource.fetchIAPAvailability()
        }

        return plansDataSource.availablePlans?.plans.first { $0.name == "mail2022" }
    }
}

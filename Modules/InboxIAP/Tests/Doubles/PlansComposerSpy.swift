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

final class PlansComposerSpy: PlansComposerProviding {
    var stubbedAvailablePlans: [ComposedPlan] = []

    private(set) var fetchAvailablePlansCalls = 0

    var hasData: Bool {
        fatalError(#function)
    }

    func getStoreProducts(_ plans: [String]) async throws -> [Product] {
        fatalError(#function)
    }

    func fetchProtonPlans() async throws -> AvailablePlans {
        fatalError(#function)
    }

    func matchPlanToStoreProduct(_ productId: String) -> ComposedPlan? {
        fatalError(#function)
    }

    func fetchAvailablePlans() async throws -> [ComposedPlan] {
        fetchAvailablePlansCalls += 1
        return stubbedAvailablePlans
    }

    func updateRemoteManager(remoteManager: any RemoteManagerProviding) {
        fatalError(#function)
    }

    func fetchCurrentSubscription() async throws -> CurrentSubscriptionResponse {
        fatalError(#function)
    }
}

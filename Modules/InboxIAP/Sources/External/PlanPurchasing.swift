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
import PaymentsNG

protocol PlanPurchasing {
    func purchase(storeKitProductId: String) async throws
}

extension ProtonPlansManager: PlanPurchasing {
    func purchase(storeKitProductId: String) async throws {
        _ = try await purchase(productId: storeKitProductId)
    }
}

struct DummyPlanPurchasing: PlanPurchasing {
    func purchase(storeKitProductId: String) async throws {
        try? await Task.sleep(for: .seconds(0.25))
        throw IAPsNotAvailableInTestFlightError()
    }
}

struct IAPsNotAvailableInTestFlightError: LocalizedError {
    var errorDescription: String? {
        "In-app purchases are not available in TestFlight builds.".notLocalized
    }
}

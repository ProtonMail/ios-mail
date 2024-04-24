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

import ProtonCorePayments
import ProtonCoreTestingToolkit

final class MockPlansDataSourceProtocol: PlansDataSourceProtocol {
    var isIAPAvailable: Bool {
        fatalError("not implemented")
    }

    var availablePlans: AvailablePlans? {
        fatalError("not implemented")
    }

    @PropertyStub(\MockPlansDataSourceProtocol.currentPlan, initialGet: nil) var currentPlanStub
    var currentPlan: CurrentPlan? {
        currentPlanStub()
    }

    var paymentMethods: [PaymentMethod]? {
        fatalError("not implemented")
    }

    var willRenewAutomatically: Bool {
        fatalError("not implemented")
    }

    var hasPaymentMethods: Bool {
        fatalError("not implemented")
    }

    func fetchIAPAvailability() async throws {
        fatalError("not implemented")
    }

    func fetchAvailablePlans() async throws {
        fatalError("not implemented")
    }

    func fetchCurrentPlan() async throws {
        fatalError("not implemented")
    }

    func fetchPaymentMethods() async throws {
        fatalError("not implemented")
    }

    func createIconURL(iconName: String) -> URL? {
        fatalError("not implemented")
    }

    func detailsOfAvailablePlanCorrespondingToIAP(_ iap: InAppPurchasePlan) -> AvailablePlans.AvailablePlan? {
        fatalError("not implemented")
    }

    func detailsOfAvailablePlanInstanceCorrespondingToIAP(_ iap: InAppPurchasePlan) -> AvailablePlans.AvailablePlan.Instance? {
        fatalError("not implemented")
    }
}

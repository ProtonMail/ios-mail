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

import InboxCoreUI
import Testing

@testable import InboxIAP

@MainActor
final class OnboardingUpsellScreenModelTests {
    private let planPurchasing = PlanPurchasingSpy()
    private let toastStateStore = ToastStateStore(initialState: .initial)

    private lazy var sut = OnboardingUpsellScreenModel(
        planTiles: PlanTileData.previews,
        purchaseActionPerformer: .init(
            eventLoopPolling: DummyEventLoopPolling(),
            planPurchasing: planPurchasing,
            telemetryReporting: DummyTelemetryReporting()
        )
    )

    @Test
    func onlyShowsTilesForPlanInstancesMatchingSelectedCycle() {
        sut.selectedCycle = .monthly

        #expect(Set(sut.visiblePlanTiles.map(\.cycleInMonths)) == [1])

        sut.selectedCycle = .yearly

        #expect(Set(sut.visiblePlanTiles.map(\.cycleInMonths)) == [12])
    }

    @Test
    func whenGetFreePlanIsTapped_dismissesTheScreen() async {
        await confirmation(expectedCount: 1) { dismissCalled in
            await sut.onGetPlanTapped(storeKitProductID: nil, toastStateStore: toastStateStore) {
                dismissCalled()
            }
        }

        #expect(planPurchasing.purchaseInvocations.count == 0)
    }

    @Test
    func whenGetPaidPlanIsTapped_initiatesTransaction() async {
        await sut.onGetPlanTapped(storeKitProductID: "foo", toastStateStore: toastStateStore) {}

        #expect(planPurchasing.purchaseInvocations.count == 1)
    }
}

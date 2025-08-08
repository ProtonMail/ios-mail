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

import CoreGraphics
import InboxCoreUI
import PaymentsNG
import Testing

@testable import InboxIAP

@MainActor
final class UpsellScreenModelTests {
    private let planPurchasing = PlanPurchasingSpy()
    private let toastStateStore = ToastStateStore(initialState: .initial)

    private lazy var sut = UpsellScreenModel(
        planName: "foo",
        planInstances: DisplayablePlanInstance.previews,
        entryPoint: .header,
        planPurchasing: planPurchasing
    )

    @Test(
        arguments: [
            VerticalScrollingTestCase(verticalOffset: -5, expectedLogoScaleFactor: 1, expectedLogoOpacity: 1),
            VerticalScrollingTestCase(verticalOffset: 0, expectedLogoScaleFactor: 1, expectedLogoOpacity: 1),
            VerticalScrollingTestCase(verticalOffset: 59, expectedLogoScaleFactor: 0.9, expectedLogoOpacity: 0.6),
            VerticalScrollingTestCase(verticalOffset: 118, expectedLogoScaleFactor: 0.8, expectedLogoOpacity: 0.2),
            VerticalScrollingTestCase(verticalOffset: 300, expectedLogoScaleFactor: 0.8, expectedLogoOpacity: 0.2),
        ]
    )
    func updatesLogoScaleAndOpacityBasedOnScrollingOffset(testCase: VerticalScrollingTestCase) {
        sut.scrollingOffsetDidChange(newValue: testCase.verticalOffset)

        #expect(sut.logoScaleFactor.isNearlyEqual(to: testCase.expectedLogoScaleFactor))
        #expect(sut.logoOpacity.isNearlyEqual(to: testCase.expectedLogoOpacity))
    }

    @Test
    func whenPurchaseButtonIsTapped_initiatesTransaction() async {
        await sut.onPurchaseTapped(toastStateStore: toastStateStore) {}

        #expect(planPurchasing.purchaseInvocations.count == 1)
    }

    @Test
    func whenTransactionIsSuccessful_dismissesTheScreen() async {
        await confirmation(expectedCount: 1) { dismissCalled in
            await sut.onPurchaseTapped(toastStateStore: toastStateStore) {
                dismissCalled()
            }
        }
    }

    @Test
    func whenTransactionFails_showsErrorAndDoesNotDismissTheScreen() async {
        planPurchasing.stubbedError = ProtonPlansManagerError.transactionUnknownError

        await confirmation(expectedCount: 0) { dismissCalled in
            await sut.onPurchaseTapped(toastStateStore: toastStateStore) {
                dismissCalled()
            }
        }

        #expect(toastStateStore.state.toasts.count == 1)
    }

    @Test
    func whenTransactionIsCancelledByUser_doesNotShowErrorAndDoesNotDismissTheScreen() async {
        planPurchasing.stubbedError = ProtonPlansManagerError.transactionCancelledByUser

        await confirmation(expectedCount: 0) { dismissCalled in
            await sut.onPurchaseTapped(toastStateStore: toastStateStore) {
                dismissCalled()
            }
        }

        #expect(toastStateStore.state.toasts == [])
    }
}

struct VerticalScrollingTestCase {
    let verticalOffset: CGFloat
    let expectedLogoScaleFactor: CGFloat
    let expectedLogoOpacity: CGFloat
}

private extension FloatingPoint {
    func isNearlyEqual(to value: Self) -> Bool {
        abs(self - value) <= .ulpOfOne
    }
}

private final class PlanPurchasingSpy: PlanPurchasing {
    var stubbedError: Error?

    private(set) var purchaseInvocations: [String] = []

    func purchase(storeKitProductId: String) async throws {
        purchaseInvocations.append(storeKitProductId)

        if let stubbedError {
            throw stubbedError
        }
    }
}

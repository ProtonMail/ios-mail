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
import Foundation
import InboxCoreUI
import proton_app_uniffi
import Testing

@testable import InboxIAP

@MainActor
final class UpsellScreenModelTests {
    private let planPurchasing = PlanPurchasingSpy()
    private let sessionForking = SessionForkingSpy()
    private let toastStateStore = ToastStateStore(initialState: .initial)

    @Test(
        arguments: [
            VerticalScrollingTestCase(verticalOffset: -5, expectedLogoScaleFactor: 1, expectedLogoOpacity: 1),
            VerticalScrollingTestCase(verticalOffset: 0, expectedLogoScaleFactor: 1, expectedLogoOpacity: 1),
            VerticalScrollingTestCase(verticalOffset: 75, expectedLogoScaleFactor: 0.9, expectedLogoOpacity: 0.6),
            VerticalScrollingTestCase(verticalOffset: 150, expectedLogoScaleFactor: 0.8, expectedLogoOpacity: 0.2),
            VerticalScrollingTestCase(verticalOffset: 300, expectedLogoScaleFactor: 0.8, expectedLogoOpacity: 0.2),
        ]
    )
    func updatesLogoScaleAndOpacityBasedOnScrollingOffset(testCase: VerticalScrollingTestCase) {
        let sut = makeSUT()

        sut.scrollingOffsetDidChange(newValue: testCase.verticalOffset)

        #expect(sut.logoScaleFactor.isNearlyEqual(to: testCase.expectedLogoScaleFactor))
        #expect(sut.logoOpacity.isNearlyEqual(to: testCase.expectedLogoOpacity))
    }

    @Test
    func givenNoPromo_whenPurchaseButtonIsTapped_thenInitiatesDirectPurchase() async {
        let sut = makeSUT()

        await sut.onPurchaseTapped(toastStateStore: toastStateStore, openURL: { _ in }, dismiss: {})

        #expect(planPurchasing.purchaseInvocations.count == 1)
        #expect(sessionForking.forkCalls == 0)
    }

    @Test
    func givenThereIsPromo_whenPurchaseButtonIsTapped_thenInitiatesWebCheckoutAndDismisses() async {
        let sut = makeSUT(upsellType: .blackFriday(.wave2))
        let expectedWebCheckoutURL = URL(
            string: """
                https://account.example.com/lite?action=subscribe-account&app-version=ios-mail@16.0&coupon=BF25PROMO1M&currency=USD&cycle=1&disableCycleSelector=1&disablePlanSelection=1&fullscreen=auto&hideClose=true&plan=mail2022&redirect=protonmail://&start=checkout#selector=FORK_SELECTOR
                """
        )

        await confirmation(expectedCount: 1) { openURLCalled in
            await confirmation(expectedCount: 1) { dismissCalled in
                await sut.onPurchaseTapped(
                    toastStateStore: toastStateStore,
                    openURL: { webCheckoutURL in
                        #expect(webCheckoutURL == expectedWebCheckoutURL)
                        openURLCalled()

                    },
                    dismiss: { dismissCalled() }
                )
            }
        }

        #expect(planPurchasing.purchaseInvocations == [])
        #expect(sessionForking.forkCalls == 1)
    }

    private func makeSUT(upsellType: UpsellType = .standard) -> UpsellScreenModel {
        .init(
            planName: "foo",
            planInstances: DisplayablePlanInstance.previews,
            entryPoint: .mailboxTopBar,
            upsellType: upsellType,
            purchaseActionPerformer: .init(
                eventLoopPolling: DummyEventLoopPolling(),
                planPurchasing: planPurchasing
            ),
            webCheckout: .init(sessionForking: sessionForking, upsellConfiguration: .dummy)
        )
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

private final class SessionForkingSpy: SessionForking {
    private(set) var forkCalls = 0

    func fork(platform: String, product: String) async -> MailUserSessionForkResult {
        forkCalls += 1
        return .ok("FORK_SELECTOR")
    }
}

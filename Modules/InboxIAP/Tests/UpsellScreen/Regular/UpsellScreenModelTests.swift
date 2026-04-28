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
import ProtonUIFoundations
import Testing
import proton_app_uniffi

@testable import InboxIAP

@MainActor
final class UpsellScreenModelTests {
    private let planPurchasing = PlanPurchasingSpy()
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
    }

    @Test
    func mailPlusLogoComesFromEntryPoint() {
        let sut = makeSUT(upsellType: .mailPlus)
        #expect(sut.logo == UpsellEntryPoint.mailboxTopBar.logo)
    }

    @Test
    func unlimitedLogoComesFromUpsellType() {
        let sut = makeSUT(upsellType: .unlimited)
        #expect(sut.logo == UpsellType.unlimited.logo)
    }

    @Test
    func mailPlusComparisonConfigurationHasSixItems() {
        let sut = makeSUT(upsellType: .mailPlus)
        #expect(sut.comparisonConfiguration.items.count == 6)
    }

    @Test
    func unlimitedComparisonConfigurationHasEightItems() {
        let sut = makeSUT(upsellType: .unlimited)
        #expect(sut.comparisonConfiguration.items.count == 8)
    }

    @Test
    func autoRenewalNoticeShowsYearlyTotalWhenYearlyPlanSelected() throws {
        let sut = makeSUT()
        let yearlyInstance = try #require(DisplayablePlanInstance.previews.first { $0.cycleInMonths == 12 })

        sut.selectedInstanceId = yearlyInstance.storeKitProductId

        #expect(String(localized: sut.autoRenewalNotice) == "Auto-renews at $47.88/year unless canceled")
    }

    @Test
    func autoRenewalNoticeShowsMonthlyPriceWhenMonthlyPlanSelected() throws {
        let sut = makeSUT()
        let monthlyInstance = try #require(DisplayablePlanInstance.previews.first { $0.cycleInMonths == 1 })

        sut.selectedInstanceId = monthlyInstance.storeKitProductId

        #expect(String(localized: sut.autoRenewalNotice) == "Auto-renews at $4.99/month unless canceled")
    }

    @Test
    func autoRenewalNoticeUpdatesWhenSelectionChanges() throws {
        let sut = makeSUT()
        let yearlyId = try #require(DisplayablePlanInstance.previews.first { $0.cycleInMonths == 12 }).storeKitProductId
        let monthlyId = try #require(DisplayablePlanInstance.previews.first { $0.cycleInMonths == 1 }).storeKitProductId

        sut.selectedInstanceId = yearlyId
        let yearlyNotice = String(localized: sut.autoRenewalNotice)

        sut.selectedInstanceId = monthlyId
        let monthlyNotice = String(localized: sut.autoRenewalNotice)

        #expect(yearlyNotice.contains("/year"))
        #expect(monthlyNotice.contains("/month"))
        #expect(yearlyNotice != monthlyNotice)
    }

    private func makeSUT(upsellType: UpsellType = .mailPlus) -> UpsellScreenModel {
        .init(
            planName: "foo",
            planInstances: DisplayablePlanInstance.previews,
            entryPoint: .mailboxTopBar,
            upsellType: upsellType,
            purchaseActionPerformer: .init(
                eventLoopPolling: DummyEventLoopPolling(),
                planPurchasing: planPurchasing,
                telemetryReporting: DummyTelemetryReporting(),
                userAttributionService: .dummy
            )
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
        return .ok(Fork(selector: "FORK_SELECTOR", id: .empty))
    }
}

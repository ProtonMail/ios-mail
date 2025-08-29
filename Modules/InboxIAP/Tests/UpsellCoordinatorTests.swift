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
import proton_app_uniffi
import Testing

@testable import InboxIAP

@MainActor
final class UpsellCoordinatorTests {
    private let onlineExecutor = OnlineExecutorDummy()
    private let plansComposer = PlansComposerSpy()
    private let telemetryReporting = TelemetryReportingSpy()
    private let sut: UpsellCoordinator

    init() {
        sut = UpsellCoordinator(
            eventLoopPolling: DummyEventLoopPolling(),
            onlineExecutor: onlineExecutor,
            plansComposer: plansComposer,
            planPurchasing: DummyPlanPurchasing(),
            sessionForking: DummySessionForking(),
            telemetryReporting: telemetryReporting,
            configuration: .dummy
        )

        plansComposer.stubbedAvailablePlans = [AvailablePlan.mailPlus, .unlimited].flatMap(\.asComposedPlans)
    }

    @Test(arguments: [true, false])
    func cachesPlansBetweenSubsequentCalls(prewarm: Bool) async throws {
        #expect(plansComposer.fetchAvailablePlansCalls == 0)

        if prewarm {
            await sut.prewarm()

            #expect(plansComposer.fetchAvailablePlansCalls == 1)
        }

        _ = try await sut.presentUpsellScreen(entryPoint: .mailboxTopBar)
        _ = try await sut.presentOnboardingUpsellScreen()

        #expect(plansComposer.fetchAvailablePlansCalls == 1)
    }

    @Test
    func considersReturningScreenModelAsPresentingTheScreen() async throws {
        _ = try await self.sut.presentUpsellScreen(entryPoint: .mailboxTopBar)
        #expect(telemetryReporting.upsellButtonTappedCalls == 1)
    }
}

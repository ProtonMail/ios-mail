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
import InboxCore
import PaymentsNG
import proton_app_uniffi

@MainActor
public final class UpsellCoordinator: ObservableObject {
    private let onlineExecutor: OnlineExecutor
    private let plansComposer: PlansComposerProviding
    private let upsellScreenFactory: UpsellScreenFactory
    private let configuration: UpsellConfiguration

    private var cachedAvailablePlans: [ComposedPlan]?

    public convenience init(mailUserSession: MailUserSession, configuration: UpsellConfiguration) {
        let plansComposer = PlansComposerRust(rustSession: mailUserSession)
        let plansManager = ProtonPlansManager(plansComposer: plansComposer, rustSession: mailUserSession)
        let planPurchasing: PlanPurchasing = configuration.arePaymentsEnabled ? plansManager : DummyPlanPurchasing()

        self.init(
            eventLoopPolling: mailUserSession,
            onlineExecutor: mailUserSession,
            plansComposer: plansComposer,
            planPurchasing: planPurchasing,
            sessionForking: mailUserSession,
            configuration: configuration
        )
    }

    init(
        eventLoopPolling: EventLoopPolling,
        onlineExecutor: OnlineExecutor,
        plansComposer: PlansComposerProviding,
        planPurchasing: PlanPurchasing,
        sessionForking: SessionForking,
        configuration: UpsellConfiguration
    ) {
        self.onlineExecutor = onlineExecutor
        self.plansComposer = plansComposer
        self.configuration = configuration

        let purchaseActionPerformer = PurchaseActionPerformer(
            eventLoopPolling: eventLoopPolling,
            planPurchasing: planPurchasing
        )

        let webCheckout = WebCheckout(sessionForking: sessionForking, upsellConfiguration: configuration)
        upsellScreenFactory = .init(purchaseActionPerformer: purchaseActionPerformer, webCheckout: webCheckout)

    }

    public func prewarm() async {
        await withCheckedContinuation { continuation in
            let callback = ExecuteWhenOnlineCallbackWrapper {
                Task {
                    _ = try? await self.fetchAvailablePlans()
                    continuation.resume()
                }
            }

            onlineExecutor.executeWhenOnline(callback: callback)
        }
    }

    public func presentUpsellScreen(entryPoint: UpsellEntryPoint, upsellType: UpsellType = .standard) async throws -> UpsellScreenModel {
        let availablePlans = try await fetchAvailablePlans()

        return try upsellScreenFactory.upsellScreenModel(
            showingPlan: configuration.regularPlan,
            basedOn: availablePlans,
            entryPoint: entryPoint,
            upsellType: upsellType
        )
    }

    public func presentOnboardingUpsellScreen() async throws -> OnboardingUpsellScreenModel {
        let availablePlans = try await fetchAvailablePlans()

        return try upsellScreenFactory.onboardingUpsellScreenModel(
            showingPlans: configuration.onboardingPlans,
            basedOn: availablePlans
        )
    }

    private func fetchAvailablePlans() async throws -> [ComposedPlan] {
        if let cachedAvailablePlans {
            return cachedAvailablePlans
        } else {
            let availablePlans = try await plansComposer.fetchAvailablePlans()
            cachedAvailablePlans = availablePlans
            return availablePlans
        }
    }
}

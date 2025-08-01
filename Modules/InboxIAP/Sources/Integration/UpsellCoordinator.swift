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
    private let upsellOfferProvider: UpsellOfferProvider
    private let upsellScreenFactory: UpsellScreenFactory
    private let configuration: UpsellConfiguration

    private var cachedUpsellOffer: UpsellOffer?

    public convenience init(mailUserSession: MailUserSession, configuration: UpsellConfiguration) {
        let plansComposer = PlansComposerRust(rustSession: mailUserSession)
        let plansManager = ProtonPlansManager(plansComposer: plansComposer, rustSession: mailUserSession)
        let planPurchasing: PlanPurchasing = configuration.arePaymentsEnabled ? plansManager : DummyPlanPurchasing()

        self.init(
            onlineExecutor: mailUserSession,
            plansComposer: plansComposer,
            planPurchasing: planPurchasing,
            configuration: configuration
        )
    }

    init(
        onlineExecutor: OnlineExecutor,
        plansComposer: PlansComposerProviding,
        planPurchasing: PlanPurchasing,
        configuration: UpsellConfiguration
    ) {
        self.onlineExecutor = onlineExecutor
        self.upsellOfferProvider = .init(plansComposer: plansComposer)
        self.upsellScreenFactory = .init(planPurchasing: planPurchasing)
        self.configuration = configuration
    }

    public func prewarm() async {
        await withCheckedContinuation { continuation in
            let callback = LiveQueryCallbackWrapper {
                Task {
                    _ = try? await self.fetchUpsellOffer()
                    continuation.resume()
                }
            }

            onlineExecutor.executeWhenOnline(callback: callback)
        }
    }

    public func presentUpsellScreen(entryPoint: UpsellScreenEntryPoint) async throws -> UpsellScreenModel {
        let upsellOffer = try await fetchUpsellOffer()
        return upsellScreenFactory.upsellScreenModel(basedOn: upsellOffer, entryPoint: entryPoint)
    }

    private func fetchUpsellOffer() async throws -> UpsellOffer {
        if let cachedUpsellOffer {
            return cachedUpsellOffer
        } else {
            let offer = try await upsellOfferProvider.findOffer(for: configuration.planName)
            cachedUpsellOffer = offer
            return offer
        }
    }
}

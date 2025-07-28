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

import Combine
import PaymentsNG
import proton_app_uniffi
import StoreKit
import Testing

@testable import InboxIAP

final class UpsellOfferProviderTests {
    private let onlineExecutor = OnlineExecutorSpy()
    private let plansComposer = PlansComposerSpy()
    private lazy var sut = UpsellOfferProvider(onlineExecutor: onlineExecutor, plansComposer: plansComposer)

    @Test
    func offerOnlyContainsComposedPlansForInstancesOfTheRequestedPlan() async {
        plansComposer.stubbedAvailablePlans = [AvailablePlan.mailPlus, .unlimited].flatMap(\.asComposedPlans)

        await #expect(sut.findOffer(for: "mail2022") == .init(composedPlans: AvailablePlan.mailPlus.asComposedPlans))
        await #expect(sut.findOffer(for: "bundle2022") == .init(composedPlans: AvailablePlan.unlimited.asComposedPlans))
    }

    @Test
    func doesNotReturnEmptyOffers() async {
        plansComposer.stubbedAvailablePlans = []

        await #expect(sut.findOffer(for: "mail2022") == nil)
    }

    @Test
    func whenOfflineThenFetchesPlansOnceBackOnline() async throws {
        onlineExecutor.isOnline = false

        Task {
            _ = await sut.findOffer(for: "mail2022")
        }

        try await Task.sleep(for: .milliseconds(50))

        #expect(onlineExecutor.executeWhenOnlineCalls == 1)
        #expect(plansComposer.fetchAvailablePlansCalls == 0)

        onlineExecutor.isOnline = true

        try await Task.sleep(for: .milliseconds(50))

        #expect(onlineExecutor.executeWhenOnlineCalls == 1)
        #expect(plansComposer.fetchAvailablePlansCalls == 1)
    }
}

private final class OnlineExecutorSpy: OnlineExecutor {
    var isOnline = true {
        didSet {
            if isOnline {
                callbackWaitingForConnectivity?.onUpdate()
                callbackWaitingForConnectivity = nil
            }
        }
    }

    private(set) var executeWhenOnlineCalls = 0

    private var callbackWaitingForConnectivity: (any LiveQueryCallback)?

    func executeWhenOnline(callback: any LiveQueryCallback) {
        executeWhenOnlineCalls += 1

        if isOnline {
            callback.onUpdate()
        } else {
            callbackWaitingForConnectivity = callback
        }
    }
}

private final class PlansComposerSpy: PlansComposerProviding {
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

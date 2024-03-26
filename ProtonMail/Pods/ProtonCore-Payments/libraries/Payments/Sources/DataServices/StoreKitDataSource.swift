//
//  StoreKitDataSource.swift
//  ProtonCore-Payments - Created on 23/08/2023.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreLog
import ProtonCoreObservability
import StoreKit

public protocol StoreKitDataSourceProtocol {
    var availableProducts: [SKProduct] { get }
    var unavailableProductsIdentifiers: [String] { get }

    func fetchAvailableProducts(availablePlans: AvailablePlans) async throws
    func fetchAvailableProducts(productIdentifiers: Set<String>) async throws

    func filterAccordingToAvailableProducts(availablePlans: AvailablePlans) -> AvailablePlans
}

final class StoreKitDataSource: NSObject, StoreKitDataSourceProtocol {

    private(set) var availableProducts: [SKProduct] = []
    private(set) var unavailableProductsIdentifiers: [String] = []

    private var request: SKProductsRequest?
    private let requestFactory: (Set<String>) -> SKProductsRequest
    var requestContinuation: CheckedContinuation<Void, Error>?

    init(requestFactory: @escaping (Set<String>) -> SKProductsRequest = { .init(productIdentifiers: $0) }) {
        self.requestFactory = requestFactory
    }

    func fetchAvailableProducts(availablePlans: AvailablePlans) async throws {
        let planVendorIdentifiers = availablePlans.plans.flatMap(\.instances).compactMap(\.vendors).map(\.apple.productID)
        try await fetchAvailableProducts(productIdentifiers: Set(planVendorIdentifiers))
    }

    func fetchAvailableProducts(productIdentifiers: Set<String>) async throws {
        try await withCheckedThrowingContinuation { continuation in
            requestContinuation = continuation
            request = requestFactory(productIdentifiers)
            request?.delegate = self
            request?.start()
        }
    }

    func filterAccordingToAvailableProducts(availablePlans originalPlans: AvailablePlans) -> AvailablePlans {
        let availableProductIdentifiers = availableProducts.map(\.productIdentifier)
        let updatedPlans = originalPlans.plans.map { originalPlan in
            let originalInstances = originalPlan.instances
            let updatedInstances = originalInstances.filter {
                guard let vendors = $0.vendors else { return false }
                return availableProductIdentifiers.contains(vendors.apple.productID)
            }
            let updatedPlan = AvailablePlans.AvailablePlan(
                ID: originalPlan.ID,
                type: originalPlan.type,
                name: originalPlan.name,
                title: originalPlan.title,
                description: originalPlan.description,
                instances: updatedInstances,
                entitlements: originalPlan.entitlements,
                decorations: originalPlan.decorations
            )
            return updatedPlan
        }
        return AvailablePlans(plans: updatedPlans, defaultCycle: originalPlans.defaultCycle)
    }
}

extension StoreKitDataSource: SKProductsRequestDelegate {

    public func productsRequest(_: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.invalidProductIdentifiers.isEmpty {
            PMLog.debug("Some IAP identifiers are reported as invalid by the AppStore: \(response.invalidProductIdentifiers)")
        }
        unavailableProductsIdentifiers = response.invalidProductIdentifiers
        availableProducts = response.products
        request = nil
        ObservabilityEnv.report(.paymentQuerySubscriptionsTotal(status: .successful, isDynamic: true))

        requestContinuation?.resume(returning: ())
        requestContinuation = nil
    }

    func request(_: SKRequest, didFailWithError error: Error) {
        PMLog.error("SKProduct fetch failed with error \(error)", sendToExternal: true)
        request = nil
        ObservabilityEnv.report(.paymentQuerySubscriptionsTotal(status: .failed, isDynamic: false))

        requestContinuation?.resume(throwing: error)
        requestContinuation = nil
    }
}

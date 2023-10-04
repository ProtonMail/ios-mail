//
//  AvailablePlansPresentation.swift
//  ProtonCorePaymentsUI - Created on 10/08/2023.
//
//  Copyright (c) 2022 Proton Technologies AG
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

#if os(iOS)

import ProtonCorePayments

class AvailablePlansPresentation {
    let availablePlan: InAppPurchasePlan?
    let details: AvailablePlansDetails
    var storeKitProductId: String? { availablePlan?.storeKitProductId }
    var isCurrentlyProcessed: Bool = false
    var isExpanded: Bool = false
    var canBePurchasedNow: Bool = true
    
    init(availablePlan: InAppPurchasePlan?,
         details: AvailablePlansDetails,
         isCurrentlyProcessed: Bool = false,
         isExpanded: Bool = false) {
        self.availablePlan = availablePlan
        self.details = details
        self.isCurrentlyProcessed = isCurrentlyProcessed
        self.isExpanded = isExpanded
    }
    
    static func createAvailablePlans(from plan: AvailablePlans.AvailablePlan,
                                     for instance: AvailablePlans.AvailablePlan.Instance? = nil,
                                     plansDataSource: PlansDataSourceProtocol?,
                                     storeKitManager: StoreKitManagerProtocol? = nil) async throws -> AvailablePlansPresentation? {
        if let instance, let storeKitManager {
            return try await createAvailablePlansWithInstance(from: plan, for: instance, plansDataSource: plansDataSource, storeKitManager: storeKitManager)
        } else {
            return try await createAvailablePlansWithoutInstance(from: plan, plansDataSource: plansDataSource)
        }
    }
    
    static func createAvailablePlansWithInstance(from plan: AvailablePlans.AvailablePlan,
                                                 for instance: AvailablePlans.AvailablePlan.Instance,
                                                 plansDataSource: PlansDataSourceProtocol?,
                                                 storeKitManager: StoreKitManagerProtocol) async throws -> AvailablePlansPresentation? {
        guard let inAppPurchasePlan = InAppPurchasePlan(availablePlanInstance: instance) else {
            return nil
        }
        
        guard let details = try await AvailablePlansDetails.createPlan(
            from: plan,
            for: instance,
            iapPlan: inAppPurchasePlan,
            plansDataSource: plansDataSource,
            storeKitManager: storeKitManager
        ) else { return nil }
        
        return .init(availablePlan: inAppPurchasePlan, details: details)
    }
    
    static func createAvailablePlansWithoutInstance(from plan: AvailablePlans.AvailablePlan,
                                                    plansDataSource: PlansDataSourceProtocol?) async throws -> AvailablePlansPresentation? {
        guard let details = try await AvailablePlansDetails.createPlan(
            from: plan,
            plansDataSource: plansDataSource
        ) else { return nil }
        return .init(availablePlan: nil, details: details)
    }
}

#endif

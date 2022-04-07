//
//  ServicePlanSubscription.swift
//  ProtonCore-Payments - Created on 31/08/2018.
//
//  Copyright (c) 2019 Proton Technologies AG
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

public struct Subscription: Codable { // this doesn't represent backend response body, it's codable for easier persistance

    public let start, end: Date?
    public let cycle: Int?
    public let planDetails: [Plan]?
    public internal(set) var organization: Organization?
    public let couponCode: String?
    public let amount: Int?
    public let currency: String?
    public internal(set) var usedSpace: Int64?

    /// Special coupons have to be set from app using this library
    public static var specialCoupons: [String] = [String]()

    public private(set) var isEmptyBecauseOfUnsufficientScopeToFetchTheDetails = false

    static var userHasNoPlanAKAFreePlan: Subscription {
        Subscription(start: nil, end: nil, planDetails: nil, amount: nil, currency: nil)
    }

    static var userHasUnsufficientScopeToFetchSubscription: Subscription {
        var subscription = Subscription(start: nil, end: nil, planDetails: nil, amount: nil, currency: nil)
        subscription.isEmptyBecauseOfUnsufficientScopeToFetchTheDetails = true
        return subscription
    }

    public init(
        start: Date?, end: Date?, planDetails: [Plan]?, couponCode: String? = nil, cycle: Int? = nil, amount: Int?, currency: String?) {
        self.start = start
        self.end = end
        self.planDetails = planDetails
        self.couponCode = couponCode
        self.cycle = cycle
        self.amount = amount
        self.currency = currency
    }
}

extension Subscription {
    
    public func computedPresentationDetails(shownPlanNames: ListOfShownPlanNames) -> Plan {
        // remove all other plans not defined in the shownPlanNames
        let planDetails = planDetails?.filter { elem in shownPlanNames.contains { elem.name == $0 } }
        guard let planDetails = planDetails else { return .empty }
        let subscriptionPlan = Plan.combineDetailsDroppingPricing(planDetails)
        guard let organization = organization else { return subscriptionPlan }
        return Plan(name: subscriptionPlan.name,
                    iD: subscriptionPlan.iD,
                    maxAddresses: max(subscriptionPlan.maxAddresses, organization.maxAddresses),
                    maxMembers: max(subscriptionPlan.maxMembers, organization.maxMembers),
                    pricing: nil,
                    maxDomains: max(subscriptionPlan.maxDomains, organization.maxDomains),
                    maxSpace: max(subscriptionPlan.maxSpace, organization.maxSpace),
                    type: subscriptionPlan.type,
                    title: subscriptionPlan.title,
                    maxVPN: max(subscriptionPlan.maxVPN, organization.maxVPN),
                    features: subscriptionPlan.features,
                    maxCalendars: subscriptionPlan.maxCalendars
                        .map { mc in organization.maxCalendars.map { max(mc, $0) } ?? mc } ?? organization.maxCalendars,
                    state: subscriptionPlan.state,
                    cycle: subscriptionPlan.cycle)
    }

    public var hasExistingProtonSubscription: Bool {
        var existingSubscription = false

        self.planDetails?.forEach { details in
            guard !InAppPurchasePlan.isThisAFreePlan(protonName: details.name),
                  !InAppPurchasePlan.isThisATrialPlan(protonName: details.name)
            else { return }
            existingSubscription = true
        }
        return existingSubscription
    }

    public var endDate: Date? {
        return end
    }
    
    public var price: String? {
        guard let amount = amount, let currency = currency else { return nil }
        let value = Double(amount) / 100.0
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: value))
    }

    public var hasSpecialCoupon: Bool {
        guard let couponCode = couponCode else {
            return false
        }
        return Subscription.specialCoupons.contains(couponCode)
    }
}

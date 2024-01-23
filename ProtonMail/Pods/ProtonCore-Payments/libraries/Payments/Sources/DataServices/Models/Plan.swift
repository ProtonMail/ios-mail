//
//  PlanDetails.swift
//  ProtonCore-Payments - Created on 16/08/2018.
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

// swiftlint:disable identifier_name

import Foundation

public struct Plan: Codable, Equatable {

    public struct Vendors: Codable, Equatable {
        public let apple: Vendor
    }

    public struct Vendor: Codable, Equatable {
        public let plans: [String: String]
    }

    // amount is ignored
    public let name: String
    public var hashedName: String { name.sha256 }
    public let ID: String?
    public let maxAddresses: Int
    public let maxMembers: Int
    // max tier is ignored

    // these three exist only for /plans
    public let pricing: [String: Int]?
    public let defaultPricing: [String: Int]?
    public let vendors: Vendors?
    // offers are ignored for now

    // this one exists only for /subscription
    public let offer: String?

    public let maxDomains: Int
    public let maxSpace: Int64
    // maxRewardsSpace exists only for plans/default route
    public let maxRewardsSpace: Int64?
    // services is ignored
    public let cycle: Int?

    // type field tells if the plan is an add-on or a primary one. 0 — add-on, 1 — primary
    public let type: Int
    public let title: String
    public let maxVPN: Int
    public let maxTier: Int?
    public let features: Int
    // currency is ignored
    // quantity is ignored

    // new plans — new fields
    public let maxCalendars: Int?

    // state field tells if the plan is available for purchasing. 0 — not purchasable, 1 — purchasable
    public let state: Int?

    public static var empty: Plan {
        Plan(name: "", ID: nil, maxAddresses: 0, maxMembers: 0, pricing: nil,
             defaultPricing: nil, vendors: nil, offer: nil, maxDomains: 0, maxSpace: 0, maxRewardsSpace: nil,
             type: 0, title: "", maxVPN: 0, maxTier: 0, features: 0, maxCalendars: nil, state: nil, cycle: nil)
    }

    public init(name: String,
                ID: String?,
                maxAddresses: Int,
                maxMembers: Int,
                pricing: [String: Int]?,
                defaultPricing: [String: Int]?,
                vendors: Vendors?,
                offer: String?,
                maxDomains: Int,
                maxSpace: Int64,
                maxRewardsSpace: Int64?,
                type: Int,
                title: String,
                maxVPN: Int,
                maxTier: Int?,
                features: Int,
                maxCalendars: Int?,
                state: Int?,
                cycle: Int?) {
        self.name = name
        self.ID = ID
        self.maxAddresses = maxAddresses
        self.maxMembers = maxMembers
        self.pricing = pricing
        self.defaultPricing = defaultPricing
        self.vendors = vendors
        self.offer = offer
        self.maxDomains = maxDomains
        self.maxSpace = maxSpace
        self.maxRewardsSpace = maxRewardsSpace
        self.type = type
        self.title = title
        self.maxVPN = maxVPN
        self.maxTier = maxTier
        self.features = features
        self.maxCalendars = maxCalendars
        self.state = state
        self.cycle = cycle
    }
}

public extension Plan {
    func pricing(for period: String?) -> Int? { period.flatMap { pricing?[$0] } }

    func defaultPricing(for period: String?) -> Int? { period.flatMap { defaultPricing?[$0] } }

    func updating(cycle: Int?) -> Plan {
        Plan(name: name, ID: ID, maxAddresses: maxAddresses, maxMembers: maxMembers,
             pricing: pricing, defaultPricing: defaultPricing, vendors: vendors, offer: offer,
             maxDomains: maxDomains, maxSpace: maxSpace, maxRewardsSpace: maxRewardsSpace, type: type,
             title: title, maxVPN: maxVPN, maxTier: maxTier,
             features: features, maxCalendars: maxCalendars, state: state, cycle: cycle)
    }

    func updating(vendors: Vendors?) -> Plan {
        Plan(name: name, ID: ID, maxAddresses: maxAddresses, maxMembers: maxMembers,
             pricing: pricing, defaultPricing: defaultPricing, vendors: vendors, offer: offer,
             maxDomains: maxDomains, maxSpace: maxSpace, maxRewardsSpace: maxRewardsSpace, type: type,
             title: title, maxVPN: maxVPN, maxTier: maxTier,
             features: features, maxCalendars: maxCalendars, state: state, cycle: cycle)
    }
}

public extension Plan {

    var isAPrimaryPlan: Bool { type == 1 }

    var isAnAddOn: Bool { type == 0 }

    var isPurchasable: Bool { state == nil || state == 1 }
}

public extension Plan {

    static func combineDetailsDroppingPricing(_ planDetails: Plan...) -> Plan {
        combineDetails(planDetails, droppingPrice: true)
    }

    static func combineDetailsKeepingPricing(_ planDetails: Plan...) -> Plan {
        combineDetails(planDetails, droppingPrice: false)
    }

    static func combineDetails(_ planDetails: [Plan], droppingPrice: Bool) -> Plan {

        func combinedValue<T: Comparable>(_ allDetails: [Plan],
                                          _ keyPath: KeyPath<Plan, T>) -> T {
            allDetails.map { $0[keyPath: keyPath] }.max() ?? Plan.empty[keyPath: keyPath]
        }

        func combinedValue<T: Comparable>(_ allDetails: [Plan],
                                          _ keyPath: KeyPath<Plan, T?>) -> T? {
            allDetails.map { $0[keyPath: keyPath] }.compactMap { $0 }.max() ?? Plan.empty[keyPath: keyPath]
        }

        var plansForNames = planDetails
            .filter { $0.isAPrimaryPlan }
            .filter { !InAppPurchasePlan.isThisAFreePlan(protonName: $0.name) }
            .filter { !InAppPurchasePlan.isThisATrialPlan(protonName: $0.name) }
        if plansForNames.isEmpty, let firstPlan = planDetails.first {
            plansForNames.append(firstPlan)
        }

        let primaryPlan = planDetails.first { $0.isAPrimaryPlan }

        return Plan(
            name: plansForNames.map(\.name).joined(separator: " + "),
            ID: plansForNames.first?.ID,
            maxAddresses: combinedValue(planDetails, \.maxAddresses),
            maxMembers: combinedValue(planDetails, \.maxMembers),
            pricing: droppingPrice ? nil : primaryPlan?.pricing,
            defaultPricing: droppingPrice ? nil : primaryPlan?.defaultPricing,
            vendors: primaryPlan?.vendors,
            offer: primaryPlan?.offer,
            maxDomains: combinedValue(planDetails, \.maxDomains),
            maxSpace: combinedValue(planDetails, \.maxSpace),
            maxRewardsSpace: combinedValue(planDetails, \.maxRewardsSpace),
            type: combinedValue(planDetails, \.type),
            title: plansForNames.map(\.title).joined(separator: " + "),
            maxVPN: combinedValue(planDetails, \.maxVPN),
            maxTier: combinedValue(planDetails, \.maxTier),
            features: combinedValue(planDetails, \.features),
            maxCalendars: combinedValue(planDetails, \.maxCalendars),
            state: combinedValue(planDetails, \.state),
            cycle: combinedValue(planDetails, \.cycle)
        )
    }
}

extension Plan {
    static func sortPurchasablePlans(lhs: Plan, rhs: Plan) -> Bool {
        // There are three rules to sorting plans:
        // 1. Sort by offer: if plan has offer, rise it to the top
        //    We detect the offer by checking if pricing and defaultPricing differ
        // 2. Sort by pricing: if plan is more expensive, rise to the top
        // 3. Keep server order
        let leftCycle = lhs.cycle.map(String.init) ?? InAppPurchasePlan.defaultCycle
        let rightCycle = rhs.cycle.map(String.init) ?? InAppPurchasePlan.defaultCycle
        let isLeftAnOffer = lhs.hasAnOffer(cycle: leftCycle)
        let isRightAnOffer = rhs.hasAnOffer(cycle: rightCycle)
        if isLeftAnOffer, !isRightAnOffer { return true }
        if !isLeftAnOffer, isRightAnOffer { return false }
        return lhs.pricing(for: leftCycle) ?? 0 > rhs.pricing(for: rightCycle) ?? 0
    }

    private func hasAnOffer(cycle: String) -> Bool {
        guard let pricing = pricing(for: cycle),
              let defaultPricing = defaultPricing(for: cycle) else {
            return false
        }
        return pricing != defaultPricing
    }
}

// swiftlint:enable identifier_name

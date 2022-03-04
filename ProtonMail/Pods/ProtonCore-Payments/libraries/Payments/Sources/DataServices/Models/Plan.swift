//
//  PlanDetails.swift
//  ProtonCore-Payments - Created on 16/08/2018.
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

// swiftlint:disable identifier_name

import Foundation

public struct Plan: Codable, Equatable {
    // amount is ignored
    public let name: String
    public let iD: String?
    public let maxAddresses: Int
    public let maxMembers: Int
    // max tier is ignored
    public let pricing: [String: Int]?
    public let maxDomains: Int
    public let maxSpace: Int64
    // services is ignored
    public let cycle: Int?

    // type field tells if the plan is an add-on or a primary one. 0 — add-on, 1 — primary
    public let type: Int
    public let title: String
    public let maxVPN: Int
    public let features: Int
    // currency is ignored
    // quantity is ignored

    // new plans — new fields
    public let maxCalendars: Int?

    // state field tells if the plan is available for purchasing. 0 — not purchasable, 1 — purchasable
    public let state: Int?

    public static var empty: Plan {
        Plan(name: "", iD: nil, maxAddresses: 0, maxMembers: 0, pricing: nil, maxDomains: 0, maxSpace: 0,
             type: 0, title: "", maxVPN: 0, features: 0, maxCalendars: nil, state: nil, cycle: nil)
    }

    public init(name: String,
                iD: String?,
                maxAddresses: Int,
                maxMembers: Int,
                pricing: [String: Int]?,
                maxDomains: Int,
                maxSpace: Int64,
                type: Int,
                title: String,
                maxVPN: Int,
                features: Int,
                maxCalendars: Int?,
                state: Int?,
                cycle: Int?) {
        self.name = name
        self.iD = iD
        self.maxAddresses = maxAddresses
        self.maxMembers = maxMembers
        self.pricing = pricing
        self.maxDomains = maxDomains
        self.maxSpace = maxSpace
        self.type = type
        self.title = title
        self.maxVPN = maxVPN
        self.features = features
        self.maxCalendars = maxCalendars
        self.state = state
        self.cycle = cycle
    }
}

public extension Plan {
    func pricing(for period: String?) -> Int? { period.flatMap { pricing?[$0] } }
    
    func updating(cycle: Int?) -> Plan {
        Plan(name: name, iD: iD, maxAddresses: maxAddresses, maxMembers: maxMembers, pricing: pricing,
             maxDomains: maxDomains, maxSpace: maxSpace, type: type, title: title, maxVPN: maxVPN,
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
        combineDetailsDroppingPricing(planDetails)
    }

    static func combineDetailsDroppingPricing(_ planDetails: [Plan]) -> Plan {

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

        return Plan(
            name: plansForNames.map(\.name).joined(separator: " + "),
            iD: plansForNames.first?.iD,
            maxAddresses: combinedValue(planDetails, \.maxAddresses),
            maxMembers: combinedValue(planDetails, \.maxMembers),
            pricing: nil,
            maxDomains: combinedValue(planDetails, \.maxDomains),
            maxSpace: combinedValue(planDetails, \.maxSpace),
            type: combinedValue(planDetails, \.type),
            title: plansForNames.map(\.title).joined(separator: " + "),
            maxVPN: combinedValue(planDetails, \.maxVPN),
            features: combinedValue(planDetails, \.features),
            maxCalendars: combinedValue(planDetails, \.maxCalendars),
            state: combinedValue(planDetails, \.state),
            cycle: combinedValue(planDetails, \.cycle)
        )
    }
}

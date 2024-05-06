//
//  CurrentPlan.swift
//  ProtonCorePayments - Created on 13.07.23.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

/// `CurrentPlan` object is the data model for the plan
///  the user is currently subscribed to.
public struct CurrentPlan: Decodable, Equatable {
    public var subscriptions: [Subscription]

    public struct Subscription: Decodable, Equatable {
        public var title: String
        public var name: String?
        public var description: String
        public var cycleDescription: String?
        public var cycle: Int?
        public var currency: String?
        public var amount: Int?
        public var periodEnd: Int?
        /// whether this subscription is auto-renewable
        public var renew: Int?
        public var external: PaymentMethod?
        public var entitlements: [Entitlement]

        public enum PaymentMethod: Int, Decodable {
            case web = 0
            case apple = 1
            case google = 2
        }

        public enum Entitlement: Equatable {
            case progress(ProgressEntitlement)
            case description(DescriptionEntitlement)
        }

        public struct ProgressEntitlement: Decodable, Equatable {
            var type: String
            public var title: String?
            public var iconName: String?
            public var text: String
            public var min: Int
            public var max: Int
            public var current: Int
        }

        public struct DescriptionEntitlement: Decodable, Equatable {
            var type: String
            public var text: String
            public var iconName: String
            public var hint: String?
        }

        public init(title: String, name: String?, description: String, cycleDescription: String? = nil, cycle: Int? = nil, currency: String? = nil, amount: Int? = nil, periodEnd: Int? = nil, renew: Int? = nil, external: PaymentMethod? = nil, entitlements: [Entitlement]) {
            self.title = title
            self.name = name
            self.description = description
            self.cycleDescription = cycleDescription
            self.cycle = cycle
            self.currency = currency
            self.amount = amount
            self.periodEnd = periodEnd
            self.renew = renew
            self.external = external
            self.entitlements = entitlements
        }
    }

    public init(subscriptions: [CurrentPlan.Subscription]) {
        self.subscriptions = subscriptions
    }
}

extension CurrentPlan.Subscription.Entitlement: Decodable {
    private enum EntitlementType: String, Decodable {
        case progress
        case description
    }

    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(EntitlementType.self, forKey: .type)

        switch type {
        case .progress:
            self = .progress(try .init(from: decoder))
        case .description:
            self = .description(try .init(from: decoder))
        }
    }
}

extension CurrentPlan {
    public var hasExistingProtonSubscription: Bool {
        // if there are no subscriptions, there is no subscription
        guard !subscriptions.isEmpty else { return false }
        // if there are multiple subscriptions, there one of them must be a paid one
        guard subscriptions.count == 1, let singleSubscription = subscriptions.first else { return true }
        // if amount, currency and cycle are nil, it's a free plan
        guard singleSubscription.amount == nil, singleSubscription.currency == nil, singleSubscription.cycle == nil
        else { return true }
        return false
    }

    public var endDate: Date? {
        guard let periodEnd = subscriptions.compactMap(\.periodEnd).max() else { return nil }
        return Date(timeIntervalSince1970: Double(periodEnd))
    }
}

extension CurrentPlan.Subscription {
    public var willRenew: Bool? {
        renew.map { $0 == 1 }
    }
}

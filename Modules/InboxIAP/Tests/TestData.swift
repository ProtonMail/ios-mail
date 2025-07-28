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
import StoreKit

@testable import InboxIAP
@testable import PaymentsNG

extension AvailablePlan: @unchecked @retroactive Sendable {
    static let mailPlus = AvailablePlan(
        description: "Secure email with advanced features for your everyday communications.",
        instances: [
            .init(
                price: [
                    .init(current: 499, currency: "EUR", id: ""),
                    .init(current: 499, currency: "USD", id: ""),
                    .init(current: 499, currency: "CHF", id: ""),
                ],
                description: "Per month",
                cycle: 1,
                periodEnd: 0,
                vendors: .init(apple: .init(productID: "iosmail_mail2022_1_usd_auto_renewing", customerID: nil))
            ),
            .init(
                price: [
                    .init(current: 4788, currency: "EUR", id: ""),
                    .init(current: 4788, currency: "USD", id: ""),
                    .init(current: 4788, currency: "CHF", id: ""),
                ],
                description: "Per year",
                cycle: 12,
                periodEnd: 0,
                vendors: .init(apple: .init(productID: "iosmail_mail2022_12_usd_auto_renewing", customerID: nil))
            ),
        ],
        name: "mail2022",
        state: 1,
        type: 1,
        title: "Mail Plus",
        features: 1,
        entitlements: [],
        decorations: [],
        id: "",
        services: 1
    )

    static let unlimited = AvailablePlan(
        description: "Comprehensive privacy and security with all Proton services combined.",
        instances: [
            .init(
                price: [
                    .init(current: 1299, currency: "EUR", id: ""),
                    .init(current: 1299, currency: "USD", id: ""),
                    .init(current: 1299, currency: "CHF", id: ""),
                ],
                description: "Per month",
                cycle: 1,
                periodEnd: 0,
                vendors: .init(apple: .init(productID: "iosmail_bundle2022_1_usd_auto_renewing", customerID: nil))
            ),
            .init(
                price: [
                    .init(current: 11988, currency: "EUR", id: ""),
                    .init(current: 11988, currency: "USD", id: ""),
                    .init(current: 11988, currency: "CHF", id: ""),
                ],
                description: "Per year",
                cycle: 12,
                periodEnd: 0,
                vendors: .init(apple: .init(productID: "iosmail_bundle2022_12_usd_auto_renewing", customerID: nil))
            ),
        ],
        name: "bundle2022",
        state: 1,
        type: 1,
        title: "Proton Unlimited",
        features: 1,
        entitlements: [],
        decorations: [],
        id: "",
        services: 31
    )

    var asComposedPlans: [ComposedPlan] {
        instances.map { instance in
            let product = ProductStub(planPrice: instance.price[1])
            return .init(plan: self, instance: instance, product: product)
        }
    }
}

private struct ProductStub: ProductProtocol {
    let planPrice: Price

    var displayName: String {
        fatalError(#function)
    }

    var description: String {
        fatalError(#function)
    }

    var price: Decimal {
        .init(planPrice.current) / 100
    }

    var priceFormatStyle: Decimal.FormatStyle.Currency {
        .currency(code: planPrice.currency)
    }

    var id: String {
        fatalError(#function)
    }

    var subscription: Product.SubscriptionInfo? {
        nil
    }

    func purchase(options: Set<Product.PurchaseOption>) async throws -> Product.PurchaseResult {
        fatalError(#function)
    }
}

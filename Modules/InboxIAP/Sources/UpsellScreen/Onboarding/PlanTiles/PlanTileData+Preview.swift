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

extension PlanTileData {
    static let previews: [Self] = [
        .init(
            storeKitProductID: "iosmail_bundle2022_12_usd_auto_renewing",
            planName: "Proton Unlimited",
            cycleInMonths: 12,
            discount: .init(percentageValue: 23, savedAmount: "$36.00"),
            entitlements: .unlimited,
            formattedPrice: "$119.88"
        ),
        .init(
            storeKitProductID: "iosmail_bundle2022_1_usd_auto_renewing",
            planName: "Proton Unlimited",
            cycleInMonths: 1,
            discount: nil,
            entitlements: .unlimited,
            formattedPrice: "$12.99"
        ),
        .init(
            storeKitProductID: "iosmail_mail2022_12_usd_auto_renewing",
            planName: "Mail Plus",
            cycleInMonths: 12,
            discount: .init(percentageValue: 20, savedAmount: "$12.00"),
            entitlements: .mailPlus,
            formattedPrice: "$47.88"
        ),
        .init(
            storeKitProductID: "iosmail_mail2022_1_usd_auto_renewing",
            planName: "Mail Plus",
            cycleInMonths: 1,
            discount: nil,
            entitlements: .mailPlus,
            formattedPrice: "$4.99"
        ),
        .free(priceFormatStyle: .usd, cycleInMonths: 12),
        .free(priceFormatStyle: .usd, cycleInMonths: 1),
    ]

    static func free(priceFormatStyle: Decimal.FormatStyle.Currency, cycleInMonths: Int) -> Self {
        .init(
            storeKitProductID: nil,
            planName: "Proton Free",
            cycleInMonths: cycleInMonths,
            discount: nil,
            entitlements: .free,
            formattedPrice: priceFormatStyle.format(0.0)
        )
    }
}

private extension Decimal.FormatStyle.Currency {
    static let usd = Self.localizedCurrency(code: "USD", locale: .init(languageCode: .english))
}

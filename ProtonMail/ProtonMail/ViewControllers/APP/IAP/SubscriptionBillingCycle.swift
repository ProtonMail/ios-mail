// Copyright (c) 2024 Proton Technologies AG
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

import ProtonCorePayments

struct SubscriptionBillingCycle: Equatable {
    let months: Int
    let monthlyPrice: Double
    let formattedMonthlyPrice: String
    let formattedBillingPrice: String
    let storeKitProductId: String

    private static let minimumVisibleDiscount = 5

    // logic copied from VPN
    func discount(comparedTo other: Self) -> Int? {
        guard other.monthlyPrice != 0 else {
            return nil
        }

        guard monthlyPrice != 0 else {
            return 100
        }

        let discountDouble = (1 - (monthlyPrice / other.monthlyPrice)) * 100
        // don't round to 100% if it's not exactly 100%
        let discountInt = min(Int(discountDouble.rounded()), 99)
        return discountInt >= Self.minimumVisibleDiscount ? discountInt : nil
    }
}

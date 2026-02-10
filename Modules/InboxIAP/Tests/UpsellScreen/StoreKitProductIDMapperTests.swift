// Copyright (c) 2026 Proton Technologies AG
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

import InboxAttribution
import Testing

@testable import InboxIAP

struct StoreKitProductIDMapperTests {
    @Test
    func mapsPlusMonthlyPlan() {
        let productID = "iosmail_mail2022_1_usd_auto_renewing"

        let result = StoreKitProductIDMapper.map(storeKitProductID: productID)

        #expect(result.plan == .plus)
        #expect(result.duration == .month)
    }

    @Test
    func mapsPlusYearlyPlan() {
        let productID = "iosmail_mail2022_12_usd_auto_renewing"

        let result = StoreKitProductIDMapper.map(storeKitProductID: productID)

        #expect(result.plan == .plus)
        #expect(result.duration == .year)
    }

    @Test
    func mapsUnlimitedMonthlyPlan() {
        let productID = "iosmail_bundle2022_1_usd_auto_renewing"

        let result = StoreKitProductIDMapper.map(storeKitProductID: productID)

        #expect(result.plan == .unlimited)
        #expect(result.duration == .month)
    }

    @Test
    func mapsUnlimitedYearlyPlan() {
        let productID = "iosmail_bundle2022_12_usd_auto_renewing"

        let result = StoreKitProductIDMapper.map(storeKitProductID: productID)

        #expect(result.plan == .unlimited)
        #expect(result.duration == .year)
    }
}

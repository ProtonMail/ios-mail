//
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

import InboxDesignSystem
import Testing
import proton_app_uniffi

@testable import InboxIAP

struct UpsellTypeUpsellScreenTests {
    @Test
    func mailPlusPlanVariant() {
        #expect(UpsellType.mailPlus.planVariant == SubscriptionPlanVariant.plus)
    }

    @Test
    func unlimitedPlanVariant() {
        #expect(UpsellType.unlimited.planVariant == SubscriptionPlanVariant.unlimited)
    }

    @Test
    func mailPlusLogo() {
        #expect(UpsellType.mailPlus.logo == DS.Images.Upsell.logoDefault)
    }

    @Test
    func unlimitedLogo() {
        #expect(UpsellType.unlimited.logo == DS.Images.Upsell.logoUnlimited)
    }

    @Test
    func mailPlusComparisonConfigurationHasTextHeader() {
        let config = UpsellType.mailPlus.comparisonConfiguration
        guard case .text = config.planColumnHeader else {
            Issue.record("Expected .text header for mailPlus")
            return
        }
        #expect(config.items.count == 6)
    }

    @Test
    func unlimitedComparisonConfigurationHasIconHeader() {
        let config = UpsellType.unlimited.comparisonConfiguration
        guard case .icon = config.planColumnHeader else {
            Issue.record("Expected .icon header for unlimited")
            return
        }
        #expect(config.items.count == 8)
    }
}

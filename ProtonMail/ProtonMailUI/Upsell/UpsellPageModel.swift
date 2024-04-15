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

import ProtonCoreUIFoundations

public struct UpsellPageModel {
    public struct Plan {
        public let name: String
        public let perks: [Perk]
        public let purchasingOptions: [PurchasingOption]

        public init(name: String, perks: [Perk], purchasingOptions: [PurchasingOption]) {
            self.name = name
            self.perks = perks
            self.purchasingOptions = purchasingOptions
        }
    }

    public struct Perk {
        public let icon: KeyPath<ProtonIconSet, ProtonIcon>
        public let description: String

        public init(icon: KeyPath<ProtonIconSet, ProtonIcon>, description: String) {
            self.icon = icon
            self.description = description
        }
    }

    public struct PurchasingOption {
        public let months: Int
        public let monthlyPrice: String
        public let isHighlighted: Bool
        public let discount: Double?

        public init(months: Int, monthlyPrice: String, isHighlighted: Bool, discount: Double?) {
            self.months = months
            self.monthlyPrice = monthlyPrice
            self.isHighlighted = isHighlighted
            self.discount = discount
        }
    }

    public let plan: Plan

    public init(plan: Plan) {
        self.plan = plan
    }
}

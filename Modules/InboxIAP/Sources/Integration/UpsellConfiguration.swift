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

public struct UpsellConfiguration: Sendable {
    public let regularPlan: String
    public let onboardingPlans: [String]
    public let arePaymentsEnabled: Bool
    public let apiDomain: String

    public init(regularPlan: String, onboardingPlans: [String], arePaymentsEnabled: Bool, apiDomain: String) {
        self.regularPlan = regularPlan
        self.onboardingPlans = onboardingPlans
        self.arePaymentsEnabled = arePaymentsEnabled
        self.apiDomain = apiDomain
    }
}

extension UpsellConfiguration {
    static let dummy = UpsellConfiguration(
        regularPlan: "mail2022",
        onboardingPlans: ["bundle2022", "mail2022"],
        arePaymentsEnabled: true,
        apiDomain: "example.com"
    )
}

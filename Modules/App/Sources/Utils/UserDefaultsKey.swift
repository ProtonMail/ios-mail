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

import Foundation
import InboxCore
import proton_app_uniffi

extension UserDefaultsKey<Bool> {
    static let hasSeenAlphaOnboarding = Self(name: "hasSeenAlphaOnboarding")

    static func hasSeenOnboardingUpsell(ofType upsellType: UpsellType) -> Self {
        .init(name: upsellType.onboardingUserDefaultsKey)
    }
}

extension UserDefaultsKey<[Date]> {
    static let notificationAuthorizationRequestDates = Self(name: "notificationAuthorizationRequestDates")
}

extension UserDefaultsKey<String> {
    static let lastWhatsNewVersion = Self(name: "lastWhatsNewVersion")
}

private extension UpsellType {
    var onboardingUserDefaultsKey: String {
        switch self {
        case .standard:
            "hasSeenOnboardingUpsell"
        case .blackFriday(.wave1):
            "hasSeenOnboardingUpsell_BF2025_1"
        case .blackFriday(.wave2):
            "hasSeenOnboardingUpsell_BF2025_2"
        }
    }
}

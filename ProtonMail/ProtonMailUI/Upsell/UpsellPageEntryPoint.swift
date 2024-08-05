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

public enum UpsellPageEntryPoint: Sendable {
    case header
    case contactGroups

    var logo: ImageResource {
        switch self {
        case .header:
            return .upsellDefaultLogo
        case .contactGroups:
            return .upsellContactGroupsLogo
        }
    }

    var logoPadding: CGFloat {
        switch self {
        case .header:
            -20
        case .contactGroups:
            0
        }
    }

    func title(planName: String) -> String {
        switch self {
        case .header:
            return String(format: L10n.Upsell.upgradeToPlan, planName)
        case .contactGroups:
            return L10n.Upsell.contactGroupsTitle
        }
    }

    func subtitle(planName: String) -> String {
        switch self {
        case .header:
            return L10n.Upsell.mailPlusDescription
        case .contactGroups:
            return String(format: L10n.Upsell.contactGroupsDescription, planName)
        }
    }
}

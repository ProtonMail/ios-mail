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

import SwiftUI

public enum UpsellPageEntryPoint: Sendable {
    case autoDelete
    case contactGroups
    case header
    case scheduleSend
    case snooze

    var logo: ImageResource {
        switch self {
        case .autoDelete:
            return .upsellAutoDeleteLogo
        case .contactGroups:
            return .upsellContactGroupsLogo
        case .header:
            return .upsellDefaultLogo
        case .scheduleSend:
            return .upsellScheduleSendLogo
        case .snooze:
            return .upsellSnoozeLogo
        }
    }

    var logoPadding: EdgeInsets {
        switch self {
        case .autoDelete, .contactGroups, .scheduleSend, .snooze:
            return .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        case .header:
            return .init(top: -40, leading: 0, bottom: -40, trailing: 0)
        }
    }

    func title(planName: String) -> String {
        switch self {
        case .autoDelete:
            return L10n.Upsell.autoDeleteTitle
        case .contactGroups:
            return L10n.Upsell.contactGroupsTitle
        case .header:
            return String(format: L10n.Upsell.upgradeToPlan, planName)
        case .scheduleSend:
            return L10n.Upsell.scheduleSendTitle
        case .snooze:
            return L10n.Upsell.snoozeTitle
        }
    }

    func subtitle(planName: String) -> String {
        switch self {
        case .autoDelete:
            return String(format: L10n.Upsell.autoDeleteDescription, planName)
        case .contactGroups:
            return String(format: L10n.Upsell.contactGroupsDescription, planName)
        case .header:
            return L10n.Upsell.mailPlusDescription
        case .scheduleSend:
            return String(format: L10n.Upsell.scheduleSendDescription, planName)
        case .snooze:
            return String(format: L10n.Upsell.snoozeDescription, planName)
        }
    }
}

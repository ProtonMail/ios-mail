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

import InboxDesignSystem
import SwiftUI

public enum UpsellScreenEntryPoint: Sendable {
    case autoDelete
    case contactGroups
    case folders
    case header
    case labels
    case mobileSignature
    case scheduleSend
    case sidebar
    case snooze

    var logo: ImageResource {
        switch self {
        case .autoDelete:
            DS.Images.Upsell.logoAutoDelete
        case .contactGroups:
            DS.Images.Upsell.logoContactGroups
        case .folders, .labels:
            DS.Images.Upsell.logoFoldersAndLabels
        case .header, .sidebar:
            DS.Images.Upsell.logoDefault
        case .mobileSignature:
            DS.Images.Upsell.logoMobileSignature
        case .scheduleSend:
            DS.Images.Upsell.logoScheduleSend
        case .snooze:
            DS.Images.Upsell.logoSnooze
        }
    }
}

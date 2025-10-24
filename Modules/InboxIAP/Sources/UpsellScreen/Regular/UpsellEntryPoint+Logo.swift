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
import proton_app_uniffi
import SwiftUI

extension UpsellEntryPoint {
    var logo: ImageResource {
        switch self {
        case .autoDeleteMessages:
            DS.Images.Upsell.logoAutoDelete
        case .contactGroups:
            DS.Images.Upsell.logoContactGroups
        case .dollarPromo, .mailboxTopBarPromo:
            fatalError("This entry point is not used")
        case .foldersCreation, .labelsCreation:
            DS.Images.Upsell.logoFoldersAndLabels
        case .mailboxTopBar, .navbarUpsell:
            DS.Images.Upsell.logoDefault
        case .mobileSignatureEdit:
            DS.Images.Upsell.logoMobileSignature
        case .postOnboarding:
            fatalError("Onboarding upsell does not have a logo")
        case .scheduleSend:
            DS.Images.Upsell.logoScheduleSend
        case .snooze:
            DS.Images.Upsell.logoSnooze
        }
    }
}

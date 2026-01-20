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
import SwiftUI

struct NewFeatureIntroduction: Hashable {
    let name: LocalizedStringResource
    let description: LocalizedStringResource
    let icon: ImageResource
}

extension NewFeatureIntroduction {
    static var whatsNew: [Self] {
        [
            .init(
                name: L10n.WhatsNew.Features.discreetIconName,
                description: L10n.WhatsNew.Features.discreetIconDescription,
                icon: DS.Icon.icPalette
            ),
            .init(
                name: L10n.WhatsNew.Features.trackingProtectionName,
                description: L10n.WhatsNew.Features.trackingProtectionDescription,
                icon: DS.Icon.icShieldCheck
            ),
            .init(
                name: L10n.WhatsNew.Features.encryptionLocksName,
                description: L10n.WhatsNew.Features.encryptionLocksDescription,
                icon: DS.Icon.icLock
            ),
            .init(
                name: L10n.WhatsNew.Features.viewHeadersAndHTMLName,
                description: L10n.WhatsNew.Features.viewHeadersAndHTMLDescription,
                icon: DS.Icon.icCode
            ),
        ]
    }
}

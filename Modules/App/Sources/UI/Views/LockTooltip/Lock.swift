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
import proton_app_uniffi

extension PrivacyLockColor {
    var uiColor: Color {
        switch self {
        case .black:
            DS.Color.Global.black
        case .green:
            DS.Color.Lock.green
        case .blue:
            DS.Color.Lock.blue
        }
    }
}

extension PrivacyLockIcon {
    var uiIcon: ImageResource {
        switch self {
        case .none:
            fatalError()
        case .closedLock:
            DS.Icon.icLockFilled
        case .closedLockWithTick:
            DS.Icon.icLockCheckFilled
        case .closedLockWithPen:
            DS.Icon.icLockPenFilled
        case .closedLockWarning:
            DS.Icon.icLockExclamationFilled
        case .openLockWithPen:
            DS.Icon.icLockOpenPenFilled
        case .openLockWithTick:
            DS.Icon.icLockOpenCheckFilled
        case .openLockWarning:
            DS.Icon.icLockOpenExclamationFilled
        }
    }
}

extension PrivacyLockTooltip {
    // FIXME: - Add correct text
    var title: String {
        "Stored with zero-access encryption".notLocalized
    }

    // FIXME: - Add correct text
    var description: String {
        """
        This message is stored on our servers with zero‑access encryption. Neither Proton nor anyone else can read it.

        However, a sender or recipient not using Proton Mail may have a non-encrypted copy stored on their email server.
        """
        .notLocalized
    }
}

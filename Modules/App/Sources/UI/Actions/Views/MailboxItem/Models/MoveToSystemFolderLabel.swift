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
import proton_app_uniffi

extension MovableSystemFolder {
    var humanReadable: LocalizedStringResource {
        switch self {
        case .inbox:
            L10n.Mailbox.SystemFolder.inbox
        case .trash:
            L10n.Mailbox.SystemFolder.trash
        case .spam:
            L10n.Mailbox.SystemFolder.spam
        case .archive:
            L10n.Mailbox.SystemFolder.archive
        }
    }

    var icon: ImageResource {
        switch self {
        case .inbox:
            DS.Icon.icInbox
        case .trash:
            DS.Icon.icTrash
        case .spam:
            DS.Icon.icFire
        case .archive:
            DS.Icon.icArchiveBox
        }
    }
}

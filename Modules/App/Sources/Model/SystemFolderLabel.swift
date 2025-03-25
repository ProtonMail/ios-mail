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

import DeveloperToolsSupport
import Foundation
import InboxDesignSystem
import proton_app_uniffi

typealias SystemFolderLabel = SystemLabel

extension SystemFolderLabel {
    var humanReadable: LocalizedStringResource {
        switch self {
        case .inbox:
            L10n.Mailbox.SystemFolder.inbox
        case .allDrafts:
            L10n.Mailbox.SystemFolder.allDrafts
        case .allSent:
            L10n.Mailbox.SystemFolder.allSent
        case .sent:
            L10n.Mailbox.SystemFolder.sent
        case .trash:
            L10n.Mailbox.SystemFolder.trash
        case .spam:
            L10n.Mailbox.SystemFolder.spam
        case .allMail:
            L10n.Mailbox.SystemFolder.allMail
        case .archive:
            L10n.Mailbox.SystemFolder.archive
        case .drafts:
            L10n.Mailbox.SystemFolder.draft
        case .outbox:
            L10n.Mailbox.SystemFolder.outbox
        case .starred:
            L10n.Mailbox.SystemFolder.starred
        case .scheduled:
            L10n.Mailbox.SystemFolder.allScheduled
        case .almostAllMail:
            L10n.Mailbox.SystemFolder.allMail
        case .snoozed:
            L10n.Mailbox.SystemFolder.snoozed
        case .categorySocial, .categoryPromotions, .catergoryUpdates, .categoryForums, .categoryDefault, .blocked, .pinned:
            fatalError("Not implemented")
        }
    }

    var icon: ImageResource {
        switch self {
        case .inbox:
            DS.Icon.icInbox
        case .allDrafts, .drafts:
            DS.Icon.icFile
        case .outbox:
            DS.Icon.icOutbox
        case .allSent, .sent:
            DS.Icon.icPaperPlane
        case .trash:
            DS.Icon.icTrash
        case .spam:
            DS.Icon.icFire
        case .allMail, .almostAllMail:
            DS.Icon.icEnvelopes
        case .archive:
            DS.Icon.icArchiveBox
        case .starred:
            DS.Icon.icStar
        case .scheduled, .snoozed:
            DS.Icon.icClock
        case .categorySocial, .categoryPromotions, .catergoryUpdates, .categoryForums, .categoryDefault, .blocked, .pinned:
            fatalError("Not implemented")
        }
    }
}

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

import DesignSystem
import Foundation
import class SwiftUI.UIImage

/// List of remote identifiers for system folders. These values are not to be used for PMLocalLabelId
enum SystemFolderIdentifier: UInt64, CaseIterable {
    case inbox = 0
    case allDraft = 1
    case allSent = 2
    case trash = 3
    case spam = 4
    case allMail = 5
    case archive = 6
    case sent = 7
    case draft = 8
    case outbox = 9
    case starred = 10
    case allScheduled = 12
    case almostAllMail = 15
    case snoozed = 16
}

extension SystemFolderIdentifier {

    var localisedName: String {
        switch self {
        case .inbox:
            LocalizationTemp.Mailbox.inbox
        case .allDraft:
            LocalizationTemp.Mailbox.allDraft
        case .allSent:
            LocalizationTemp.Mailbox.allSent
        case .trash:
            LocalizationTemp.Mailbox.trash
        case .spam:
            LocalizationTemp.Mailbox.spam
        case .allMail:
            LocalizationTemp.Mailbox.allMail
        case .archive:
            LocalizationTemp.Mailbox.archive
        case .sent:
            LocalizationTemp.Mailbox.sent
        case .draft:
            LocalizationTemp.Mailbox.draft
        case .outbox:
            LocalizationTemp.Mailbox.outbox
        case .starred:
            LocalizationTemp.Mailbox.starred
        case .allScheduled:
            LocalizationTemp.Mailbox.allScheduled
        case .almostAllMail:
            LocalizationTemp.Mailbox.allMail
        case .snoozed:
            LocalizationTemp.Mailbox.snoozed
        }
    }

    var icon: UIImage {
        switch self {
        case .inbox:
            DS.Icon.icInbox
        case .allDraft, .draft, .outbox:
            DS.Icon.icFile
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
        case .allScheduled, .snoozed:
            DS.Icon.icClock
        }
    }
}

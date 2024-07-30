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
import class UIKit.UIImage

/**
 List of all the actions that can take place over a message or a conversation.

 The purpose of this enum is to declare icons and strings related to an action only once.
 */
enum Action: ActionPickerListElement {
    case deletePermanently
    case markAsRead
    case markAsUnread
    case labelAs
    case moveTo
    case moveToArchive
    case moveToInbox
    case moveToInboxFromSpam
    case moveToSpam
    case moveToTrash
    case print
    case renderInLightMode
    case reportPhishing
    case saveAsPDF
    case star
    case snooze
    case unstar
    case viewHeaders
    case viewHTML

    var name: LocalizedStringResource {
        switch self {
        case .deletePermanently:
            L10n.Action.deletePermanently
        case .labelAs:
            L10n.Action.labelAs
        case .markAsRead:
            L10n.Action.markAsRead
        case .markAsUnread:
            L10n.Action.markAsUnread
        case .moveTo:
            L10n.Action.moveTo
        case .moveToArchive:
            L10n.Action.moveToArchive
        case .moveToInbox:
            L10n.Action.moveToInbox
        case .moveToInboxFromSpam:
            L10n.Action.moveToInboxFromSpam
        case .moveToSpam:
            L10n.Action.moveToSpam
        case .moveToTrash:
            L10n.Action.moveToTrash
        case .print:
            L10n.Action.print
        case .renderInLightMode:
            L10n.Action.renderInLightMode
        case .reportPhishing:
            L10n.Action.reportPhishing
        case .saveAsPDF:
            L10n.Action.saveAsPDF
        case .snooze:
            L10n.Action.snooze
        case .star:
            L10n.Action.star
        case .unstar:
            L10n.Action.unstar
        case .viewHeaders:
            L10n.Action.viewHeaders
        case .viewHTML:
            L10n.Action.viewHTML
        }
    }

    var icon: UIImage {
        switch self {
        case .deletePermanently:
            return DS.Icon.icTrashCross
        case .labelAs:
            return DS.Icon.icTag
        case .markAsRead:
            return DS.Icon.icEnvelopeOpen
        case .markAsUnread:
            return DS.Icon.icEnvelopeDot
        case .moveTo:
            return DS.Icon.icFolderArrowIn
        case .moveToArchive:
            return DS.Icon.icArchiveBox
        case .moveToInbox:
            return DS.Icon.icInbox
        case .moveToInboxFromSpam:
            return DS.Icon.icNotSpam
        case .moveToSpam:
            return DS.Icon.icSpam
        case .moveToTrash:
            return DS.Icon.icTrash
        case .print:
            return DS.Icon.icPrinter
        case .renderInLightMode:
            return DS.Icon.icSun
        case .reportPhishing:
            return DS.Icon.icHook
        case .saveAsPDF:
            return DS.Icon.icFilePDF
        case .snooze:
            return DS.Icon.icClock
        case .star:
            return DS.Icon.icStar
        case .unstar:
            return DS.Icon.icStarSlash
        case .viewHeaders:
            return DS.Icon.icFileLines
        case .viewHTML:
            return DS.Icon.icCode
        }
    }
}

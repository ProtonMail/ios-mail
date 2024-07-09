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

    var name: String {
        switch self {
        case .deletePermanently:
            return LocalizationTemp.Action.deletePermanently
        case .labelAs:
            return LocalizationTemp.Action.labelAs
        case .markAsRead:
            return LocalizationTemp.Action.markAsRead
        case .markAsUnread:
            return LocalizationTemp.Action.markAsUnread
        case .moveTo:
            return LocalizationTemp.Action.moveTo
        case .moveToArchive:
            return LocalizationTemp.Action.moveToArchive
        case .moveToInbox:
            return LocalizationTemp.Action.moveToInbox
        case .moveToInboxFromSpam:
            return LocalizationTemp.Action.moveToInboxNotSpam
        case .moveToSpam:
            return LocalizationTemp.Action.moveToSpam
        case .moveToTrash:
            return LocalizationTemp.Action.moveToTrash
        case .print:
            return LocalizationTemp.Action.print
        case .renderInLightMode:
            return LocalizationTemp.Action.renderInLightMode
        case .reportPhishing:
            return LocalizationTemp.Action.reportPhishing
        case .saveAsPDF:
            return LocalizationTemp.Action.saveAsPDF
        case .snooze:
            return LocalizationTemp.Action.snooze
        case .star:
            return LocalizationTemp.Action.star
        case .unstar:
            return LocalizationTemp.Action.unstar
        case .viewHeaders:
            return LocalizationTemp.Action.viewHeaders
        case .viewHTML:
            return LocalizationTemp.Action.viewHTML
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

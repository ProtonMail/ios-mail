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
enum Action {
    case delete
    case markAsRead
    case markAsUnread
    case labelAs
    case moveTo
    case moveToArchive
    case moveToInbox
    case moveToSpam
    case moveToTrash
    case star
    case snooze
    case unstar

    var name: String {
        switch self {
        case .delete:
            return LocalizationTemp.Action.delete
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
        case .moveToSpam:
            return LocalizationTemp.Action.moveToSpam
        case .moveToTrash:
            return LocalizationTemp.Action.moveToTrash
        case .snooze:
            return LocalizationTemp.Action.snooze
        case .star:
            return LocalizationTemp.Action.star
        case .unstar:
            return LocalizationTemp.Action.unstar
        }
    }

    var icon: UIImage {
        switch self {
        case .delete:
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
        case .moveToSpam:
            return DS.Icon.icFire
        case .moveToTrash:
            return DS.Icon.icTrash
        case .snooze:
            return DS.Icon.icClock
        case .star:
            return DS.Icon.icStar
        case .unstar:
            return DS.Icon.icStarSlash
        }
    }
}

//
//  MessageViewActionSheetAction.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations

enum MessageViewActionSheetAction: Equatable {
    case reply
    case replyAll
    case forward
    case markUnread
    case markRead
    case labelAs
    case trash
    case archive
    case spam
    case delete
    case moveTo
    case print
    case viewHeaders
    case viewHTML
    case reportPhishing
    case dismiss
    case inbox
    case spamMoveToInbox
    case star
    case unstar
    case viewInLightMode
    case viewInDarkMode

    var title: String {
        switch self {
        case .archive:
            return LocalString._action_sheet_action_title_archive
        case .reply:
            return LocalString._action_sheet_action_title_reply
        case .replyAll:
            return LocalString._action_sheet_action_title_replyAll
        case .forward:
            return LocalString._action_sheet_action_title_forward
        case .markUnread:
            return LocalString._title_of_unread_action_in_action_sheet
        case .markRead:
            return LocalString._title_of_read_action_in_action_sheet
        case .labelAs:
            return LocalString._action_sheet_action_title_labelAs
        case .trash:
            return LocalString._action_sheet_action_title_trash
        case .spam:
            return LocalString._action_sheet_action_title_spam
        case .delete:
            return LocalString._action_sheet_action_title_delete
        case .moveTo:
            return LocalString._action_sheet_action_title_moveTo
        case .print:
            return LocalString._action_sheet_action_title_print
        case .viewHeaders:
            return LocalString._action_sheet_action_title_view_headers
        case .viewHTML:
            return LocalString._action_sheet_action_title_view_html
        case .reportPhishing:
            return LocalString._action_sheet_action_title_phishing
        case .dismiss:
            return ""
        case .inbox:
            return LocalString._action_sheet_action_title_inbox
        case .spamMoveToInbox:
            return LocalString._action_sheet_action_title_spam_to_inbox
        case .star:
            return LocalString._title_of_star_action_in_action_sheet
        case .unstar:
            return LocalString._title_of_unstar_action_in_action_sheet
        case .viewInLightMode:
            return LocalString._title_of_viewInLightMode_action_in_action_sheet
        case .viewInDarkMode:
            return LocalString._title_of_viewInDarkMode_action_in_action_sheet
        }
    }

    var icon: ImageAsset.Image {
        switch self {
        case .reply:
            return IconProvider.arrowUpAndLeft
        case .replyAll:
            return IconProvider.arrowsUpAndLeft
        case .forward:
            return IconProvider.arrowRight
        case .markUnread, .markRead:
            return IconProvider.envelopeDot
        case .labelAs:
            return IconProvider.tag
        case .trash:
            return IconProvider.trash
        case .archive:
            return IconProvider.archiveBox
        case .spam:
            return IconProvider.fire
        case .delete:
            return IconProvider.trashCross
        case .moveTo:
            return IconProvider.folderArrowIn
        case .print:
            return IconProvider.printer
        case .viewHeaders:
            return IconProvider.fileLines
        case .viewHTML:
            return IconProvider.code
        case .reportPhishing:
            return IconProvider.hook
        case .dismiss:
            return IconProvider.cross
        case .inbox, .spamMoveToInbox:
            return IconProvider.inbox
        case .star:
            return IconProvider.star
        case .unstar:
            return IconProvider.starSlash
        case .viewInLightMode:
            return IconProvider.sun
        case .viewInDarkMode:
            return IconProvider.moon
        }
    }
}

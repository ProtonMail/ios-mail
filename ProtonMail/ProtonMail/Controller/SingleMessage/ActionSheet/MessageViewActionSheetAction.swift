//
//  MessageViewActionSheetAction.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

enum MessageViewActionSheetAction: Equatable {
    case reply
    case replyAll
    case forward
    case markUnread
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
            return LocalString._action_sheet_action_title_markUnread
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
        }
    }

    var icon: ImageAsset.Image {
        switch self {
        case .reply:
            return Asset.actionBarReply.image
        case .replyAll:
            return Asset.actionBarReplyAll.image
        case .forward:
            return Asset.mailForward.image
        case .markUnread:
            return Asset.actionSheetUnread.image
        case .labelAs:
            return Asset.swipeLabelAs.image
        case .trash:
            return Asset.actionBarTrash.image
        case .archive:
            return Asset.actionBarArchive.image
        case .spam:
            return Asset.actionBarSpam.image
        case .delete:
            return Asset.actionBarDelete.image
        case .moveTo:
            return Asset.actionBarMoveTo.image
        case .print:
            return Asset.actionSheetPrint.image
        case .viewHeaders:
            return Asset.actionSheetHeader.image
        case .viewHTML:
            return Asset.actionSheetHtml.image
        case .reportPhishing:
            return Asset.actionSheetPhishing.image
        case .dismiss:
            return Asset.actionSheetClose.image
        case .inbox, .spamMoveToInbox:
            return Asset.mailInboxIcon.image
        case .star:
            return Asset.actionSheetStar.image
        case .unstar:
            return Asset.actionSheetUnstar.image
        }
    }
}

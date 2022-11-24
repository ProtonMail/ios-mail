// Copyright (c) 2022 Proton AG
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

import Foundation
import ProtonCore_DataModel

/// This enum maps the toolbar action value in string from server.
enum ServerToolbarAction: String, CaseIterable {
    case replyOrReplyAll = "reply"
    case markAsReadOrUnread = "toggle_read"
    case starOrUnstar = "toggle_star"
    case forward = "forward"
    case labelAs = "label"
    case moveTo = "move"
    case moveToTrash = "trash"
    case moveToArchive = "archive"
    case moveToSpam = "spam"
    case viewMessageInLight = "toggle_light"
    case print = "print"
    case viewHeader = "view_header"
    case viewHTML = "view_html"
    case reportPhishing = "report_phishing"
    case remindMe = "remind"
    case saveAsPDF = "save_pdf"
    case emailsForSender = "sender_emails"
    case downloadAttachments = "save_attachments"

    static func convert(action: [MessageViewActionSheetAction]) -> [Self] {
        return action.compactMap { action in
            switch action {
            case .viewHTML:
                return .viewHTML
            case .archive:
                return .moveToArchive
            case .delete, .trash:
                return .moveToTrash
            case .forward:
                return forward
            case .inbox, .spam, .spamMoveToInbox:
                return .moveToSpam
            case .labelAs:
                return .labelAs
            case .markRead, .markUnread:
                return .markAsReadOrUnread
            case .moveTo:
                return .moveTo
            case .print:
                return .print
            case .reply, .replyAll, .replyOrReplyAll:
                return .replyOrReplyAll
            case .reportPhishing:
                return .reportPhishing
            case .saveAsPDF:
                return .saveAsPDF
            case .star, .unstar:
                return .starOrUnstar
            case .viewHeaders:
                return .viewHeader
            case .viewInDarkMode, .viewInLightMode:
                return .viewMessageInLight
            case .toolbarCustomization, .more, .dismiss:
                return nil
            }
        }
    }
}

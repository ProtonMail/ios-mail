//
//  SingleMessageNavigationAction.swift
//  Proton Mail
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

import ProtonMailUI

enum SingleMessageNavigationAction: Equatable {
    case contacts(contact: ContactVO)
    case compose(contact: ContactVO)
    case viewHeaders(url: URL?)
    case viewHTML(url: URL?)
    case reply(
        messageId: MessageID,
        remoteContentPolicy: WebContents.RemoteContentPolicy,
        embeddedContentPolicy: WebContents.EmbeddedContentPolicy
    )
    case replyAll(
        messageId: MessageID,
        remoteContentPolicy: WebContents.RemoteContentPolicy,
        embeddedContentPolicy: WebContents.EmbeddedContentPolicy
    )
    case forward(
        messageId: MessageID,
        remoteContentPolicy: WebContents.RemoteContentPolicy,
        embeddedContentPolicy: WebContents.EmbeddedContentPolicy
    )
    case attachmentList(messageId: MessageID, decryptedBody: String?, attachments: [AttachmentInfo])
    case url(url: URL)
    case inAppSafari(url: URL)
    case mailToUrl(url: URL)
    case addNewFolder
    case addNewLabel
    case viewCypher(url: URL)
    case more(messageId: MessageID)
    case toolbarCustomization(currentActions: [MessageViewActionSheetAction],
                              allActions: [MessageViewActionSheetAction])
    case toolbarSettingView
    case upsellPage(entryPoint: UpsellPageEntryPoint)
}

extension SingleMessageNavigationAction {

    var isReplyAction: Bool {
        guard case .reply = self else { return false }
        return true
    }

    var isReplyAllAction: Bool {
        guard case .replyAll = self else { return false }
        return true
    }

    var isForwardAction: Bool {
        guard case .forward = self else { return false }
        return true
    }
}

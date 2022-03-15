//
//  SingleMessageNavigationAction.swift
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

enum SingleMessageNavigationAction: Equatable {
    case contacts(contact: ContactVO)
    case compose(contact: ContactVO)
    case viewHeaders(url: URL?)
    case viewHTML(url: URL?)
    case reply(messageId: String)
    case replyAll(messageId: String)
    case forward(messageId: String)
    case attachmentList(messageId: String, decryptedBody: String?)
    case url(url: URL)
    case inAppSafari(url: URL)
    case mailToUrl(url: URL)
    case addNewFolder
    case addNewLabel
    case viewCypher(url: URL)
    case more(messageId: String)
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

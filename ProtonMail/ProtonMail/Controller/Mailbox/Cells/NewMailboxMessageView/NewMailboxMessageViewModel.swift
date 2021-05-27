//
//  NewMailboxMessageViewModel.swift
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

struct NewMailboxMessageViewModel {
    let location: Message.Location?
    let isLabelLocation: Bool
    let style: NewMailboxMessageViewStyle
    let initial: NSAttributedString
    let isRead: Bool
    let sender: String
    let time: String
    let isForwarded: Bool
    let isReply: Bool
    let isReplyAll: Bool
    let topic: String
    let isStarred: Bool
    let hasAttachment: Bool
    let tags: [TagViewModel]
    let messageCount: Int
    var folderIcons: [UIImage]
}

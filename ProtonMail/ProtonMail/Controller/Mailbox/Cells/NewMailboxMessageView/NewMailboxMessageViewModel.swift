//
//  NewMailboxMessageViewModel.swift
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

import UIKit

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

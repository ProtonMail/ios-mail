//
//  MessageAction.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
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


import Foundation

enum MessageAction: String {
    
    // Draft
    case saveDraft = "saveDraft"
    
    // Attachment
    case uploadAtt = "uploadAtt"
    case uploadPubkey = "uploadPubkey"
    case deleteAtt = "deleteAtt"
    
    // Read/unread
    case read = "read"
    case unread = "unread"
    
    // Move mailbox
    case delete = "delete"
//    case inbox = "inbox"
//    case spam = "spam"
//    case trash = "trash"
//    case archive = "archive"
    
    // Send
    case send = "send"
    
    // Empty
    case emptyTrash = "emptyTrash"
    case emptySpam = "emptySpam"
    case empty = "empty"
    
    case label = "applyLabel"
    case unlabel = "unapplyLabel"
    case folder = "moveToFolder"
    
    case updateLabel = "updateLabel"
    case createLabel = "createLabel"
    case deleteLabel = "deleteLabel"
    case signout = "signout"
    case signin = "signin"
    case fetchMessageDetail = "fetchMessageDetail"
}

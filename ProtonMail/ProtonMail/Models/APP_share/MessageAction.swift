//
//  MessageAction.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
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

import Foundation

enum MessageAction: Equatable {
    enum NestedCodingKeys: CodingKey {
        case action
        case addedEmailIDs
        case messageObjectID
        case attachmentObjectID
        case attachmentID
        case objectIDs
        case objectID
        case currentLabelID
        case itemIDs
        case shouldFetch
        case nextLabelID
        case labelID
        case name
        case color
        case isFolder
        case addressID
        case contactID
        case cardDatas
        case emailIDs
        case removedEmailIDs
        case isSwipeAction
        case importFromDevice
        case deliveryTime
        case notificationAction
        case messageID
        case emailAddress
    }

    // Draft
    case saveDraft(messageObjectID: String)

    // Attachment
    case uploadAtt(attachmentObjectID: String)
    case uploadPubkey(attachmentObjectID: String)
    case deleteAtt(attachmentObjectID: String, attachmentID: String?)
    case updateAttKeyPacket(messageObjectID: String, addressID: String)

    // Read/unread
    case read(itemIDs: [String], objectIDs: [String])
    case unread(currentLabelID: String, itemIDs: [String], objectIDs: [String])

    // Move mailbox
    case delete(currentLabelID: String?, itemIDs: [String])

    // Send
    case send(messageObjectID: String, deliveryTime: Date?)

    // Empty
    case emptyTrash
    case emptySpam
    case empty(currentLabelID: String)

    case label(currentLabelID: String,
               shouldFetch: Bool?,
               isSwipeAction: Bool,
               itemIDs: [String],
               objectIDs: [String])
    case unlabel(currentLabelID: String,
                 shouldFetch: Bool?,
                 isSwipeAction: Bool,
                 itemIDs: [String],
                 objectIDs: [String])
    case folder(nextLabelID: String,
                shouldFetch: Bool?,
                isSwipeAction: Bool,
                itemIDs: [String],
                objectIDs: [String])

    case updateLabel(labelID: String, name: String, color: String)
    case createLabel(name: String, color: String, isFolder: Bool)
    case deleteLabel(labelID: String)
    case signout
    case signin
    case fetchMessageDetail

    // Contact
    case updateContact(objectID: String, cardDatas: [CardData])
    case deleteContact(objectID: String)
    case addContact(objectID: String, cardDatas: [CardData], importFromDevice: Bool)
    case addContactGroup(objectID: String, name: String, color: String, emailIDs: [String])
    case updateContactGroup(objectID: String, name: String, color: String, addedEmailIDs: [String], removedEmailIDs: [String])
    case deleteContactGroup(objectID: String)

    // Push notification action
    case notificationAction(messageID: String, action: PushNotificationAction)

    case blockSender(emailAddress: String)
    case unblockSender(emailAddress: String)
}

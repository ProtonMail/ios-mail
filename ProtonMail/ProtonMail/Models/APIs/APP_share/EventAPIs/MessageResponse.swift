// Copyright (c) 2023 Proton Technologies AG
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

struct MessageResponse: Decodable {
    let id: String
    let action: Int
    let message: Message?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case action = "Action"
        case message = "Message"
    }

    struct Message: Decodable {
        let id: String
        let order: Int
        let conversationID: String
        let subject: String
        let unread: Int
        let sender: ConversationResponse.Sender
        let senderAddress: String
        let senderName: String
        let flags: Int
        let type: Int
        let isEncrypted: Int
        let isReplied: Int
        let isRepliedAll: Int
        let isForwarded: Int
        let isProton: Int
        let displaySenderImage: Int
        let bimiSelector: String?
        let toList: [ConversationResponse.Recipient]
        let ccList: [ConversationResponse.Recipient]
        let bccList: [ConversationResponse.Recipient]
        let time: Int
        let size: Int
        let numAttachments: Int
        let expirationTime: Int
        let addressID: String
        let externalID: String?
        let labelIDs: [String]
        let labelIDsAdded: [String]?
        let labelIDsRemoved: [String]?
        let attachmentsMetadata: [ConversationResponse.AttachmentMetadata]?
        let snoozeTime: Int

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case order = "Order"
            case conversationID = "ConversationID"
            case subject = "Subject"
            case unread = "Unread"
            case sender = "Sender"
            case senderAddress = "SenderAddress"
            case senderName = "SenderName"
            case flags = "Flags"
            case type = "Type"
            case isEncrypted = "IsEncrypted"
            case isReplied = "IsReplied"
            case isRepliedAll = "IsRepliedAll"
            case isForwarded = "IsForwarded"
            case isProton = "IsProton"
            case displaySenderImage = "DisplaySenderImage"
            case bimiSelector = "BimiSelector"
            case toList = "ToList"
            case ccList = "CCList"
            case bccList = "BCCList"
            case time = "Time"
            case size = "Size"
            case numAttachments = "NumAttachments"
            case expirationTime = "ExpirationTime"
            case addressID = "AddressID"
            case externalID = "ExternalID"
            case labelIDs = "LabelIDs"
            case labelIDsAdded = "LabelIDsAdded"
            case labelIDsRemoved = "LabelIDsRemoved"
            case attachmentsMetadata = "AttachmentsMetadata"
            case snoozeTime = "SnoozeTime"
        }
    }
}

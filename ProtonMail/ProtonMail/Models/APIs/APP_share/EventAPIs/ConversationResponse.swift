// swiftlint:disable nesting
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

struct ConversationResponse: Decodable {
    let id: String
    let action: Int
    let conversation: Conversation?

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case action = "Action"
        case conversation = "Conversation"
    }

    struct Conversation: Decodable {
        let id: String
        let order: Int
        let subject: String
        let senders: [Sender]
        let recipients: [Recipient]
        let numMessages: Int
        let numUnread: Int
        let numAttachments: Int
        let expirationTime: Int
        let size: Int
        let isProton: Int
        let displaySenderImage: Int
        let bimiSelector: String?
        let labels: [ContextLabel]
        let attachmentsMetadata: [AttachmentMetadata]?
        let displaySnoozedReminder: Bool

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case order = "Order"
            case subject = "Subject"
            case senders = "Senders"
            case recipients = "Recipients"
            case numMessages = "NumMessages"
            case numUnread = "NumUnread"
            case numAttachments = "NumAttachments"
            case expirationTime = "ExpirationTime"
            case size = "Size"
            case isProton = "IsProton"
            case displaySenderImage = "DisplaySenderImage"
            case bimiSelector = "BimiSelector"
            case labels = "Labels"
            case attachmentsMetadata = "AttachmentsMetadata"
            case displaySnoozedReminder = "DisplaySnoozedReminder"
        }
    }

    struct Sender: Codable {
        let name: String
        let address: String
        let isProton: Int
        let displaySenderImage: Int
        let bimiSelector: String?
        let isSimpleLogin: Int

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case address = "Address"
            case isProton = "IsProton"
            case displaySenderImage = "DisplaySenderImage"
            case bimiSelector = "BimiSelector"
            case isSimpleLogin = "IsSimpleLogin"
        }
    }

    struct Recipient: Codable {
        let name: String
        let address: String
        let isProton: Int
        let group: String?

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case address = "Address"
            case isProton = "IsProton"
            case group = "Group"
        }
    }

    struct ContextLabel: Decodable {
        let id: String
        let contextNumMessages: Int
        let contextNumUnread: Int
        let contextTime: Int
        let contextExpirationTime: Int?
        let contextSize: Int
        let contextNumAttachments: Int
        let contextSnoozeTime: Int?

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case contextNumMessages = "ContextNumMessages"
            case contextNumUnread = "ContextNumUnread"
            case contextTime = "ContextTime"
            case contextExpirationTime = "ContextExpirationTime"
            case contextSize = "ContextSize"
            case contextNumAttachments = "ContextNumAttachments"
            case contextSnoozeTime = "ContextSnoozeTime"
        }
    }

    struct AttachmentMetadata: Codable {
        let id: String
        let name: String
        let size: Int
        let MIMEType: String
        let disposition: String

        enum CodingKeys: String, CodingKey {
            case id = "ID"
            case name = "Name"
            case size = "Size"
            case MIMEType = "MIMEType"
            case disposition = "Disposition"
        }
    }
}
// swiftlint:enable nesting

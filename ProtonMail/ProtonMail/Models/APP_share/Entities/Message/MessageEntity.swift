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

struct MessageHeaderKey {
    static let autoReply = "X-Autoreply"
    static let autoReplyFrom = "X-Autoreply-From"
    static let autoRespond = "X-Autorespond"
    static let mailAutoReply = "X-Mail-Autoreply"
    static let dispositionNotificationTo = "Disposition-Notification-To"
    static let listID = "List-Id"
    static let listUnsubscribe = "List-Unsubscribe"
    static let listSubscribe = "List-Subscribe"
    static let listPost = "List-Post"
    static let listHelp = "List-Help"
    static let listOwner = "List-Owner"
    static let listArchive = "List-Archive"
    static let pmRecipientEncryption = "X-Pm-Recipient-Encryption"
    static let pmRecipientAuthentication = "X-Pm-Recipient-Authentication"
    static let pmOrigin = "X-Pm-Origin"
    static let pmContentEncryption = "X-Pm-Content-Encryption"
}

struct MessageEntity: Equatable, Hashable {

    // MARK: Identifiers

    let messageID: MessageID
    let addressID: AddressID
    let conversationID: ConversationID
    let userID: UserID

    // MARK: Message metadata

    let numAttachments: Int
    let size: Int
    let spamScore: SpamScore

    let rawHeader: String?
    let rawParsedHeaders: String?

    let rawFlag: Int
    var flag: MessageFlag { MessageFlag(rawValue: rawFlag) }

    let time: Date?
    let expirationTime: Date?

    let order: Int
    let unRead: Bool
    let unsubscribeMethods: UnsubscribeMethods?

    // MARK: Message content

    let title: String

    /// "Sender": { "Address":"", "Name":"" }
    let rawSender: String?

    /// "ToList":[ { "Address":"", "Name":"", "Group": ""} ]
    let rawTOList: String
    /// "CCList":[ { "Address":"", "Name":"", "Group": ""} ]
    let rawCCList: String
    /// "BCCList":[ { "Address":"", "Name":"", "Group": ""} ]
    let rawBCCList: String
    /// "ReplyTos": [{"Address":"", "Name":""}]
    let rawReplyTos: String

    // recipients email addresses
    let recipientsTo: [String]
    let recipientsCc: [String]
    let recipientsBcc: [String]

    let replyTo: [String]

    let mimeType: String?

    /// "Body":"-----BEGIN PGP MESSAGE-----.*-----END PGP MESSAGE-----"
    let body: String

    // MARK: Relations

    private(set) var attachments: [AttachmentEntity]
    private(set) var labels: [LabelEntity]

    // MARK: Local properties

    /// To record the addressID when user change the sender address
    /// Before executing the updateAttKeyPacket action, this variable keep holding the addressID that should show
    /// after the action finish and the message.addressID is equal nextAddressID, this variable will be reset to nil
    private(set) var nextAddressID: AddressID?
    /// For sending set expiration offset
    let expirationOffset: Int
    /// To mark this conversation is deleted
    /// (usually caused by empty trash/ spam action)
    let isSoftDeleted: Bool
    /// Check if details downloaded
    let isDetailDownloaded: Bool
    /// To check if message has metadata or not. some logic will fetch the metadata based on this
    let hasMetaData: Bool
    /// To check draft latest update time to decide pick cache or remote. should use the server time.
    let lastModified: Date?
    /// Only when send/draft/reply/forward. to track the original message id
    private(set) var originalMessageID: MessageID?
    /// For sending. original message time. sometimes need it in the body
    let originalTime: Date?

    let passwordEncryptedBody: String
    let password: String
    let passwordHint: String

    let objectID: ObjectID

    var sender: ContactVO? {
        rawSender?.toContact()
    }

    var parsedHeaders: [String: Any] {
        rawParsedHeaders?.parseObjectAny() ?? [:]
    }

    // swiftlint:disable:function_body_length
    init(_ message: Message) {
        self.messageID = MessageID(message.messageID)
        self.addressID = AddressID(message.addressID ?? "")
        self.conversationID = ConversationID(message.conversationID)
        self.userID = UserID(message.userID)

        self.numAttachments = message.numAttachments.intValue
        self.size = message.size.intValue
        self.spamScore = SpamScore(rawValue: message.spamScore.intValue)

        self.rawHeader = message.header
        self.rawParsedHeaders = message.parsedHeaders

        self.rawFlag = message.flags.intValue

        self.time = message.time
        self.expirationTime = message.expirationTime

        self.order = message.order.intValue
        self.unRead = message.unRead
        self.unsubscribeMethods = MessageEntity.parseUnsubscribeMethods(from: message.unsubscribeMethods)

        self.title = message.title

        self.rawSender = message.sender

        self.rawTOList = message.toList
        self.rawCCList = message.ccList
        self.rawBCCList = message.bccList
        self.rawReplyTos = message.replyTos ?? ""

        self.recipientsTo = Message.contactsToAddressesArray(message.toList)
        self.recipientsCc = Message.contactsToAddressesArray(message.ccList)
        self.recipientsBcc = Message.contactsToAddressesArray(message.bccList)
        self.replyTo = Message.contactsToAddressesArray(message.replyTos)

        self.mimeType = message.mimeType
        self.body = message.body

        self.attachments = AttachmentEntity.convert(from: message.attachments)
        self.labels = LabelEntity.convert(from: message.labels)

        if let id = message.nextAddressID {
            self.nextAddressID = AddressID(id)
        }
        self.expirationOffset = Int(message.expirationOffset)
        self.isSoftDeleted = message.isSoftDeleted
        self.isDetailDownloaded = message.isDetailDownloaded
        self.hasMetaData = message.messageStatus.boolValue
        self.lastModified = message.lastModified
        if let originalMessageID = message.orginalMessageID {
            self.originalMessageID = .init(rawValue: originalMessageID)
        }
        self.originalTime = message.orginalTime
        self.passwordEncryptedBody = message.passwordEncryptedBody
        self.password = message.password
        self.passwordHint = message.passwordHint
        self.objectID = .init(rawValue: message.objectID)
    }

    private static func parseUnsubscribeMethods(from jsonString: String?) -> UnsubscribeMethods? {
        if let method = jsonString,
           let data = method.data(using: .utf8) {
            return try? JSONDecoder().decode(UnsubscribeMethods?.self, from: data)
        }
        return nil
    }
}

#if DEBUG
extension MessageEntity {
    mutating func setAttachment(_ attachment: AttachmentEntity) {
        self.attachments.append(attachment)
    }

    mutating func setLabels(_ labels: [LabelEntity]) {
        self.labels = labels
    }
}
#endif

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
    // MARK: Properties
    private(set) var addressID: AddressID
    /// "BCCList":[ { "Address":"", "Name":"", "Group": ""} ]
    private(set) var rawBCCList: String
    /// "Body":"-----BEGIN PGP MESSAGE-----.*-----END PGP MESSAGE-----"
    private(set) var body: String
    /// "CCList":[ { "Address":"", "Name":"", "Group": ""} ]
    private(set) var rawCCList: String
    private(set) var conversationID: ConversationID
    private(set) var expirationTime: Date?
    private var rawFlag: Int
    var flag: MessageFlag { MessageFlag(rawValue: rawFlag) }

    private(set) var messageID: MessageID
    private(set) var mimeType: String?
    private(set) var numAttachments: Int
    private(set) var rawParsedHeaders: String?
    let rawHeader: String?
    /// "ReplyTos": [{"Address":"", "Name":""}]
    private(set) var rawReplyTos: String
    /// "Sender": { "Address":"", "Name":"" }
    private(set) var rawSender: String?
    private(set) var size: Int
    private(set) var spamScore: SpamScore
    private(set) var time: Date?
    private(set) var title: String
    /// "ToList":[ { "Address":"", "Name":"", "Group": ""} ]
    private(set) var rawTOList: String
    private(set) var unRead: Bool
    private(set) var userID: UserID
    private(set) var unsubscribeMethods: UnsubscribeMethods?
    private(set) var order: Int

    // MARK: Relations
    private(set) var attachments: [AttachmentEntity]
    private(set) var labels: [LabelEntity]

    // MARK: Local properties
    /// To record the addressID when user change the sender address
    /// Before executing the updateAttKeyPacket action, this variable keep holding the addressID that should show
    /// after the action finish and the message.addressID is equal nextAddressID, this variable will be reset to nil
    private(set) var nextAddressID: AddressID?
    /// For sending set expiration offset
    private(set) var expirationOffset: Int
    /// To mark this conversation is deleted
    /// (usually caused by empty trash/ spam action)
    private(set) var isSoftDeleted: Bool
    /// Check if details downloaded
    private(set) var isDetailDownloaded: Bool
    private(set) var isSending: Bool
    /// To check if message has metadata or not. some logic will fetch the metadata based on this
    private(set) var hasMetaData: Bool
    /// To check draft latest update time to decide pick cache or remote. should use the server time.
    private(set) var lastModified: Date?
    /// Only when send/draft/reply/forward. to track the original message id
    private(set) var originalMessageID: MessageID?
    /// For sending. original message time. sometimes need it in the body
    private(set) var originalTime: Date?
    /// The encrypted body encrypt by password
    private(set) var passwordEncryptedBody: String
    /// The password
    private(set) var password: String
    /// Password hint
    private(set) var passwordHint: String
    /// Transient
    private(set) var cachedPassphraseRaw: Data? // transient
    /// Transient
    /// can this be kind of transient relationship?
    private(set) var cachedPrivateKeysRaw: Data?
    /// transient
    private(set) var cachedAuthCredentialRaw: Data?
    /// Transient
    /// addresses can also be in db,
    /// currently they are received from UserInfo singleton via message.defaultAddress getter
    private(set) var cachedAddressRaw: Data?

    let objectID: ObjectID

    var bccList: [ContactPickerModelProtocol] {
        ContactPickerModelHelper.contacts(from: self.rawBCCList)
    }

    var ccList: [ContactPickerModelProtocol] {
        ContactPickerModelHelper.contacts(from: self.rawCCList)
    }

    var toList: [ContactPickerModelProtocol] {
        ContactPickerModelHelper.contacts(from: self.rawTOList)
    }

    var replyTos: [ContactPickerModelProtocol] {
        ContactPickerModelHelper.contacts(from: self.rawReplyTos)
    }

    var sender: ContactVO? {
        rawSender?.toContact()
    }

    var parsedHeaders: [String: Any] {
        rawParsedHeaders?.parseObjectAny() ?? [:]
    }

    // swiftlint:disable:next function_body_length
    init(_ message: Message) {
        self.addressID = AddressID(message.addressID ?? "")
        self.rawBCCList = message.bccList
        self.body = message.body
        self.rawCCList = message.ccList
        self.conversationID = ConversationID(message.conversationID)
        self.expirationTime = message.expirationTime
        self.rawFlag = message.flags.intValue
        self.rawParsedHeaders = message.parsedHeaders
        self.rawHeader = message.header
        self.messageID = MessageID(message.messageID)
        self.mimeType = message.mimeType
        self.numAttachments = message.numAttachments.intValue
        self.rawReplyTos = message.replyTos ?? ""
        self.rawSender = message.sender
        self.size = message.size.intValue
        self.spamScore = SpamScore(rawValue: message.spamScore.intValue)
        self.time = message.time
        self.title = message.title
        self.rawTOList = message.toList
        self.unRead = message.unRead
        self.userID = UserID(message.userID)
        self.unsubscribeMethods = MessageEntity
            .parseUnsubscribeMethods(from: message.unsubscribeMethods)
        self.order = message.order.intValue

        self.attachments = AttachmentEntity.convert(from: message.attachments)
        self.labels = LabelEntity.convert(from: message.labels)

        if let id = message.nextAddressID {
            self.nextAddressID = AddressID(id)
        }
        self.expirationOffset = Int(message.expirationOffset)
        self.isSoftDeleted = message.isSoftDeleted
        self.isDetailDownloaded = message.isDetailDownloaded
        self.isSending = message.isSending
        self.hasMetaData = message.messageStatus.boolValue
        self.lastModified = message.lastModified
        if let originalMessageID = message.orginalMessageID {
            self.originalMessageID = .init(rawValue: originalMessageID)
        }
        self.originalTime = message.orginalTime
        self.passwordEncryptedBody = message.passwordEncryptedBody
        self.password = message.password
        self.passwordHint = message.passwordHint
        self.cachedPassphraseRaw = message.cachedPassphraseRaw as Data?
        self.cachedPrivateKeysRaw = message.cachedPrivateKeysRaw as Data?
        self.cachedAuthCredentialRaw = message.cachedAuthCredentialRaw as Data?
        self.cachedAddressRaw = message.cachedAddressRaw as Data?
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

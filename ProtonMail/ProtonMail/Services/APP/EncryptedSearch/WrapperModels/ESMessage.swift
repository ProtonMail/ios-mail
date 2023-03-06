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

import CoreData
import CryptoKit
import Foundation
import ProtonCore_DataModel
import ProtonCore_Services

struct ESSender: Codable {
    var name: String = ""
    var address: String = ""
    var group: String = ""

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case address = "Address"
        case group = "Group"
    }
}

final class ESMessage: Codable {
    // variables that are fetched with getMessage
    private(set) var id: String = ""
    private(set) var order: Int = 0
    private(set) var conversationID: String = ""
    private(set) var subject: String = ""
    private(set) var unread: Int = 0
    private(set) var `type`: Int = 0
    private(set) var senderAddress: String = ""
    private(set) var senderName: String = ""
    private(set) var sender: ESSender = ESSender(name: "", address: "")
    // public var replyTo: String
    // public var replyTos: String
    private(set) var toList: [ESSender?] = []
    private(set) var cCList: [ESSender?] = []
    private(set) var bCCList: [ESSender?] = []
    private(set) var time: Double = 0
    private(set) var size: Int = 0
    private(set) var isEncrypted: Int = 0
    // set default for Fri Jan 01 2100 23:59:59 GMT+0100
    private(set) var expirationTime: Date? = Date(timeIntervalSince1970: 4_102_527_599)
    private(set) var isReplied: Int = 0
    private(set) var isRepliedAll: Int = 0
    private(set) var isForwarded: Int = 0
    private(set) var spamScore: Int? = 0
    private(set) var addressID: String? = ""
    private(set) var numAttachments: Int = 0
    private(set) var flags: Int = 0
    private(set) var labelIDs: Set<String> = Set<String>()
    private(set) var externalID: String? = ""
    // public var unsubscribeMethods: String?

    // variables that are fetched with getMessageDetails
    // public var attachments: Set<Any>
    private(set) var body: String? = ""
    private(set) var header: String? = ""
    private(set) var mimeType: String? = ""
    // public var ParsedHeaders: String?
    private(set) var userID: String? = ""

    // local variables
    // swiftlint:disable discouraged_optional_boolean
    var isStarred: Bool? = false
    // swiftlint:disable discouraged_optional_boolean
    var isDetailsDownloaded: Bool? = false
    // var tempAtts: [MimeAttachment]? = nil

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case order = "Order"
        case conversationID = "ConversationID"
        case subject = "Subject"
        case unread = "Unread"
        case `type` = "Type"
        case senderAddress = "SenderAddress"
        case senderName = "SenderName"
        case time = "Time"
        case size = "Size"
        case isEncrypted = "IsEncrypted"
        case expirationTime = "ExpirationTime"
        case isReplied = "IsReplied"
        case isRepliedAll = "IsRepliedAll"
        case isForwarded = "IsForwarded"
        case spamScore = "SpamScore"
        case addressID = "AddressID"
        case numAttachments = "NumAttachments"
        case flags = "Flags"
        case externalID = "ExternalID"
        case body = "Body"
        case header = "Header"
        case mimeType = "MimeType"
        case userID = "UserID"
        case toList = "ToList"
        case cCList = "CCList"
        case bCCList = "BCCList"
    }

    init(id: String,
         order: Int,
         conversationID: String,
         subject: String,
         unread: Int,
         type: Int,
         senderAddress: String,
         senderName: String,
         sender: ESSender,
         toList: [ESSender?],
         ccList: [ESSender?],
         bccList: [ESSender?],
         time: Double,
         size: Int,
         isEncrypted: Int,
         expirationTime: Date?,
         isReplied: Int,
         isRepliedAll: Int,
         isForwarded: Int,
         spamScore: Int?,
         addressID: String?,
         numAttachments: Int,
         flags: Int,
         labelIDs: Set<String>,
         externalID: String?,
         body: String?,
         header: String?,
         mimeType: String?,
         userID: String) {
        self.id = id
        self.order = order
        self.conversationID = conversationID
        self.subject = subject
        self.unread = unread
        self.`type` = type
        self.senderAddress = senderAddress
        self.senderName = senderName
        self.sender = sender
        self.toList = toList
        self.cCList = ccList
        self.bCCList = bccList
        self.time = time
        self.size = size
        self.isEncrypted = isEncrypted
        self.expirationTime = expirationTime
        self.isReplied = isReplied
        self.isRepliedAll = isRepliedAll
        self.isForwarded = isForwarded
        self.spamScore = spamScore
        self.addressID = addressID
        self.numAttachments = numAttachments
        self.flags = flags
        self.labelIDs = labelIDs
        self.externalID = externalID
        self.body = body
        self.header = header
        self.mimeType = mimeType
        self.userID = userID
    }
}

extension ESMessage {
    // swiftlint:disable next function_body_length
    func toEntity() -> MessageEntity {
        assert(addressID != nil)
        assert(userID != nil)
        assert(body != nil)

        return MessageEntity(
            messageID: MessageID(id),
            addressID: AddressID(addressID ?? ""),
            conversationID: ConversationID(conversationID),
            userID: UserID(userID ?? ""),
            action: nil,
            numAttachments: numAttachments,
            size: size,
            spamScore: SpamScore(rawValue: spamScore ?? 0),
            rawHeader: header,
            rawParsedHeaders: nil,
            rawFlag: flags,
            time: Date(timeIntervalSince1970: time),
            expirationTime: expirationTime,
            order: order,
            unRead: false,
            unsubscribeMethods: nil,
            title: subject,
            rawSender: ESSenderToJSONString(sender: sender),
            rawTOList: ESSenderArrayToJsonString(senderArray: toList),
            rawCCList: ESSenderArrayToJsonString(senderArray: cCList),
            rawBCCList: ESSenderArrayToJsonString(senderArray: bCCList),
            rawReplyTos: .empty,
            recipientsTo: [],
            recipientsCc: [],
            recipientsBcc: [],
            replyTo: [],
            mimeType: mimeType,
            body: body ?? "",
            attachments: [],
            labels: [],
            expirationOffset: 0,
            isSoftDeleted: false,
            isDetailDownloaded: isDetailsDownloaded ?? false,
            hasMetaData: true,
            lastModified: nil,
            originalTime: nil,
            passwordEncryptedBody: .empty,
            password: .empty,
            passwordHint: .empty,
            objectID: .init(rawValue: .init())
        )
    }

    private func ESSenderArrayToJsonString(senderArray: [ESSender?]) -> String {
        guard senderArray.isEmpty == false else {
            return ""
        }

        var jsonString: String = "["
        senderArray.forEach { sender in
            let senderString: String = (self.ESSenderToJSONString(sender: sender) ?? "") + ", "
            jsonString.append(senderString)
        }
        jsonString.append("]")
        return jsonString
    }

    private func ESSenderToJSONString(sender: ESSender?) -> String? {
        let encoder = JSONEncoder()
        var jsonString: String? = ""
        do {
            if let sender = sender {
                let data = try encoder.encode(sender)
                jsonString = String(data: data, encoding: .utf8)
            }
        } catch {
            print("Error when encoding ESSender to json string: \(error)")
        }
        return jsonString
    }
}

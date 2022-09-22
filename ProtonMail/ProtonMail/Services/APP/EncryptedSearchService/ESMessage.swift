// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import CoreData
import CryptoKit
import Foundation
import ProtonCore_DataModel
import ProtonCore_Services

struct ESSender: Codable {
    var name: String = ""
    var address: String = ""

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case address = "Address"
    }
}

public class ESMessage: Codable {
    // variables that are fetched with getMessage
    public var id: String = ""
    public var order: Int = 0
    public var conversationID: String = ""
    public var subject: String = ""
    public var unread: Int = 0
    public var `type`: Int = 0
    public var senderAddress: String = ""
    public var senderName: String = ""
    var sender: ESSender = ESSender(name: "", address: "")
    // public var replyTo: String
    // public var replyTos: String
    var toList: [ESSender?] = []
    var cCList: [ESSender?] = []
    var bCCList: [ESSender?] = []
    public var time: Double = 0
    public var size: Int = 0
    public var isEncrypted: Int = 0
    // set default for Fri Jan 01 2100 23:59:59 GMT+0100
    public var expirationTime: Date? = Date(timeIntervalSince1970: 4_102_527_599)
    public var isReplied: Int = 0
    public var isRepliedAll: Int = 0
    public var isForwarded: Int = 0
    public var spamScore: Int? = 0
    public var addressID: String? = ""
    public var numAttachments: Int = 0
    public var flags: Int = 0
    public var labelIDs: Set<String> = Set<String>()
    public var externalID: String? = ""
    // public var unsubscribeMethods: String?

    // variables that are fetched with getMessageDetails
    // public var attachments: Set<Any>
    public var body: String? = ""
    public var header: String? = ""
    public var mimeType: String? = ""
    // public var ParsedHeaders: String?
    public var userID: String? = ""

    // local variables
    // swiftlint:disable discouraged_optional_boolean
    public var isStarred: Bool? = false
    // swiftlint:disable discouraged_optional_boolean
    public var isDetailsDownloaded: Bool? = false
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

    /// check if contains exclusive lable
    ///
    /// - Parameter label: Location
    /// - Returns: yes or no
    internal func contains(label: Message.Location) -> Bool {
        return self.contains(label: label.rawValue)
    }

    /// check if contains the lable
    ///
    /// - Parameter labelID: label id
    /// - Returns: yes or no
    internal func contains(label labelID: String) -> Bool {
        let labels = self.labelIDs
        for l in labels {
            if let label = l as? Label, labelID == label.labelID {
                return true
            }
        }
        return false
    }

    // check if message contains a draft label
    var draft: Bool {
        contains(label: Message.Location.draft) || contains(label: Message.HiddenLocation.draft.rawValue)
    }

    var flag: Message.Flag? {
        get {
            return Message.Flag(rawValue: self.flags)
        }
        set {
            self.flags = newValue!.rawValue
        }
    }

    // signed mime also external message
    var isExternal: Bool? {
        get {
            return !self.flag!.contains(.internal) && self.flag!.contains(.received)
        }
    }

    // 7  & 8
    var isE2E: Bool? {
        get {
            return self.flag!.contains(.e2e)
        }
    }
}

extension ESMessage {
    func toMessage() -> Message {
        // Add message to maincontext as otherwise there are faults when accessing the message
        let context = CoreDataService.shared.mainContext
        // swiftlint:disable force_cast
        let message = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message

        // Add attributes of all neccessary fields
        message.bccList = self.ESSenderArrayToJsonString(senderArray: self.bCCList)
        message.body = self.body ?? ""
        message.ccList = self.ESSenderArrayToJsonString(senderArray: self.cCList)
        message.expirationOffset = 0    // Set default value
        message.flags = NSNumber(value: self.flags)
        message.isDetailDownloaded = self.isDetailsDownloaded ?? false
        message.messageID = self.id
        message.messageStatus = 0   // Set default value
        message.messageType = NSNumber(value: self.`type`)
        message.numAttachments = NSNumber(value: self.numAttachments)
        message.passwordEncryptedBody = ""  // Set default value
        message.password = ""   // Set default value
        message.passwordHint = ""   // Set default value
        message.size = NSNumber(value: self.size)
        message.spamScore = NSNumber(value: self.spamScore ?? 0)
        message.title = self.subject
        message.toList = self.ESSenderArrayToJsonString(senderArray: self.toList)
        message.unRead = self.unread != 0
        message.userID = self.userID ?? ""
        message.conversationID = self.conversationID
        message.attachments = []    // Set default value
        let labels = NSSet()
        labels.addingObjects(from: self.labelIDs)
        message.labels = labels
        message.order = NSNumber(value: self.order)

        // Optional fields
        // message.action
        // message.addressID
        // message.nextAddressID
        // message.cachedPassphraseRaw
        // message.cachedPrivateKeysRaw
        // message.cachedAuthCredentialRaw
        // message.cachedAddressRaw
        // message.expirationTime = self.ExpirationTime
        // message.header
        // message.lastModified
        // message.mimeType
        // message.originalMessageID
        // message.originalTime
        // message.replyTos = self.ESSenderArrayToJsonString(senderArray: [self.Sender])
        message.sender = self.ESSenderToJSONString(sender: self.sender)
        message.time = Date(timeIntervalSince1970: self.time)
        // message.unsubscribeMethods

        // delete message from context to remove duplicates
        context.delete(message)

        return message
    }

    private func ESSenderArrayToJsonString(senderArray: [ESSender?]) -> String {
        guard senderArray.isEmpty == false else {
            return ""
        }

        var jsonString: String = "["
        senderArray.forEach { sender in
            let senderString: String = (self.ESSenderToJSONString(sender: sender!) ?? "") + ", "
            jsonString.append(senderString)
        }
        jsonString.append("]")
        return jsonString
    }

    private func ESSenderToJSONString(sender: ESSender) -> String? {
        let encoder = JSONEncoder()
        var jsonString: String? = ""
        do {
            let data = try encoder.encode(sender)
            jsonString = String(data: data, encoding: .utf8)
        } catch {
            print("Error when encoding ESSender to json string: \(error)")
        }
        return jsonString
    }
}

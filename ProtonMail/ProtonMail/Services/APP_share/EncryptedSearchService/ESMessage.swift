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

import Foundation
import CryptoKit

import ProtonCore_Services
import ProtonCore_DataModel
import CoreData


struct ESSender: Codable {
    var Name: String = ""
    var Address: String = ""
}

public class ESMessage: Codable {
    // variables that are fetched with getMessage
    public var ID: String = ""
    public var Order: Int = 0
    public var ConversationID: String = ""
    public var Subject: String = ""
    public var Unread: Int = 0
    public var `Type`: Int = 0
    public var SenderAddress: String = ""
    public var SenderName: String = ""
    var Sender: ESSender = ESSender(Name: "", Address: "")
    //public var replyTo: String
    //public var replyTos: String
    var ToList: [ESSender?] = []
    var CCList: [ESSender?] = []
    var BCCList: [ESSender?] = []
    public var Time: Double = 0
    public var Size: Int = 0
    public var IsEncrypted: Int = 0
    public var ExpirationTime: Date? = Date(timeIntervalSince1970: 4102527599) // set detault for Fri Jan 01 2100 23:59:59 GMT+0100
    public var IsReplied: Int = 0
    public var IsRepliedAll: Int = 0
    public var IsForwarded: Int = 0
    public var SpamScore: Int? = 0
    public var AddressID: String? = ""
    public var NumAttachments: Int = 0
    public var Flags: Int = 0
    public var LabelIDs: Set<String> = Set<String>()
    public var ExternalID: String? = ""
    // public var unsubscribeMethods: String?

    // variables that are fetched with getMessageDetails
    // public var attachments: Set<Any>
    public var Body: String? = ""
    public var Header: String? = ""
    public var MIMEType: String? = ""
    // public var ParsedHeaders: String?
    public var UserID: String? = ""

    // local variables
    public var isStarred: Bool? = false
    public var isDetailsDownloaded: Bool? = false
    //var tempAtts: [MimeAttachment]? = nil //TODO make decodable

    init(id: String, order: Int, conversationID: String, subject: String, unread: Int, type: Int, senderAddress: String, senderName: String, sender: ESSender, toList: [ESSender?], ccList: [ESSender?], bccList: [ESSender?], time: Double, size: Int, isEncrypted: Int, expirationTime: Date?, isReplied: Int, isRepliedAll: Int, isForwarded: Int, spamScore: Int?, addressID: String?, numAttachments: Int, flags: Int, labelIDs: Set<String>, externalID: String?, body: String?, header: String?, mimeType: String?, userID: String) {
        self.ID = id
        self.Order = order
        self.ConversationID = conversationID
        self.Subject = subject
        self.Unread = unread
        self.`Type` = type
        self.SenderAddress = senderAddress
        self.SenderName = senderName
        self.Sender = sender
        self.ToList = toList
        self.CCList = ccList
        self.BCCList = bccList
        self.Time = time
        self.Size = size
        self.IsEncrypted = isEncrypted
        self.ExpirationTime = expirationTime
        self.IsReplied = isReplied
        self.IsRepliedAll = isRepliedAll
        self.IsForwarded = isForwarded
        self.SpamScore = spamScore
        self.AddressID = addressID
        self.NumAttachments = numAttachments
        self.Flags = flags
        self.LabelIDs = labelIDs
        self.ExternalID = externalID
        self.Body = body
        self.Header = header
        self.MIMEType = mimeType
        self.UserID = userID
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
    internal func contains(label labelID : String) -> Bool {
        let labels = self.LabelIDs
        for l in labels {
            //TODO
            if let label = l as? Label, labelID == label.labelID {
                return true
            }
        }
        return false
    }
    
    /// check if message contains a draft label
    var draft : Bool {
        contains(label: Message.Location.draft) || contains(label: Message.HiddenLocation.draft.rawValue)
    }
    
    var flag : Message.Flag? {
        get {
            return Message.Flag(rawValue: self.Flags)
        }
        set {
            self.Flags = newValue!.rawValue
        }
    }
    
    //signed mime also external message
    var isExternal : Bool? {
        get {
            return !self.flag!.contains(.internal) && self.flag!.contains(.received)
        }
    }
    
    // 7  & 8
    var isE2E : Bool? {
        get {
            return self.flag!.contains(.e2e)
        }
    }
    
    var isPlainText : Bool {
        get {
            if let type = MIMEType, type.lowercased() == Message.MimeType.plainText {
                return true
            }
            return false
        }
    }
    
    var isMultipartMixed : Bool {
        get {
            if let type = MIMEType, type.lowercased() == Message.MimeType.mutipartMixed {
                return true
            }
            return false
        }
    }
    
    //case outPGPInline = 7
    var isPgpInline : Bool {
        get {
            if isE2E!, !isPgpMime! {
                return true
            }
            return false
        }
    }
    
    //case outPGPMime = 8       // out pgp mime
    var isPgpMime : Bool? {
        get {
            if let mt = self.MIMEType, mt.lowercased() == Message.MimeType.mutipartMixed, isExternal!, isE2E! {
                return true
            }
            return false
        }
    }
    
    //case outSignedPGPMime = 9 //PGP/MIME signed message
    var isSignedMime : Bool? {
        get {
            if let mt = self.MIMEType, mt.lowercased() == Message.MimeType.mutipartMixed, isExternal!, !isE2E! {
                return true
            }
            return false
        }
    }

    // Same function as Message+Extension.swift:320
    /*public func decryptBody(keys: [Key], passphrase: String) throws -> String? {
        var firstError: Error?
        var errorMessages: [String] = []
        for key in keys {
            do {
                let decryptedBody = try self.Body?.decryptMessageWithSingleKeyNonOptional(key.privateKey, passphrase: passphrase)
                    return decryptedBody
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
            }
        }

        if let error = firstError {
            throw error
        }
        return nil
    }*/

    /*public func decryptBody(keys: [Key], userKeys: [Data], passphrase: String) throws -> String? {
        var firstError: Error?
        var errorMessages: [String] = []
        for key in keys {
            do {
                let addressKeyPassphrase = try MailCrypto.getAddressKeyPassphrase(userKeys: userKeys,
                                                   passphrase: passphrase,
                                                   key: key)
                let decryptedBody = try self.Body?.decryptMessageWithSingleKeyNonOptional(key.privateKey, passphrase: addressKeyPassphrase)
                return decryptedBody
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
            }
        }
        return nil
    }*/
}

extension ESMessage {
    func toMessage() -> Message {
        let context = CoreDataService.shared.mainContext
        let message = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message

        // Add attributes of all neccessary fields
        message.bccList = self.ESSenderArrayToJsonString(senderArray: self.BCCList)
        message.body = self.Body ?? ""
        message.ccList = self.ESSenderArrayToJsonString(senderArray: self.CCList)
        //message.expirationOffset
        message.flags = NSNumber(value: self.Flags)
        message.isDetailDownloaded = self.isDetailsDownloaded ?? false
        message.messageID = self.ID
        //message.messageStatus
        message.messageType = NSNumber(value: self.`Type`)
        message.numAttachments = NSNumber(value: self.NumAttachments)
        //message.passwordEncryptedBody
        //message.password
        //message.passwordHint
        message.size = NSNumber(value: self.Size)
        message.spamScore = NSNumber(value: self.SpamScore ?? 0)
        message.title = self.Subject
        message.toList = self.ESSenderArrayToJsonString(senderArray: self.ToList)
        message.unRead = self.Unread != 0
        message.userID = self.UserID ?? ""
        //message.isSending
        message.conversationID = self.ConversationID
        //message.attachments
        let labels = NSSet()
        labels.addingObjects(from: self.LabelIDs)
        message.labels = labels
        message.order = NSNumber(value: self.Order)

        // Optional fields
        // message.action
        // message.addressID
        // message.nextAddressID
        // message.cachedPassphraseRaw
        // message.cachedPrivateKeysRaw
        // message.cachedAuthCredentialRaw
        // message.cachedAddressRaw
        // message.expirationTime = self.ExpirationTime // TODO
        // message.header
        // message.lastModified
        // message.mimeType
        // message.originalMessageID
        // message.originalTime
        // message.replyTos = self.ESSenderArrayToJsonString(senderArray: [self.Sender])
        message.sender = self.ESSenderToJSONString(sender: self.Sender)
        message.time = Date(timeIntervalSince1970: self.Time)
        // message.unsubscribeMethods

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

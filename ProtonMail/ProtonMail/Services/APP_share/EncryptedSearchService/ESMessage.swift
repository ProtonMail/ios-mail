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
    //variables that are fetched with getMessage
    public var ID: String = ""
    public var Order: Int
    public var ConversationID: String
    public var Subject: String
    public var Unread: Int
    public var `Type`: Int    //messagetype
    public var SenderAddress: String //TODO
    public var SenderName: String   //TODO
    var Sender: ESSender
    //public var replyTo: String  //not existing
    //public var replyTos: String //TODO
    var ToList: [ESSender?] = []
    var CCList: [ESSender?] = []
    var BCCList: [ESSender?] = []
    public var Time: Double
    public var Size: Int
    public var IsEncrypted: Int
    public var ExpirationTime: Date?
    public var IsReplied: Int
    public var IsRepliedAll: Int
    public var IsForwarded: Int
    public var SpamScore: Int?
    public var AddressID: String?   //needed for decryption
    public var NumAttachments: Int
    public var Flags: Int
    public var LabelIDs: Set<String>
    public var ExternalID: String?
    //public var unsubscribeMethods: String?
    
    //variables that are fetched with getMessageDetails
    //public var attachments: Set<Any>
    public var Body: String?
    public var Header: String?
    public var MIMEType: String?
    //public var ParsedHeaders: String? //String or class?
    public var UserID: String?

    //local variables
    public var Starred: Bool? = false
    public var isDetailsDownloaded: Bool? = false
    //var tempAtts: [AttachmentInline]? = nil
    
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
    
    public func decryptBody(keys: [Key], passphrase: String) throws -> String? {
        var firstError: Error?
        var errorMessages: [String] = []
        
        for key in keys {
            do {
                return try self.Body!.decryptMessageWithSinglKey(key.privateKey, passphrase: passphrase)
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
                //TODO temporary disable to have less output
                //PMLog.D(error.localizedDescription)
            }
        }
        
        let extra: [String: Any] = ["newSchema": false,
                                    "Ks count": keys.count,
                                    "Error message": errorMessages]
        
        if let error = firstError {
            Analytics.shared.error(message: .decryptedMessageBodyFailed,
                                   error: error,
                                   extra: extra)
            throw error
        }
        Analytics.shared.error(message: .decryptedMessageBodyFailed,
                               error: "No error from crypto library",
                               extra: extra)
        return nil
    }
    
    public func decryptBody(keys: [Key], userKeys: [Data], passphrase: String) throws -> String? {
        var firstError: Error?
        var errorMessages: [String] = []
        var newScheme: Int = 0
        var oldSchemaWithToken: Int = 0
        var oldSchema: Int = 0
        
        for key in keys {
            do {
                if let token = key.token, let signature = key.signature{
                    //have both means new schema. key is
                    newScheme += 1
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here Detached signature
                        // if failed return a warning
                        //PMLog.D(signature)    disable printing temporarily
                        //TODO
                        return try self.Body!.decryptMessageWithSinglKey(key.privateKey, passphrase: plaitToken)
                    }
                } else if let token = key.token { //old schema with token - subuser. key is embed singed
                    oldSchemaWithToken += 1
                    if let plaitToken = try token.decryptMessage(binKeys: userKeys, passphrase: passphrase) {
                        //TODO:: try to verify signature here embeded signature
                        return try self.Body!.decryptMessageWithSinglKey(key.privateKey, passphrase: plaitToken)
                    }
                } else { //normal key old schema
                    oldSchema += 1
                    return try self.Body!.decryptMessage(binKeys: keys.binPrivKeysArray, passphrase: passphrase)
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
                //TODO temporary disable to have less output
                //PMLog.D(error.localizedDescription)
            }
        }
        return nil
    }
}

extension ESMessage {
    func toMessage() -> Message {
        let context = CoreDataService.shared.mainContext
        let message = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message
        
        // Add attributes of all neccessary fields
        //message.bccList = self.BCCList    TODO
        message.body = self.Body ?? ""
        //message.ccList = self.CCList TODO
        //message.expirationOffset = TODO
        //message.flags = self.Flags TODO
        message.isDetailDownloaded = self.isDetailsDownloaded ?? false
        message.messageID = self.ID
        //message.messageStatus =
        //message.messageType = self.`Type`
        //message.numAttachments = self.NumAttachments
        //message.passwordEncryptedBody
        //message.password
        //message.passwordHint
        //message.size = self.Size
        //message.spamScore = self.SpamScore ?? 0
        //message.title = self.tit
        //message.toList = self.ToList
        //message.unRead = self.Unread
        //message.userID = self.
        //message.isSending =
        message.conversationID = self.ConversationID
        //message.attachments =
        //message.labels = self.LabelIDs
        //message.order = self.Order

        // Optional fields
        // message.action
        // message.addressID
        // message.nextAddressID
        // message.cachedPassphraseRaw
        // message.cachedPrivateKeysRaw
        // message.cachedAuthCredentialRaw
        // message.cachedAddressRaw
        // message.expirationTime
        // message.header
        // message.lastModified
        // message.mimeType
        // message.originalMessageID
        // message.originalTime
        // message.replyTos
        // message.sender
        // message.time
        // message.unsubscribeMethods
        
        return message
    }
}

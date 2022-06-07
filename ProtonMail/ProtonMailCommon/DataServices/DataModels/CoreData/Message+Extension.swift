//
//  MessageExtension.swift
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
import CoreData
import Crypto
import ProtonCore_DataModel

extension Message {

    struct Attributes {
        static let entityName = "Message"
        static let isDetailDownloaded = "isDetailDownloaded"
        static let messageID = "messageID"
        static let toList = "toList"
        static let sender = "sender"
        static let time = "time"
        static let title = "title"
        static let labels = "labels"
        static let unread = "unread"

        static let messageType = "messageType"
        static let messageStatus = "messageStatus"

        static let expirationTime = "expirationTime"
        // 1.9.1
        static let unRead = "unRead"

        // 1.12.0
        static let userID = "userID"

        // 1.12.9
        static let isSending = "isSending"

        // 2.0.0
        static let conversationID = "conversationID"
        static let isSoftDeleted = "isSoftDeleted"
    }

    var recipients: [[String: Any]] {
        let to: [[String: Any]] = self.toList.parseJson() ?? []
        let cc: [[String: Any]] = self.ccList.parseJson() ?? []
        let bcc: [[String: Any]] = self.bccList.parseJson() ?? []
        return to + cc + bcc
    }

    // MARK: - variables
    var allEmails: [String] {
        var lists: [String] = []

        if !toList.isEmpty {
            let to = Message.contactsToAddressesArray(toList)
            if !to.isEmpty {
                lists.append(contentsOf: to)
            }
        }

        if !ccList.isEmpty {
            let cc = Message.contactsToAddressesArray(ccList)
            if !cc.isEmpty {
                lists.append(contentsOf: cc)
            }
        }

        if !bccList.isEmpty {
            let bcc = Message.contactsToAddressesArray(bccList)
            if !bcc.isEmpty {
                lists.append(contentsOf: bcc)
            }
        }

        return lists
    }

    func getScore() -> Message.SpamScore {
        if let e = Message.SpamScore(rawValue: self.spamScore.intValue) {
            return e
        }
        return .others
    }

    @discardableResult
    func add(labelID: String) -> String? {
        var outLabel: String?
        // 1, 2, labels can't be in inbox,
        var addLabelID = labelID
        if labelID == Location.inbox.rawValue && (self.contains(label: HiddenLocation.draft.rawValue) || self.contains(label: Location.draft.rawValue)) {
            // move message to 1 / 8
            addLabelID = Location.draft.rawValue // "8"
        }

        if labelID == Location.inbox.rawValue && (self.contains(label: HiddenLocation.sent.rawValue) || self.contains(label: Location.sent.rawValue)) {
            // move message to 2 / 7
            addLabelID = sentSelf ? Location.inbox.rawValue : Location.sent.rawValue // "7"
        }

        if let context = self.managedObjectContext {
            let labelObjs = self.mutableSetValue(forKey: Attributes.labels)
            if let toLabel = Label.labelForLabelID(addLabelID, inManagedObjectContext: context) {
                var exsited = false
                for l in labelObjs {
                    if let label = l as? Label {
                        if label == toLabel {
                            exsited = true
                            break
                        }
                    }
                }
                if !exsited {
                    outLabel = addLabelID
                    labelObjs.add(toLabel)
                }
            }
            self.setValue(labelObjs, forKey: Attributes.labels)

        }
        return outLabel
    }

    /// in rush , clean up later
    func setAsDraft() {
        if let context = self.managedObjectContext {
            let labelObjs = self.mutableSetValue(forKey: Attributes.labels)
            if let toLabel = Label.labelForLabelID(Location.draft.rawValue, inManagedObjectContext: context) {
                var exsited = false
                for l in labelObjs {
                    if let label = l as? Label {
                        if label == toLabel {
                            exsited = true
                            return
                        }
                    }
                }
                if !exsited {
                    labelObjs.add(toLabel)
                }
            }

            if let toLabel = Label.labelForLabelID("1", inManagedObjectContext: context) {
                var exsited = false
                for l in labelObjs {
                    if let label = l as? Label {
                        if label == toLabel {
                            exsited = true
                            return
                        }
                    }
                }
                if !exsited {
                    labelObjs.add(toLabel)
                }
            }
            self.setValue(labelObjs, forKey: "labels")
        }
    }

    func firstValidFolder() -> String? {
        let labelObjs = self.mutableSetValue(forKey: "labels")
        for l in labelObjs {
            if let label = l as? Label {
                if label.type == 3 {
                    return label.labelID
                }

                if !label.labelID.preg_match("(?!^\\d+$)^.+$") {
                    if label.labelID != "1", label.labelID != "2", label.labelID != "10", label.labelID != "5" {
                        return label.labelID
                    }
                }
            }
        }

        return nil
    }

    @discardableResult
    func remove(labelID: String) -> String? {
        if Location.allmail.rawValue == labelID {
            return Location.allmail.rawValue
        }
        var outLabel: String?
        if let _ = self.managedObjectContext {
            let labelObjs = self.mutableSetValue(forKey: Attributes.labels)
            for l in labelObjs {
                if let label = l as? Label {
                    // can't remove label 1, 2, 5
                    // case inbox   = "0"
                    // case draft   = "1"
                    // case sent    = "2"
                    // case starred = "10"
                    // case archive = "6"
                    // case spam    = "4"
                    // case trash   = "3"
                    // case allmail = "5"
                    if label.labelID == "1" || label.labelID == "2" || label.labelID == Location.allmail.rawValue {
                        continue
                    }
                    if label.labelID == labelID {
                        labelObjs.remove(label)
                        outLabel = labelID
                        break
                    }
                }
            }
            self.setValue(labelObjs, forKey: "labels")
        }
        return outLabel
    }

    func checkLabels() {
        guard let labels = self.labels.allObjects as? [Label] else {return}
        let labelIDs = labels.map {$0.labelID}
        guard labelIDs.contains(Message.Location.draft.rawValue) else {
            return
        }

        // This is the basic labes for draft
        let basic = [Message.Location.draft.rawValue,
                     Message.Location.allmail.rawValue,
                     Message.HiddenLocation.draft.rawValue]
        for label in labels {
            let id = label.labelID
            if basic.contains(id) {continue}

            if let _ = Int(id) {
                // default folder
                // The draft can't in the draft folder and another folder at the same time
                // the draft folder label should be removed
                self.remove(labelID: Message.Location.draft.rawValue)
                break
            }

            guard label.type == 3 else {continue}

            self.remove(labelID: Message.Location.draft.rawValue)
            break
        }
    }

    func selfSent(labelID: String) -> String? {
        if let _ = self.managedObjectContext {
            let labelObjs = self.mutableSetValue(forKey: Attributes.labels)
            for l in labelObjs {
                if let label = l as? Label {
                    if labelID == Location.inbox.rawValue {
                        if label.labelID == "2" || label.labelID == "7" {
                            return Location.sent.rawValue
                        }
                    }

                    if labelID == Location.sent.rawValue {
                        if label.labelID == Location.inbox.rawValue {
                            return Location.inbox.rawValue
                        }

                    }
                }
            }
        }
        return nil
    }

    var subject: String {
        return title
    }

    // MARK: - methods
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: NSEntityDescription.entity(forEntityName: Attributes.entityName, in: context)!, insertInto: context)
    }

    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }

    class func messageForMessageID(_ messageID: String, inManagedObjectContext context: NSManagedObjectContext) -> Message? {
        return context.managedObjectWithEntityName(Attributes.entityName, forKey: Attributes.messageID, matchingValue: messageID) as? Message
    }

    class func getIDsofSendingMessage(managedObjectContext: NSManagedObjectContext) -> [String]? {
        return (managedObjectContext.managedObjectsWithEntityName(Attributes.entityName, forKey: Attributes.isSending, matchingValue: NSNumber(value: true)) as? [Message])?.compactMap { $0.messageID }
    }

    class func messagesForConversationID(_ conversationID: String, inManagedObjectContext context: NSManagedObjectContext, shouldSort: Bool = false) -> [Message]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Attributes.conversationID, conversationID)
        if shouldSort {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Message.time), ascending: true), NSSortDescriptor(key: #keyPath(Message.order), ascending: true)]
        }

        do {
            let results = try context.fetch(fetchRequest)
            return results as? [Message]
        } catch {
        }
        return nil
    }

    override func awakeFromInsert() {
        super.awakeFromInsert()

        replaceNilAttributesWithEmptyString(option: [.string, .transformable])
    }

    // MARK: methods

    func decryptBody(keys: [Key], passphrase: String) throws -> String? {
        var firstError: Error?
        var errorMessages: [String] = []
        for key in keys {
            do {
                if let decryptedBody = try body.decryptMessageWithSinglKey(key.privateKey, passphrase: passphrase) {
                    return decryptedBody
                } else {
                    throw Crypto.CryptoError.unexpectedNil
                }
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
    }

    func decryptBody(keys: [Key], userKeys: [Data], passphrase: String) throws -> String? {
        var firstError: Error?
        var errorMessages: [String] = []
        for key in keys {
            do {
                let addressKeyPassphrase = try Crypto.getAddressKeyPassphrase(userKeys: userKeys,
                                                                              passphrase: passphrase,
                                                                              key: key)
                if let decryptedBody = try body.decryptMessageWithSinglKey(key.privateKey,
                                                                           passphrase: addressKeyPassphrase) {
                    return decryptedBody
                } else {
                    throw Crypto.CryptoError.unexpectedNil
                }
            } catch let error {
                if firstError == nil {
                    firstError = error
                    errorMessages.append(error.localizedDescription)
                }
            }
        }
        return nil
    }

    func split() throws -> SplitMessage? {
        return try body.split()
    }

    func getSessionKey(keys: [Data], passphrase: String) throws -> SymmetricKey? {
        return try split()?.keyPacket?.getSessionFromPubKeyPackage(passphrase, privKeys: keys)
    }

    func bodyToHtml() -> String {
        if isPlainText {
            return "<div>" + body.ln2br() + "</div>"
        } else {
            let body_without_ln = body.rmln()
            return "<div><pre>" + body_without_ln.lr2lrln() + "</pre></div>"
        }
    }

    var isPlainText: Bool {
        get {
            if let type = mimeType, type.lowercased() == MimeType.plainText {
                return true
            }
            return false
        }

    }

    var isMultipartMixed: Bool {
        get {
            if let type = mimeType, type.lowercased() == MimeType.mutipartMixed {
                return true
            }
            return false
        }
    }

    var senderContactVO: ContactVO! {
        var sender: Sender?
        if let senderRaw = self.sender?.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(Sender.self, from: senderRaw) {
            sender = decoded
        }

        return ContactVO(id: "",
                         name: sender?.name ?? "",
                         email: sender?.address ?? "")
    }

    var isHavingMoreThanOneContact: Bool {
        (toList.toContacts() + ccList.toContacts()).count > 1
    }

    var hasMetaData: Bool {
        messageStatus == 1
    }
}

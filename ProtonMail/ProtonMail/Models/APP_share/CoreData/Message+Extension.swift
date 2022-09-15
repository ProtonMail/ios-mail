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

import CoreData
import Crypto
import ProtonCore_Crypto
import ProtonCore_DataModel

extension Message {
    enum Attributes {
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

        // 2.0.0
        static let conversationID = "conversationID"
        static let isSoftDeleted = "isSoftDeleted"
    }

    // MARK: - variables

    var allEmails: [String] {
        var lists: [String] = []

        if !toList.isEmpty {
            let contactsInToList = Message.contactsToAddressesArray(toList)
            if !contactsInToList.isEmpty {
                lists.append(contentsOf: contactsInToList)
            }
        }

        if !ccList.isEmpty {
            let contactsInCCList = Message.contactsToAddressesArray(ccList)
            if !contactsInCCList.isEmpty {
                lists.append(contentsOf: contactsInCCList)
            }
        }

        if !bccList.isEmpty {
            let contactsInBCCList = Message.contactsToAddressesArray(bccList)
            if !contactsInBCCList.isEmpty {
                lists.append(contentsOf: contactsInBCCList)
            }
        }

        return lists
    }

    @discardableResult
    func add(labelID: String) -> String? {
        var outLabel: String?
        // 1, 2, labels can't be in inbox,
        var addLabelID = labelID
        if labelID == Location.inbox.rawValue,
           self.contains(label: HiddenLocation.draft.rawValue) ||
            self.contains(label: Location.draft.rawValue) {
            // move message to 1 / 8
            addLabelID = Location.draft.rawValue // "8"
        }

        if labelID == Location.inbox.rawValue,
           self.contains(label: HiddenLocation.sent.rawValue) ||
            self.contains(label: Location.sent.rawValue) {
            // move message to 2 / 7
            addLabelID = sentSelf ? Location.inbox.rawValue : Location.sent.rawValue // "7"
        }

        if let context = self.managedObjectContext {
            let labelObjects = self.mutableSetValue(forKey: Attributes.labels)
            if let toLabel = Label.labelForLabelID(addLabelID, inManagedObjectContext: context) {
                var existed = false
                for labelObject in labelObjects {
                    if let label = labelObject as? Label {
                        if label == toLabel {
                            existed = true
                            break
                        }
                    }
                }
                if !existed {
                    outLabel = addLabelID
                    labelObjects.add(toLabel)
                }
            }
            self.setValue(labelObjects, forKey: Attributes.labels)
        }
        return outLabel
    }

    // swiftlint:disable cyclomatic_complexity
    func setAsDraft() {
        if let context = self.managedObjectContext {
            let labelObjects = self.mutableSetValue(forKey: Attributes.labels)
            if let toLabel = Label.labelForLabelID(Location.draft.rawValue, inManagedObjectContext: context) {
                var existed = false
                for lableObject in labelObjects {
                    if let label = lableObject as? Label {
                        if label == toLabel {
                            existed = true
                            return
                        }
                    }
                }
                if !existed {
                    labelObjects.add(toLabel)
                }
            }

            if let toLabel = Label.labelForLabelID("1", inManagedObjectContext: context) {
                var existed = false
                for lableObject in labelObjects {
                    if let label = lableObject as? Label {
                        if label == toLabel {
                            existed = true
                            return
                        }
                    }
                }
                if !existed {
                    labelObjects.add(toLabel)
                }
            }
            self.setValue(labelObjects, forKey: "labels")
        }
    }

    func firstValidFolder() -> String? {
        let labelObjects = self.mutableSetValue(forKey: "labels")
        for label in labelObjects {
            if let label = label as? Label {
                if label.type == 3 {
                    return label.labelID
                }
                if !label.labelID.preg_match("(?!^\\d+$)^.+$"),
                   label.labelID != HiddenLocation.draft.rawValue,
                   label.labelID != HiddenLocation.sent.rawValue,
                   label.labelID != Location.starred.rawValue,
                   label.labelID != Location.allmail.rawValue,
                   label.labelID != HiddenLocation.outbox.rawValue {
                    return label.labelID
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
        if self.managedObjectContext != nil {
            let labelObjects = self.mutableSetValue(forKey: Attributes.labels)
            for lableObject in labelObjects {
                if let label = lableObject as? Label {
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
                        labelObjects.remove(label)
                        outLabel = labelID
                        break
                    }
                }
            }
            self.setValue(labelObjects, forKey: "labels")
        }
        return outLabel
    }

    func checkLabels() {
        guard let labels = self.labels.allObjects as? [Label] else { return }
        let labelIDs = labels.map { $0.labelID }
        guard labelIDs.contains(Message.Location.draft.rawValue) else {
            return
        }

        // This is the basic labels for draft
        let basic = [Message.Location.draft.rawValue,
                     Message.Location.allmail.rawValue,
                     Message.HiddenLocation.draft.rawValue]
        for label in labels {
            let id = label.labelID
            if basic.contains(id) { continue }

            if Int(id) != nil {
                // default folder
                // The draft can't in the draft folder and another folder at the same time
                // the draft folder label should be removed
                self.remove(labelID: Message.Location.draft.rawValue)
                break
            }

            guard label.type == 3 else { continue }

            self.remove(labelID: Message.Location.draft.rawValue)
            break
        }
    }

    func selfSent(labelID: String) -> String? {
        if self.managedObjectContext != nil {
            let labelObjects = self.mutableSetValue(forKey: Attributes.labels)
            for lableObject in labelObjects {
                if let label = lableObject as? Label {
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
        // swiftlint:disable force_unwrapping
        self.init(entity: NSEntityDescription.entity(forEntityName: Attributes.entityName, in: context)!,
                  insertInto: context)
    }

    /// Removes all messages from the store.
    class func deleteAll(inContext context: NSManagedObjectContext) {
        context.deleteAll(Attributes.entityName)
    }

    class func messageForMessageID(_ messageID: String,
                                   inManagedObjectContext context: NSManagedObjectContext) -> Message? {
        return context.managedObjectWithEntityName(Attributes.entityName,
                                                   forKey: Attributes.messageID,
                                                   matchingValue: messageID) as? Message
    }

    class func messagesForConversationID(_ conversationID: String,
                                         inManagedObjectContext context: NSManagedObjectContext,
                                         shouldSort: Bool = false) -> [Message]? {
        let fetchRequest = NSFetchRequest<Message>(entityName: Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K == %@", Attributes.conversationID, conversationID)
        if shouldSort {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Message.time), ascending: true),
                                            NSSortDescriptor(key: #keyPath(Message.order), ascending: true)]
        }

        do {
            let results = try context.fetch(fetchRequest)
            return results
        } catch {}
        return nil
    }

    // MARK: methods

    func decryptBody(keys: [Key], passphrase: Passphrase) throws -> String? {
        var firstError: Error?
        var errorMessages: [String] = []
        for key in keys {
            do {
                let decryptedBody = try body.decryptMessageWithSingleKeyNonOptional(
                    ArmoredKey(value: key.privateKey),
                    passphrase: passphrase
                )
                return decryptedBody
            } catch {
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

    func decryptBody(keys: [Key], userKeys: [Data], passphrase: Passphrase) throws -> String? {
        var firstError: Error?
        var errorMessages: [String] = []
        for key in keys {
            do {
                let addressKeyPassphrase = try MailCrypto.getAddressKeyPassphrase(userKeys: userKeys,
                                                                                  passphrase: passphrase,
                                                                                  key: key)
                let decryptedBody = try body.decryptMessageWithSingleKeyNonOptional(ArmoredKey(value: key.privateKey),
                                                                                    passphrase: addressKeyPassphrase)
                return decryptedBody
            } catch {
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

    func getSessionKey(keys: [Key], passphrase: Passphrase) throws -> SessionKey? {
        return try split()?.keyPacket?.getSessionFromPubKeyPackage(passphrase, privKeys: keys)
    }

    func bodyToHtml() -> String {
        if isPlainText {
            return "<div>" + body.ln2br() + "</div>"
        } else {
            let bodyWithoutNewlines = body.rmln()
            return "<div><pre>" + bodyWithoutNewlines.lr2lrln() + "</pre></div>"
        }
    }

    var isPlainText: Bool {
        mimeType?.lowercased() == MimeType.textPlain.rawValue
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

    var hasMetaData: Bool {
        messageStatus == 1
    }
}

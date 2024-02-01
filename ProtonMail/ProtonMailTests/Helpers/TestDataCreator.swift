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
import Groot
import ProtonCoreCrypto
@testable import ProtonMail

enum TestDataCreator {
    static func mockConversation(
        conversationID: ConversationID,
        in labelIDs: [LabelID],
        userID: UserID,
        isUnread: Bool = false,
        isSoftDeleted: Bool = false,
        context: NSManagedObjectContext
    ) -> Conversation? {
        let parsedObject = testConversationDetailData.parseObjectAny()!
        var conversation: [String: Any] = parsedObject["Conversation"] as! [String : Any]
        conversation["ID"] = conversationID.rawValue
        conversation["Order"] = Date().timeIntervalSinceReferenceDate
        let testConversation = try? GRTJSONSerialization
            .object(withEntityName: "Conversation",
                    fromJSONDictionary: conversation,
                    in: context) as? Conversation
        testConversation?.isSoftDeleted = isSoftDeleted
        testConversation?.mutableSetValue(forKeyPath: "labels").removeAllObjects()
        testConversation?.userID = userID.rawValue
        for id in labelIDs {
            testConversation?.applyLabelChanges(labelID: id.rawValue, apply: true)
        }
        testConversation?
            .mutableSetValue(forKey: "labels")
            .forEach({ ($0 as? ContextLabel)?.unreadCount = NSNumber(value: 1) })
        try? context.save()
        return testConversation
    }

    static func mockMessage(
        messageID: MessageID,
        conversationID: ConversationID?,
        in labelIDs: [LabelID],
        labelIDType: LabelEntity.LabelType,
        userID: UserID,
        isUnread: Bool = false,
        isSoftDeleted: Bool = false,
        context: NSManagedObjectContext
    ) -> Message? {
        var parsedObject = testMessageMetaData.parseObjectAny()!
        parsedObject["ID"] = messageID.rawValue
        let message = try? GRTJSONSerialization.object(
            withEntityName: Message.Attributes.entityName,
            fromJSONDictionary: parsedObject,
            in: context
        ) as? Message
        message?.userID = userID.rawValue
        message?.messageStatus = 1
        message?.unRead = isUnread
        message?.isSoftDeleted = isSoftDeleted
        message?.remove(labelID: "0")
        message?.remove(labelID: "10")
        message?.conversationID = conversationID?.rawValue ?? .empty
        for id in labelIDs {
            if Label.labelForLabelID(id.rawValue, inManagedObjectContext: context) == nil {
                Self.mockLabel(labelID: id, type: labelIDType.rawValue, context: context)
            }
            message?.add(labelID: id.rawValue)
        }
        try? context.save()
        return message
    }

    static func mockLabel(labelID: LabelID, type: Int, context: NSManagedObjectContext) {
        let label = Label(context: context)
        label.labelID = labelID.rawValue
        label.type = .init(value: type)
        try? context.save()
    }

    static func loadMessageLabelData(
        context: NSManagedObjectContext
    ) {
        let parsedLabel = testLabelsData.parseJson()!
        _ = try? GRTJSONSerialization.objects(
            withEntityName: Label.Attributes.entityName,
            fromJSONArray: parsedLabel,
            in: context
        )
        try? context.save()
    }

    static func loadDefaultConversationCountData(
        userID: UserID,
        context: NSManagedObjectContext
    ) {
        let defaultLabelID: Set<LabelID> = [
            Message.Location.inbox.labelID,
            Message.Location.spam.labelID,
            Message.Location.allmail.labelID,
            Message.Location.trash.labelID,
            Message.Location.archive.labelID,
            Message.Location.starred.labelID,
            Message.Location.sent.labelID,
            Message.Location.draft.labelID,
            Message.Location.almostAllMail.labelID,
            Message.Location.scheduled.labelID,
            Message.Location.blocked.labelID
        ]
        for labelID in defaultLabelID {
            let conversationCount = ConversationCount.newConversationCount(
                by: labelID.rawValue,
                userID: userID.rawValue,
                inManagedObjectContext: context
            )
            conversationCount.unread = 0
        }
        _ = context.saveUpstreamIfNeeded()
    }

    static func generateVCardTestData(
        vCardSignAndEncrypt: String,
        vCardSign: String,
        vCard: String,
        privateKey: ArmoredKey = ContactParserTestData.privateKey,
        passphrase: Passphrase = ContactParserTestData.passphrase
    ) throws -> String? {
        let key = privateKey
        let encrypted = try vCardSignAndEncrypt.encryptNonOptional(
            withPubKey: key.armoredPublicKey,
            privateKey: "",
            passphrase: ""
        )
        let signature = try Sign.signDetached(
            signingKey: .init(
                privateKey: key,
                passphrase: passphrase
            ),
            plainText: vCardSignAndEncrypt
        )
        let signedAndEncryptedJsonDict: [String: Any] = [
            "Type": CardDataType.SignAndEncrypt.rawValue,
            "Data": encrypted,
            "Signature": signature.value
        ]

        let signedOnlySignature = try Sign.signDetached(
            signingKey: .init(
                privateKey: key,
                passphrase: passphrase
            ),
            plainText: vCardSign
        )
        let signedJsonDict: [String: Any] = [
            "Type": CardDataType.SignedOnly.rawValue,
            "Data": vCardSign,
            "Signature": signedOnlySignature.value
        ]

        let jsonDict: [String: Any] = [
            "Type": CardDataType.PlainText.rawValue,
            "Data": vCard,
            "Signature": ""
        ]
        return [jsonDict, signedAndEncryptedJsonDict, signedJsonDict].toJSONString()
    }

    static func generateContactGroupTestData(
        userID: UserID,
        context: NSManagedObjectContext
    ) -> Label {
        let label = Label(context: context)
        label.userID = userID.rawValue
        label.name = String.randomString(20)
        label.labelID = String.randomString(20)
        label.color = "#007DC3"
        label.isSoftDeleted = false
        label.type = 2
        label.sticky = 0
        let email = Email(context: context)
        let labelsOfEmail = email.mutableSetValue(forKey: "labels")
        labelsOfEmail.add(label)
        email.userID = userID.rawValue
        email.email = "\(String.randomString(20))@pm.me"
        return label
    }
}

extension Array where Element == [String: Any] {
    func toJSONString(
        options: JSONSerialization.WritingOptions = .prettyPrinted
    ) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: self, options: options),
           let result = String(data: data, encoding: String.Encoding.utf8) {
            return result
        }
        return "[]"
    }
}

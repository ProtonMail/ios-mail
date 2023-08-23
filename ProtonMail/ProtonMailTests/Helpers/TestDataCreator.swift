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

@testable import ProtonMail
import CoreData
import Groot

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
                Self.mockLabel(labelID: id, context: context)
            }
            message?.add(labelID: id.rawValue)
        }
        try? context.save()
        return message
    }

    static func mockLabel(labelID: LabelID, context: NSManagedObjectContext) {
        let label = Label(context: context)
        label.labelID = labelID.rawValue
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
}

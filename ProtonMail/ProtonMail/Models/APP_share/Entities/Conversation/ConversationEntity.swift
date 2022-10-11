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

struct ConversationEntity: Equatable, Hashable {
    let objectID: ObjectID
    let conversationID: ConversationID
    let expirationTime: Date?
    let attachmentCount: Int
    let messageCount: Int
    let order: Int
    let senders: String
    let recipients: String
    let size: Int?
    let subject: String
    let userID: UserID
    let contextLabelRelations: [ContextLabelEntity]

    /// Local use flag to mark this conversation is deleted
    /// (usually caused by empty trash/ spam action)
    let isSoftDeleted: Bool

    init(_ conversation: Conversation) {
        self.objectID = ObjectID(rawValue: conversation.objectID)
        self.conversationID = ConversationID(conversation.conversationID)
        self.expirationTime = conversation.expirationTime
        self.attachmentCount = conversation.numAttachments.intValue
        self.messageCount = conversation.numMessages.intValue
        self.order = conversation.order.intValue
        self.senders = conversation.senders
        self.recipients = conversation.recipients
        self.size = conversation.size?.intValue
        self.subject = conversation.subject
        self.userID = UserID(conversation.userID)

        self.contextLabelRelations = ContextLabelEntity.convert(from: conversation)

        self.isSoftDeleted = conversation.isSoftDeleted
    }
}

extension ConversationEntity {
    var starred: Bool {
        return contains(of: .starred)
    }
}

extension ConversationEntity {
    func contains(of labelID: LabelID) -> Bool {
        return contextLabelRelations
            .contains(where: { $0.labelID == labelID })
    }

    func contains(of location: Message.Location) -> Bool {
        return contains(of: location.labelID)
    }

    func isUnread(labelID: LabelID) -> Bool {
        return getNumUnread(labelID: labelID) != 0
    }

    func getNumUnread(labelID: LabelID) -> Int {
        guard let matchedLabel = contextLabelRelations
                .first(where: { $0.labelID == labelID }) else {
            return 0
        }
        return matchedLabel.unreadCount
    }

    func getLabelIDs() -> [LabelID] {
        return contextLabelRelations.map(\.labelID)
    }

    func getTime(labelID: LabelID) -> Date? {
        guard let matchedLabel = contextLabelRelations
                .first(where: { $0.labelID == labelID }) else {
            return nil
        }
        return matchedLabel.time
    }

    func getFirstValidFolder() -> LabelID? {
        let foldersToFilter = [
            Message.HiddenLocation.sent.rawValue,
            Message.HiddenLocation.draft.rawValue,
            Message.Location.starred.rawValue,
            Message.Location.allmail.rawValue
        ]
        return getLabelIDs().first { labelID in
            labelID.rawValue.preg_match("(?!^\\d+$)^.+$") == false && !foldersToFilter.contains(labelID.rawValue)
        }
    }

    func getNumMessages(labelID: LabelID) -> Int {
        guard let matchedLabel = contextLabelRelations
                .first(where: { $0.labelID == labelID }) else {
            return 0
        }
        return matchedLabel.messageCount
    }
}

// MARK: - Senders
extension ConversationEntity {
    func getSenders() -> [ContactPickerModelProtocol] {
        ContactPickerModelHelper.contacts(from: self.senders)
    }

    /// This method will return a string that contains the name of all senders with ',' between them.
    /// e.g Georage, Paul, Ringo
    /// - Returns: String of all name of the senders.
    func getJoinedSendersName(_ replacingEmails: [String: EmailEntity]) -> String {
        let lists: [String] = self.getSenders().compactMap { contact in
            if let displayEmail = contact.displayEmail,
               let name = replacingEmails[displayEmail]?.name,
               !name.isEmpty {
                return name
            } else if !(contact.displayName?.isEmpty ?? true) {
                return contact.displayName
            } else {
                return contact.displayEmail
            }
        }
        return lists.asCommaSeparatedList(trailingSpace: true)
    }

    func initial(_ replacingEmails:[String: EmailEntity]) -> String {
        guard let senderName = getSendersName(replacingEmails).first else {
            return "?"
        }
        return senderName.initials()
    }

    func getSendersName(_ replacingEmails: [String: EmailEntity]) -> [String] {
        return self.getSenders().compactMap { contact in
            if let displayEmail = contact.displayEmail,
               let name = replacingEmails[displayEmail]?.name,
               !name.isEmpty {
                return name
            } else if !(contact.displayName?.isEmpty ?? true) {
                return contact.displayName
            } else {
                return contact.displayEmail
            }
        }
    }
}

extension ConversationEntity {
    #if !APP_EXTENSION
    // swiftlint:disable function_body_length
    func getFolderIcons(customFolderLabels: [LabelEntity]) -> [ImageAsset.Image] {
        let labelIds = getLabelIDs()
        let standardFolders: [LabelID] = [
            Message.Location.inbox,
            Message.Location.trash,
            Message.Location.spam,
            Message.Location.archive,
            Message.Location.sent,
            Message.Location.draft
        ].map({ $0.labelID })

        // Display order: Inbox, Custom, Drafts, Sent, Archive, Spam, Trash
        let standardFolderWithOrder: [Message.Location: Int] = [
            .inbox: 0,
            .draft: 2,
            .sent: 3,
            .archive: 4,
            .spam: 5,
            .trash: 6
        ]

        let customLabelIdsMap = customFolderLabels.reduce([:]) { result, label -> [LabelID: LabelEntity] in
            var newValue = result
            newValue[label.labelID] = label
            return newValue
        }

        var addedDict: [ImageAsset.Image: Bool] = [:]
        let filteredLabelIds = labelIds.filter { labelId in
            return (customLabelIdsMap[labelId] != nil) || standardFolders.contains(labelId)
        }

        let sortedLabelIds = filteredLabelIds.sorted { labelId1, labelId2 in
            var orderOfLabelId1 = Int.max
            if let location = Message.Location(labelId1) {
                orderOfLabelId1 = standardFolderWithOrder[location] ?? Int.max
            } else {
                orderOfLabelId1 = 1
            }

            var orderOfLabelId2 = Int.max
            if let location = Message.Location(labelId2) {
                orderOfLabelId2 = standardFolderWithOrder[location] ?? Int.max
            } else {
                orderOfLabelId2 = 1
            }

            return orderOfLabelId1 < orderOfLabelId2
        }

        var isCustomFolderIconAdded = false
        return Array(sortedLabelIds.compactMap { lableId in
            var icon: ImageAsset.Image?
            if standardFolders.contains(lableId) {
                if let location = Message.Location(lableId) {
                    icon = location.originImage()
                }
            } else if !isCustomFolderIconAdded {
                isCustomFolderIconAdded = true
                icon = Asset.mailCustomFolder.image
            }
            if let iconToAdd = icon,
               addedDict.updateValue(true, forKey: iconToAdd) == nil { // filter duplicated icon
                return iconToAdd
            } else {
                return nil
            }
        }.prefix(3))
    }
    #endif
}

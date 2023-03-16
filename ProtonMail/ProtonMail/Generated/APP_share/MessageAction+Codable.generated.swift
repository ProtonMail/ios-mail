// Generated using Sourcery 1.9.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

extension MessageAction: Codable {
    enum CodingKeys: CodingKey {
        case saveDraft
        case uploadAtt
        case uploadPubkey
        case deleteAtt
        case updateAttKeyPacket
        case read
        case unread
        case delete
        case send
        case emptyTrash
        case emptySpam
        case empty
        case label
        case unlabel
        case folder
        case updateLabel
        case createLabel
        case deleteLabel
        case signout
        case signin
        case fetchMessageDetail
        case updateContact
        case deleteContact
        case addContact
        case addContactGroup
        case updateContactGroup
        case deleteContactGroup
        case notificationAction
    }

    var rawValue: String {
        switch self {
        case .saveDraft:
            return "saveDraft"
        case .uploadAtt:
            return "uploadAtt"
        case .uploadPubkey:
            return "uploadPubkey"
        case .deleteAtt:
            return "deleteAtt"
        case .updateAttKeyPacket:
            return "updateAttKeyPacket"
        case .read:
            return "read"
        case .unread:
            return "unread"
        case .delete:
            return "delete"
        case .send:
            return "send"
        case .emptyTrash:
            return "emptyTrash"
        case .emptySpam:
            return "emptySpam"
        case .empty:
            return "empty"
        case .label:
            return "label"
        case .unlabel:
            return "unlabel"
        case .folder:
            return "folder"
        case .updateLabel:
            return "updateLabel"
        case .createLabel:
            return "createLabel"
        case .deleteLabel:
            return "deleteLabel"
        case .signout:
            return "signout"
        case .signin:
            return "signin"
        case .fetchMessageDetail:
            return "fetchMessageDetail"
        case .updateContact:
            return "updateContact"
        case .deleteContact:
            return "deleteContact"
        case .addContact:
            return "addContact"
        case .addContactGroup:
            return "addContactGroup"
        case .updateContactGroup:
            return "updateContactGroup"
        case .deleteContactGroup:
            return "deleteContactGroup"
        case .notificationAction:
            return "notificationAction"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard container.allKeys.count == 1 else {
            let context = DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Invalid number of keys found, expected one."
            )

            throw DecodingError.typeMismatch(Self.self, context)
        }

        switch container.allKeys.first.unsafelyUnwrapped {
        case .saveDraft:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .saveDraft)
            self = .saveDraft(
                messageObjectID: try nestedContainer.decode(String.self, forKey: .messageObjectID)
            )
        case .uploadAtt:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uploadAtt)
            self = .uploadAtt(
                attachmentObjectID: try nestedContainer.decode(String.self, forKey: .attachmentObjectID)
            )
        case .uploadPubkey:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uploadPubkey)
            self = .uploadPubkey(
                attachmentObjectID: try nestedContainer.decode(String.self, forKey: .attachmentObjectID)
            )
        case .deleteAtt:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteAtt)
            self = .deleteAtt(
                attachmentObjectID: try nestedContainer.decode(String.self, forKey: .attachmentObjectID),
                attachmentID: try nestedContainer.decodeIfPresent(String.self, forKey: .attachmentID)
            )
        case .updateAttKeyPacket:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateAttKeyPacket)
            self = .updateAttKeyPacket(
                messageObjectID: try nestedContainer.decode(String.self, forKey: .messageObjectID),
                addressID: try nestedContainer.decode(String.self, forKey: .addressID)
            )
        case .read:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .read)
            self = .read(
                itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs),
                objectIDs: try nestedContainer.decode([String].self, forKey: .objectIDs)
            )
        case .unread:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .unread)
            self = .unread(
                currentLabelID: try nestedContainer.decode(String.self, forKey: .currentLabelID),
                itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs),
                objectIDs: try nestedContainer.decode([String].self, forKey: .objectIDs)
            )
        case .delete:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .delete)
            self = .delete(
                currentLabelID: try nestedContainer.decodeIfPresent(String.self, forKey: .currentLabelID),
                itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs)
            )
        case .send:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .send)
            self = .send(
                messageObjectID: try nestedContainer.decode(String.self, forKey: .messageObjectID),
                deliveryTime: try nestedContainer.decodeIfPresent(Date.self, forKey: .deliveryTime)
            )
        case .emptyTrash:
            self = .emptyTrash
        case .emptySpam:
            self = .emptySpam
        case .empty:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .empty)
            self = .empty(
                currentLabelID: try nestedContainer.decode(String.self, forKey: .currentLabelID)
            )
        case .label:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .label)
            self = .label(
                currentLabelID: try nestedContainer.decode(String.self, forKey: .currentLabelID),
                shouldFetch: try nestedContainer.decodeIfPresent(Bool.self, forKey: .shouldFetch),
                isSwipeAction: try nestedContainer.decode(Bool.self, forKey: .isSwipeAction),
                itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs),
                objectIDs: try nestedContainer.decode([String].self, forKey: .objectIDs)
            )
        case .unlabel:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .unlabel)
            self = .unlabel(
                currentLabelID: try nestedContainer.decode(String.self, forKey: .currentLabelID),
                shouldFetch: try nestedContainer.decodeIfPresent(Bool.self, forKey: .shouldFetch),
                isSwipeAction: try nestedContainer.decode(Bool.self, forKey: .isSwipeAction),
                itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs),
                objectIDs: try nestedContainer.decode([String].self, forKey: .objectIDs)
            )
        case .folder:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .folder)
            self = .folder(
                nextLabelID: try nestedContainer.decode(String.self, forKey: .nextLabelID),
                shouldFetch: try nestedContainer.decodeIfPresent(Bool.self, forKey: .shouldFetch),
                isSwipeAction: try nestedContainer.decode(Bool.self, forKey: .isSwipeAction),
                itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs),
                objectIDs: try nestedContainer.decode([String].self, forKey: .objectIDs)
            )
        case .updateLabel:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateLabel)
            self = .updateLabel(
                labelID: try nestedContainer.decode(String.self, forKey: .labelID),
                name: try nestedContainer.decode(String.self, forKey: .name),
                color: try nestedContainer.decode(String.self, forKey: .color)
            )
        case .createLabel:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .createLabel)
            self = .createLabel(
                name: try nestedContainer.decode(String.self, forKey: .name),
                color: try nestedContainer.decode(String.self, forKey: .color),
                isFolder: try nestedContainer.decode(Bool.self, forKey: .isFolder)
            )
        case .deleteLabel:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteLabel)
            self = .deleteLabel(
                labelID: try nestedContainer.decode(String.self, forKey: .labelID)
            )
        case .signout:
            self = .signout
        case .signin:
            self = .signin
        case .fetchMessageDetail:
            self = .fetchMessageDetail
        case .updateContact:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateContact)
            self = .updateContact(
                objectID: try nestedContainer.decode(String.self, forKey: .objectID),
                cardDatas: try nestedContainer.decode([CardData].self, forKey: .cardDatas)
            )
        case .deleteContact:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteContact)
            self = .deleteContact(
                objectID: try nestedContainer.decode(String.self, forKey: .objectID)
            )
        case .addContact:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .addContact)
            self = .addContact(
                objectID: try nestedContainer.decode(String.self, forKey: .objectID),
                cardDatas: try nestedContainer.decode([CardData].self, forKey: .cardDatas),
                importFromDevice: try nestedContainer.decode(Bool.self, forKey: .importFromDevice)
            )
        case .addContactGroup:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .addContactGroup)
            self = .addContactGroup(
                objectID: try nestedContainer.decode(String.self, forKey: .objectID),
                name: try nestedContainer.decode(String.self, forKey: .name),
                color: try nestedContainer.decode(String.self, forKey: .color),
                emailIDs: try nestedContainer.decode([String].self, forKey: .emailIDs)
            )
        case .updateContactGroup:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateContactGroup)
            self = .updateContactGroup(
                objectID: try nestedContainer.decode(String.self, forKey: .objectID),
                name: try nestedContainer.decode(String.self, forKey: .name),
                color: try nestedContainer.decode(String.self, forKey: .color),
                addedEmailIDs: try nestedContainer.decode([String].self, forKey: .addedEmailIDs),
                removedEmailIDs: try nestedContainer.decode([String].self, forKey: .removedEmailIDs)
            )
        case .deleteContactGroup:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteContactGroup)
            self = .deleteContactGroup(
                objectID: try nestedContainer.decode(String.self, forKey: .objectID)
            )
        case .notificationAction:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .notificationAction)
            self = .notificationAction(
                messageID: try nestedContainer.decode(String.self, forKey: .messageID),
                action: try nestedContainer.decode(PushNotificationAction.self, forKey: .action)
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .saveDraft(messageObjectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .saveDraft)
            try nestedContainer.encode(messageObjectID, forKey: .messageObjectID)
        case let .uploadAtt(attachmentObjectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uploadAtt)
            try nestedContainer.encode(attachmentObjectID, forKey: .attachmentObjectID)
        case let .uploadPubkey(attachmentObjectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uploadPubkey)
            try nestedContainer.encode(attachmentObjectID, forKey: .attachmentObjectID)
        case let .deleteAtt(attachmentObjectID, attachmentID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteAtt)
            try nestedContainer.encode(attachmentObjectID, forKey: .attachmentObjectID)
            try nestedContainer.encode(attachmentID, forKey: .attachmentID)
        case let .updateAttKeyPacket(messageObjectID, addressID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateAttKeyPacket)
            try nestedContainer.encode(messageObjectID, forKey: .messageObjectID)
            try nestedContainer.encode(addressID, forKey: .addressID)
        case let .read(itemIDs, objectIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .read)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
            try nestedContainer.encode(objectIDs, forKey: .objectIDs)
        case let .unread(currentLabelID, itemIDs, objectIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .unread)
            try nestedContainer.encode(currentLabelID, forKey: .currentLabelID)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
            try nestedContainer.encode(objectIDs, forKey: .objectIDs)
        case let .delete(currentLabelID, itemIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .delete)
            try nestedContainer.encode(currentLabelID, forKey: .currentLabelID)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
        case let .send(messageObjectID, deliveryTime):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .send)
            try nestedContainer.encode(messageObjectID, forKey: .messageObjectID)
            try nestedContainer.encode(deliveryTime, forKey: .deliveryTime)
        case .emptyTrash:
            try container.encode(rawValue, forKey: .emptyTrash)
        case .emptySpam:
            try container.encode(rawValue, forKey: .emptySpam)
        case let .empty(currentLabelID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .empty)
            try nestedContainer.encode(currentLabelID, forKey: .currentLabelID)
        case let .label(currentLabelID, shouldFetch, isSwipeAction, itemIDs, objectIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .label)
            try nestedContainer.encode(currentLabelID, forKey: .currentLabelID)
            try nestedContainer.encode(shouldFetch, forKey: .shouldFetch)
            try nestedContainer.encode(isSwipeAction, forKey: .isSwipeAction)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
            try nestedContainer.encode(objectIDs, forKey: .objectIDs)
        case let .unlabel(currentLabelID, shouldFetch, isSwipeAction, itemIDs, objectIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .unlabel)
            try nestedContainer.encode(currentLabelID, forKey: .currentLabelID)
            try nestedContainer.encode(shouldFetch, forKey: .shouldFetch)
            try nestedContainer.encode(isSwipeAction, forKey: .isSwipeAction)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
            try nestedContainer.encode(objectIDs, forKey: .objectIDs)
        case let .folder(nextLabelID, shouldFetch, isSwipeAction, itemIDs, objectIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .folder)
            try nestedContainer.encode(nextLabelID, forKey: .nextLabelID)
            try nestedContainer.encode(shouldFetch, forKey: .shouldFetch)
            try nestedContainer.encode(isSwipeAction, forKey: .isSwipeAction)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
            try nestedContainer.encode(objectIDs, forKey: .objectIDs)
        case let .updateLabel(labelID, name, color):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateLabel)
            try nestedContainer.encode(labelID, forKey: .labelID)
            try nestedContainer.encode(name, forKey: .name)
            try nestedContainer.encode(color, forKey: .color)
        case let .createLabel(name, color, isFolder):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .createLabel)
            try nestedContainer.encode(name, forKey: .name)
            try nestedContainer.encode(color, forKey: .color)
            try nestedContainer.encode(isFolder, forKey: .isFolder)
        case let .deleteLabel(labelID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteLabel)
            try nestedContainer.encode(labelID, forKey: .labelID)
        case .signout:
            try container.encode(rawValue, forKey: .signout)
        case .signin:
            try container.encode(rawValue, forKey: .signin)
        case .fetchMessageDetail:
            try container.encode(rawValue, forKey: .fetchMessageDetail)
        case let .updateContact(objectID, cardDatas):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateContact)
            try nestedContainer.encode(objectID, forKey: .objectID)
            try nestedContainer.encode(cardDatas, forKey: .cardDatas)
        case let .deleteContact(objectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteContact)
            try nestedContainer.encode(objectID, forKey: .objectID)
        case let .addContact(objectID, cardDatas, importFromDevice):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .addContact)
            try nestedContainer.encode(objectID, forKey: .objectID)
            try nestedContainer.encode(cardDatas, forKey: .cardDatas)
            try nestedContainer.encode(importFromDevice, forKey: .importFromDevice)
        case let .addContactGroup(objectID, name, color, emailIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .addContactGroup)
            try nestedContainer.encode(objectID, forKey: .objectID)
            try nestedContainer.encode(name, forKey: .name)
            try nestedContainer.encode(color, forKey: .color)
            try nestedContainer.encode(emailIDs, forKey: .emailIDs)
        case let .updateContactGroup(objectID, name, color, addedEmailIDs, removedEmailIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateContactGroup)
            try nestedContainer.encode(objectID, forKey: .objectID)
            try nestedContainer.encode(name, forKey: .name)
            try nestedContainer.encode(color, forKey: .color)
            try nestedContainer.encode(addedEmailIDs, forKey: .addedEmailIDs)
            try nestedContainer.encode(removedEmailIDs, forKey: .removedEmailIDs)
        case let .deleteContactGroup(objectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteContactGroup)
            try nestedContainer.encode(objectID, forKey: .objectID)
        case let .notificationAction(messageID, action):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .notificationAction)
            try nestedContainer.encode(messageID, forKey: .messageID)
            try nestedContainer.encode(action, forKey: .action)
        }
    }
}


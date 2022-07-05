//
//  MessageAction.swift
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

enum MessageAction: Equatable {
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
    }

    enum NestedCodingKeys: CodingKey {
        case messageObjectID
        case attachmentObjectID
        case objectIDs
        case objectID
        case currentLabelID
        case itemIDs
        case shouldFetch
        case nextLabelID
        case labelID
        case name
        case color
        case isFolder
        case addressID
        case contactID
        case cardDatas
        case emailIDs
        case removedEmailIDs
        case isSwipeAction
        case importFromDevice
    }

    // Draft
    case saveDraft(messageObjectID: String)

    // Attachment
    case uploadAtt(attachmentObjectID: String)
    case uploadPubkey(attachmentObjectID: String)
    case deleteAtt(attachmentObjectID: String)
    case updateAttKeyPacket(messageObjectID: String, addressID: String)

    // Read/unread
    case read(itemIDs: [String], objectIDs: [String])
    case unread(currentLabelID: String, itemIDs: [String], objectIDs: [String])

    // Move mailbox
    case delete(currentLabelID: String?, itemIDs: [String])

    // Send
    case send(messageObjectID: String)

    // Empty
    case emptyTrash
    case emptySpam
    case empty(currentLabelID: String)

    case label(currentLabelID: String,
               shouldFetch: Bool?,
               isSwipeAction: Bool,
               itemIDs: [String],
               objectIDs: [String])
    case unlabel(currentLabelID: String,
                 shouldFetch: Bool?,
                 isSwipeAction: Bool,
                 itemIDs: [String],
                 objectIDs: [String])
    case folder(nextLabelID: String,
                shouldFetch: Bool?,
                isSwipeAction: Bool,
                itemIDs: [String],
                objectIDs: [String])

    case updateLabel(labelID: String, name: String, color: String)
    case createLabel(name: String, color: String, isFolder: Bool)
    case deleteLabel(labelID: String)
    case signout
    case signin
    case fetchMessageDetail

    // Contact
    case updateContact(objectID: String, cardDatas: [CardData])
    case deleteContact(objectID: String)
    case addContact(objectID: String, cardDatas: [CardData], importFromDevice: Bool)
    case addContactGroup(objectID: String, name: String, color: String, emailIDs: [String])
    case updateContactGroup(objectID: String, name: String, color: String, addedEmailList: [String], removedEmailList: [String])
    case deleteContactGroup(objectID: String)

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
            return "applyLabel"
        case .unlabel:
            return "unapplyLabel"
        case .folder:
            return "moveToFolder"
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
        }
    }
}

extension MessageAction: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.allKeys.count != 1 {
            let context = DecodingError.Context(codingPath: container.codingPath,
                                                debugDescription: "Invalid number of keys found, expected one.")
            throw DecodingError.typeMismatch(Self.self, context)
        }

        switch container.allKeys.first.unsafelyUnwrapped {
        case .saveDraft:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .saveDraft)
            self = .saveDraft(messageObjectID: try nestedContainer.decode(String.self, forKey: .messageObjectID))
        case .uploadAtt:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uploadAtt)
            self = .uploadAtt(attachmentObjectID: try nestedContainer.decode(String.self, forKey: .attachmentObjectID))
        case .uploadPubkey:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uploadPubkey)
            self = .uploadPubkey(attachmentObjectID: try nestedContainer.decode(String.self, forKey: .attachmentObjectID))
        case .deleteAtt:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteAtt)
            self = .deleteAtt(attachmentObjectID: try nestedContainer.decode(String.self, forKey: .attachmentObjectID))
        case .updateAttKeyPacket:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateAttKeyPacket)
            self = .updateAttKeyPacket(messageObjectID: try nestedContainer.decode(String.self, forKey: .messageObjectID), addressID: try nestedContainer.decode(String.self, forKey: .addressID))
        case .read:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .read)
            self = .read(itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs), objectIDs: try nestedContainer.decode([String].self, forKey: .objectIDs))
        case .unread:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .unread)
            self = .unread(currentLabelID: try nestedContainer.decode(String.self, forKey: .currentLabelID), itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs), objectIDs: try nestedContainer.decode([String].self, forKey: .objectIDs))
        case .delete:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .delete)
            self = .delete(currentLabelID: try nestedContainer.decode(String?.self, forKey: .currentLabelID), itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs))
        case .send:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .send)
            self = .send(messageObjectID: try nestedContainer.decode(String.self, forKey: .messageObjectID))
        case .emptyTrash:
            self = .emptyTrash
        case .emptySpam:
            self = .emptySpam
        case .empty:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .empty)
            self = .empty(currentLabelID: try nestedContainer.decode(String.self, forKey: .currentLabelID))
        case .label:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .label)
            self = .label(currentLabelID: try nestedContainer.decode(String.self, forKey: .currentLabelID),
                          shouldFetch: try nestedContainer.decode(Bool?.self, forKey: .shouldFetch),
                          isSwipeAction: try nestedContainer.decode(Bool.self, forKey: .isSwipeAction),
                          itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs),
                          objectIDs: try nestedContainer.decode([String].self, forKey: .objectIDs))
        case .unlabel:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .unlabel)
            self = .unlabel(currentLabelID: try nestedContainer.decode(String.self, forKey: .currentLabelID),
                            shouldFetch: try nestedContainer.decode(Bool?.self, forKey: .shouldFetch),
                            isSwipeAction: try nestedContainer.decode(Bool.self, forKey: .isSwipeAction),
                            itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs),
                            objectIDs: try nestedContainer.decode([String].self, forKey: .objectIDs))
        case .folder:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .folder)
            self = .folder(nextLabelID: try nestedContainer.decode(String.self, forKey: .nextLabelID),
                           shouldFetch: try nestedContainer.decode(Bool?.self, forKey: .shouldFetch),
                           isSwipeAction: try nestedContainer.decode(Bool.self, forKey: .isSwipeAction),
                           itemIDs: try nestedContainer.decode([String].self, forKey: .itemIDs),
                           objectIDs: try nestedContainer.decode([String].self, forKey: .objectIDs))
        case .updateLabel:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateLabel)
            self = .updateLabel(labelID: try nestedContainer.decode(String.self, forKey: .labelID), name: try nestedContainer.decode(String.self, forKey: .name), color: try nestedContainer.decode(String.self, forKey: .color))
        case .createLabel:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .createLabel)
            self = .createLabel(name: try nestedContainer.decode(String.self, forKey: .name), color: try nestedContainer.decode(String.self, forKey: .color), isFolder: try nestedContainer.decode(Bool.self, forKey: .isFolder))
        case .deleteLabel:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteLabel)
            self = .deleteLabel(labelID: try nestedContainer.decode(String.self, forKey: .labelID))
        case .signout:
            self = .signout
        case .signin:
            self = .signin
        case .fetchMessageDetail:
            self = .fetchMessageDetail
        case .updateContact:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateContact)
            self = .updateContact(objectID: try nestedContainer.decode(String.self, forKey: .objectID),
                                  cardDatas: try nestedContainer.decode([CardData].self, forKey: .cardDatas))
        case .deleteContact:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteContact)
            self = .deleteContact(objectID: try nestedContainer.decode(String.self, forKey: .objectID))
        case .addContact:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .addContact)
            self = .addContact(objectID: try nestedContainer.decode(String.self,
                                                                     forKey: .objectID),
                               cardDatas: try nestedContainer.decode([CardData].self,
                                                                     forKey: .cardDatas),
                               importFromDevice: try nestedContainer.decode(Bool.self,
                                                                            forKey: .importFromDevice))
        case .addContactGroup:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .addContactGroup)
            let objectID = try nestedContainer.decode(String.self, forKey: .objectID)
            let name = try nestedContainer.decode(String.self, forKey: .name)
            let color = try nestedContainer.decode(String.self, forKey: .color)
            let emailIDs = try nestedContainer.decode([String].self, forKey: .emailIDs)
            self = .addContactGroup(objectID: objectID, name: name, color: color, emailIDs: emailIDs)
        case .updateContactGroup:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateContactGroup)
            let objectID = try nestedContainer.decode(String.self, forKey: .objectID)
            let name = try nestedContainer.decode(String.self, forKey: .name)
            let color = try nestedContainer.decode(String.self, forKey: .color)
            let added = try nestedContainer.decode([String].self, forKey: .emailIDs)
            let removed = try nestedContainer.decode([String].self, forKey: .removedEmailIDs)
            self = .updateContactGroup(objectID: objectID, name: name, color: color, addedEmailList: added, removedEmailList: removed)
        case .deleteContactGroup:
            let nestedContainer = try container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteContactGroup)
            self = .deleteContactGroup(objectID: try nestedContainer.decode(String.self, forKey: .objectID))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .saveDraft(messageObjectID: let messageObjectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .saveDraft)
            try nestedContainer.encode(messageObjectID, forKey: .messageObjectID)
        case .uploadAtt(attachmentObjectID: let attachmentObjectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uploadAtt)
            try nestedContainer.encode(attachmentObjectID, forKey: .attachmentObjectID)
        case .uploadPubkey(attachmentObjectID: let attachmentObjectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .uploadPubkey)
            try nestedContainer.encode(attachmentObjectID, forKey: .attachmentObjectID)
        case .deleteAtt(attachmentObjectID: let attachmentObjectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteAtt)
            try nestedContainer.encode(attachmentObjectID, forKey: .attachmentObjectID)
        case .updateAttKeyPacket(messageObjectID: let messageObjectID, addressID: let addressID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateAttKeyPacket)
            try nestedContainer.encode(messageObjectID, forKey: .messageObjectID)
            try nestedContainer.encode(addressID, forKey: .addressID)
        case .read(itemIDs: let itemIDs, objectIDs: let objectIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .read)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
            try nestedContainer.encode(objectIDs, forKey: .objectIDs)
        case .unread(currentLabelID: let currentLabelID, itemIDs: let itemIDs, objectIDs: let objectIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .unread)
            try nestedContainer.encode(currentLabelID, forKey: .currentLabelID)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
            try nestedContainer.encode(objectIDs, forKey: .objectIDs)
        case .delete(currentLabelID: let currentLabelID, itemIDs: let itemIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .delete)
            try nestedContainer.encode(currentLabelID, forKey: .currentLabelID)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
        case .send(messageObjectID: let messageObjectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .send)
            try nestedContainer.encode(messageObjectID, forKey: .messageObjectID)
        case .emptyTrash:
            try container.encode(rawValue, forKey: .emptyTrash)
        case .emptySpam:
            try container.encode(rawValue, forKey: .emptySpam)
        case .empty(currentLabelID: let currentLabelID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .empty)
            try nestedContainer.encode(currentLabelID, forKey: .currentLabelID)
        case .label(currentLabelID: let currentLabelID, shouldFetch: let shouldFetch, isSwipeAction: let isSwipeAction, itemIDs: let itemIDs, objectIDs: let objectIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .label)
            try nestedContainer.encode(currentLabelID, forKey: .currentLabelID)
            try nestedContainer.encode(shouldFetch, forKey: .shouldFetch)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
            try nestedContainer.encode(objectIDs, forKey: .objectIDs)
            try nestedContainer.encode(isSwipeAction, forKey: .isSwipeAction)
        case .unlabel(currentLabelID: let currentLabelID,
                      shouldFetch: let shouldFetch,
                      isSwipeAction: let isSwipeAction,
                      itemIDs: let itemIDs,
                      objectIDs: let objectIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .unlabel)
            try nestedContainer.encode(currentLabelID, forKey: .currentLabelID)
            try nestedContainer.encode(shouldFetch, forKey: .shouldFetch)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
            try nestedContainer.encode(objectIDs, forKey: .objectIDs)
            try nestedContainer.encode(isSwipeAction, forKey: .isSwipeAction)
        case .folder(nextLabelID: let nextLabelID,
                     shouldFetch: let shouldFetch,
                     isSwipeAction: let isSwipeAction,
                     itemIDs: let itemIDs,
                     objectIDs: let objectIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .folder)
            try nestedContainer.encode(shouldFetch, forKey: .shouldFetch)
            try nestedContainer.encode(nextLabelID, forKey: .nextLabelID)
            try nestedContainer.encode(itemIDs, forKey: .itemIDs)
            try nestedContainer.encode(objectIDs, forKey: .objectIDs)
            try nestedContainer.encode(isSwipeAction, forKey: .isSwipeAction)
        case .updateLabel(labelID: let labelID, name: let name, color: let color):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateLabel)
            try nestedContainer.encode(labelID, forKey: .labelID)
            try nestedContainer.encode(name, forKey: .name)
            try nestedContainer.encode(color, forKey: .color)
        case .createLabel(name: let name, color: let color, isFolder: let isFolder):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .createLabel)
            try nestedContainer.encode(name, forKey: .name)
            try nestedContainer.encode(color, forKey: .color)
            try nestedContainer.encode(isFolder, forKey: .isFolder)
        case .deleteLabel(labelID: let labelID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteLabel)
            try nestedContainer.encode(labelID, forKey: .labelID)
        case .signout:
            try container.encode(rawValue, forKey: .signout)
        case .signin:
            try container.encode(rawValue, forKey: .signin)
        case .fetchMessageDetail:
            try container.encode(rawValue, forKey: .fetchMessageDetail)
        case .updateContact(objectID: let objectID, cardDatas: let cardDatas):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateContact)
            try nestedContainer.encode(objectID, forKey: .objectID)
            try nestedContainer.encode(cardDatas, forKey: .cardDatas)
        case .deleteContact(objectID: let objectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteContact)
            try nestedContainer.encode(objectID, forKey: .objectID)
        case .addContact(objectID: let objectID, cardDatas: let cardDatas, importFromDevice: let importFromDevice):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .addContact)
            try nestedContainer.encode(objectID, forKey: .objectID)
            try nestedContainer.encode(cardDatas, forKey: .cardDatas)
            try nestedContainer.encode(importFromDevice, forKey: .importFromDevice)
        case .addContactGroup(objectID: let objectID, name: let name, color: let color, emailIDs: let emailIDs):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .addContactGroup)
            try nestedContainer.encode(objectID, forKey: .objectID)
            try nestedContainer.encode(name, forKey: .name)
            try nestedContainer.encode(color, forKey: .color)
            try nestedContainer.encode(emailIDs, forKey: .emailIDs)
        case .updateContactGroup(let objectID, let name, let color, let addedEmailList, let removedEmailList):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .updateContactGroup)
            try nestedContainer.encode(objectID, forKey: .objectID)
            try nestedContainer.encode(name, forKey: .name)
            try nestedContainer.encode(color, forKey: .color)
            try nestedContainer.encode(addedEmailList, forKey: .emailIDs)
            try nestedContainer.encode(removedEmailList, forKey: .removedEmailIDs)
        case .deleteContactGroup(let objectID):
            var nestedContainer = container.nestedContainer(keyedBy: NestedCodingKeys.self, forKey: .deleteContactGroup)
            try nestedContainer.encode(objectID, forKey: .objectID)
        }
    }
}

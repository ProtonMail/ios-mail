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
import ProtonCoreDataModel

// sourcery: mock
protocol CopyMessageUseCase {
    typealias CopyOutput = (Message, [MimeAttachment]?)

    func execute(parameters: CopyMessage.Parameters) throws -> CopyOutput
}

class CopyMessage: CopyMessageUseCase {
    let dependencies: Dependencies
    private(set) weak var userDataSource: UserDataSource?

    init(dependencies: Dependencies, userDataSource: UserDataSource) {
        self.dependencies = dependencies
        self.userDataSource = userDataSource
    }

    func execute(parameters: Parameters) throws -> CopyOutput {
        try dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            guard let originalMessage = Message.messageForMessageID(parameters.messageID.rawValue, in: context) else {
                throw CopyMessageError.messageNotFoundForGivenMessageID
            }

            return try self.copy(
                message: originalMessage,
                copyAttachments: parameters.copyAttachments,
                context: context
            )
        }
    }

    private func copy(
        message: Message,
        copyAttachments: Bool,
        context: NSManagedObjectContext
    ) throws -> CopyOutput {
        let newMessage = duplicate(message, context: context)

        if let conversation = Conversation.conversationForConversationID(
            message.conversationID,
            inManagedObjectContext: context
        ) {
            let newCount = conversation.numMessages.intValue + 1
            conversation.numMessages = NSNumber(value: newCount)
        }

        let decryptionOutput = try? dependencies.messageDecrypter.decrypt(messageObject: newMessage)
        let mimeAttachments = decryptionOutput?.attachments ?? []
        // When we reply a message that can not be decrypted, we should use the raw body as the body of the new draft.
        let decryptedBody = decryptionOutput?.body ?? newMessage.body

        try copy(attachments: message.attachments,
                 to: newMessage,
                 copyAttachment: copyAttachments,
                 decryptedBody: decryptedBody,
                 context: context)

        if let error = context.saveUpstreamIfNeeded() {
            throw error
        }

        return (newMessage, mimeAttachments)
    }

    func getFirstAddressKey(for addressID: String?) -> Key? {
        guard let addressID = addressID,
              let userInfo = self.userDataSource?.userInfo,
              let keys = userInfo.getAllAddressKey(address_id: addressID) else {
            return nil
        }
        return keys.first
    }

    private func updateKeyPacketIfNeeded(attachment: Attachment, addressID: String?) {
        guard let key = self.getFirstAddressKey(for: addressID),
              let userData = self.userDataSource else {
            return
        }

        do {
            let symmetricKey = try attachment.getSession(
                userKeys: userData.userInfo.userPrivateKeys,
                keys: userData.userInfo.addressKeys,
                mailboxPassword: userData.mailboxPassword
            )

            guard let sessionPack = symmetricKey,
                  let newkp = try sessionPack.sessionKey
                .getKeyPackage(publicKey: key.publicKey,
                               algo: sessionPack.algo.value) else {
                return
            }
            let encodedkp = newkp.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            attachment.keyPacket = encodedkp
            attachment.keyChanged = true
        } catch {
            return
        }
    }

    func duplicate(_ message: Message, context: NSManagedObjectContext) -> Message {
        let newMessage = Message(context: context)
        newMessage.toList = message.toList
        newMessage.bccList = message.bccList
        newMessage.ccList = message.ccList
        newMessage.title = message.title
        newMessage.time = Date()
        newMessage.body = message.body

        // newMessage.flag = message.flag
        newMessage.sender = message.sender
        newMessage.replyTos = message.replyTos

        newMessage.orginalTime = message.time
        newMessage.orginalMessageID = message.messageID
        newMessage.expirationOffset = 0

        newMessage.addressID = message.addressID
        newMessage.messageStatus = message.messageStatus
        newMessage.mimeType = message.mimeType
        newMessage.conversationID = message.conversationID
        newMessage.setAsDraft()

        newMessage.userID = self.userDataSource?.userID.rawValue ?? ""
        return newMessage
    }

    // TODO: this method should also accept MIME attachments
    private func copy(
        attachments: NSSet,
        to newMessage: Message,
        copyAttachment: Bool,
        decryptedBody: String,
        context: NSManagedObjectContext
    ) throws {
        var newAttachmentCount: Int = 0
        let oldAttachments = attachments
            .allObjects
            .compactMap({ $0 as? Attachment })
        for attachment in oldAttachments {
            guard attachment.inline() || copyAttachment else {
                continue
            }

            if !copyAttachment {
                if attachment.inline() == false {
                    // Normal attachment & shouldn't copy attachment
                    continue
                }
                // Inline attachment but the body doesn't contain the contentID
                if let contentID = attachment.contentID(), !decryptedBody.contains(check: contentID) {
                    continue
                }
            }

            duplicate(oldAttachment: attachment, newMessage: newMessage, context: context)

            newAttachmentCount += 1
        }

        newMessage.numAttachments = NSNumber(value: newAttachmentCount)

        if let error = context.saveUpstreamIfNeeded() {
            throw error
        }
    }

    private func duplicate(
        oldAttachment: Attachment,
        newMessage: Message,
        context: NSManagedObjectContext
    ) {
        let attachment = Attachment(context: context)
        attachment.attachmentID = oldAttachment.attachmentID
        attachment.message = newMessage
        attachment.fileName = oldAttachment.fileName
        attachment.mimeType = oldAttachment.mimeType
        attachment.fileData = oldAttachment.fileData
        attachment.fileSize = oldAttachment.fileSize
        attachment.headerInfo = oldAttachment.headerInfo
        attachment.localURL = oldAttachment.localURL
        attachment.keyPacket = oldAttachment.keyPacket
        attachment.isTemp = true
        attachment.order = oldAttachment.order
        attachment.userID = self.userDataSource?.userID.rawValue ?? ""

        self.updateKeyPacketIfNeeded(attachment: attachment,
                                     addressID: newMessage.addressID)
    }
}

extension CopyMessage {
    struct Dependencies {
        let contextProvider: CoreDataContextProviderProtocol
        let messageDecrypter: MessageDecrypter
    }

    struct Parameters {
        let copyAttachments: Bool
        let messageID: MessageID
    }
}

enum CopyMessageError: Swift.Error {
    case messageNotFoundForGivenMessageID
}

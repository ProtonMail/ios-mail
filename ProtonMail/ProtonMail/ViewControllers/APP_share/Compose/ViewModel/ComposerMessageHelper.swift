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

import AwaitKit
import CoreData
import Foundation
import ProtonCore_Crypto
import ProtonCore_DataModel

final class ComposerMessageHelper {
    private(set) var draft: Draft?
    private var rawMessage: Message?

    private let mailboxPassword: Passphrase
    private let dependencies: Dependencies

    var attachments: [AttachmentEntity] {
        return draft?.attachments ?? []
    }

    var attachmentSize: Int {
        return attachments.reduce(into: 0) {
            $0 += $1.fileSize.intValue
        }
    }

    var updateAttachmentView: (() -> Void)?

    init(
        dependencies: Dependencies,
        user: UserManager
    ) {
        self.mailboxPassword = user.mailboxPassword
        self.dependencies = dependencies
    }

    func collectDraft(
        recipientList: String,
        bccList: String,
        ccList: String,
        sendAddress: Address,
        title: String,
        body: String,
        expiration: TimeInterval,
        password: String,
        passwordHint: String
    ) {
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            if self.draft == nil {
                self.rawMessage = self.dependencies.messageDataService.messageWithLocation(
                    recipientList: recipientList,
                    bccList: bccList,
                    ccList: ccList,
                    title: title,
                    encryptionPassword: "",
                    passwordHint: "",
                    expirationTimeInterval: expiration,
                    body: body,
                    attachments: nil,
                    mailbox_pwd: self.mailboxPassword,
                    sendAddress: sendAddress,
                    inManagedObjectContext: context
                )
                self.rawMessage?.password = password
                self.rawMessage?.passwordHint = passwordHint
                self.rawMessage?.unRead = false
                self.rawMessage?.expirationOffset = Int32(expiration)
            } else {
                self.rawMessage?.toList = recipientList
                self.rawMessage?.ccList = ccList
                self.rawMessage?.bccList = bccList
                self.rawMessage?.title = title
                self.rawMessage?.time = Date()
                self.rawMessage?.password = password
                self.rawMessage?.unRead = false
                self.rawMessage?.passwordHint = passwordHint
                self.rawMessage?.expirationOffset = Int32(expiration)
                if let msg = self.rawMessage {
                    self.dependencies.messageDataService
                        .updateMessage(msg,
                                       expirationTimeInterval: expiration,
                                       body: body,
                                       mailbox_pwd: self.mailboxPassword)
                }
            }
            _ = context.saveUpstreamIfNeeded()
        }
        updateDraft()
    }

    func setNewMessage(objectID: NSManagedObjectID) {
        var message: Message?
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            message = try? context.existingObject(with: objectID) as? Message
            message?.password = .empty
        }
        self.rawMessage = message
        updateDraft()
    }

    func uploadDraft() {
        dependencies.messageDataService.saveDraft(self.rawMessage)
    }

    func markAsRead() {
        if let draft = draft, draft.unRead, let rawMsg = rawMessage {
            _ = dependencies.messageDataService.mark(
                messageObjectIDs: [rawMsg.objectID],
                labelID: Message.Location.draft.labelID,
                unRead: false
            )
            updateDraft()
        }
    }

    func copyAndCreateDraft(from message: Message, shouldCopyAttachment: Bool) {
        var messageToAssign: Message?
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            messageToAssign = self.dependencies.messageDataService
                .messageDecrypter.copy(
                    message: message,
                    copyAttachments: shouldCopyAttachment,
                    context: context
                )
        }
        self.rawMessage = messageToAssign
        updateDraft()
    }

    func updateAddressID(addressID: String, completion: @escaping () -> Void) {
        dependencies.contextProvider.performOnRootSavingContext { context in
            defer {
                self.updateDraft()
                self.uploadDraft()
                completion()
            }
            guard let msg = self.rawMessage else { return }
            msg.nextAddressID = addressID
            _ = context.saveUpstreamIfNeeded()
            self.dependencies.messageDataService.updateAttKeyPacket(message: MessageEntity(msg), addressID: addressID)
        }
    }

    func updateExpirationOffset(
        expirationTime: TimeInterval,
        password: String,
        passwordHint: String,
        completion: @escaping () -> Void
    ) {
        guard let msg = self.rawMessage else {
            completion()
            return
        }
        dependencies.cacheService.updateExpirationOffset(
            of: msg.objectID,
            expirationTime: expirationTime,
            pwd: password,
            pwdHint: passwordHint,
            completion: {
                self.updateDraft()
                completion()
            }
        )
    }

    func updateMessageByMessageAction(_ action: ComposeMessageAction) {
        dependencies.contextProvider.performAndWaitOnRootSavingContext { _ in
            defer {
                self.updateDraft()
            }
            switch action {
            case .reply, .replyAll:
                self.rawMessage?.action = action.rawValue as NSNumber?
                if let title = self.draft?.title {
                    if !title.hasRe() {
                        let re = LocalString._composer_short_reply
                        self.rawMessage?.title = "\(re) \(title)"
                    }
                }
            case .forward:
                self.rawMessage?.action = action.rawValue as NSNumber?
                if let title = self.draft?.title {
                    if !(title.hasFwd() || title.hasFw()) {
                        let fwd = LocalString._composer_short_forward_shorter
                        self.rawMessage?.title = "\(fwd) \(title)"
                    }
                }
            default:
                break
            }
        }
    }

    func decryptBody() -> String {
        guard let msg = rawMessage else {
            fatalError("Message should never be nil")
        }
        var result = ""
        dependencies.contextProvider.performAndWaitOnRootSavingContext { _ in
            do {
                result = try self.dependencies.messageDataService.messageDecrypter.decrypt(message: msg)
            } catch {
                result = msg.bodyToHtml()
            }
        }
        return result
    }

    func getRawMessageObject() -> Message? {
        return rawMessage
    }

    func getMessageEntity() -> MessageEntity? {
        guard let rawMessage = self.rawMessage else {
            return nil
        }
        var message: MessageEntity?
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            message = MessageEntity(rawMessage)
        }
        return message
    }
}

// MARK: - Attachment related methods

extension ComposerMessageHelper {
    func addPublicKeyIfNeeded(email: String,
                              fingerprint: String,
                              data: Data,
                              shouldStripMetaDate: Bool,
                              completion: @escaping (AttachmentEntity?) -> Void) {
        let fileName = "publicKey - \(email) - \(fingerprint).asc"
        var attached = false
        // check if key already attached
        let attachments = attachments.filter { !$0.isSoftDeleted }
        for attachment in attachments {
            if attachment.name == fileName {
                attached = true
                break
            }
        }

        if !attached {
            self.addAttachment(data: data,
                               fileName: fileName,
                               shouldStripMetaData: shouldStripMetaDate,
                               type: "application/pgp-keys",
                               isInline: false) { attachmentToAdd in
                completion(attachmentToAdd)
            }
        } else {
            completion(nil)
        }
    }

    func addAttachment(data: Data,
                       fileName: String,
                       shouldStripMetaData: Bool,
                       type: String,
                       isInline: Bool,
                       completion: @escaping (AttachmentEntity?) -> Void) {
        dependencies.contextProvider.performOnRootSavingContext { context in
            data.toAttachment(context,
                              fileName: fileName,
                              type: type,
                              stripMetadata: shouldStripMetaData,
                              isInline: isInline).done { attachment in
                if let attachment = attachment {
                    self.addAttachment(attachment.objectID)
                }
                self.updateDraft()
                completion(attachment)
            }.cauterize()
        }
    }

    func addAttachment(_ attachmentObjectID: ObjectID) {
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            if let attachmentObject = context.object(with: attachmentObjectID.rawValue) as? Attachment {
                self.addAttachmentObject(attachmentObject, context: context)
                self.uploadAttachment(attachment: attachmentObject)
            }
        }
    }

    func deleteAttachment(
        _ attachment: AttachmentEntity,
        completion: @escaping () -> Void
    ) {
        guard let msgID = draft?.messageID else { return }
        dependencies.messageDataService.delete(
            att: attachment,
            messageID: msgID
        ).done { _ in
            self.updateDraft()
            completion()
        }.cauterize()
    }

    func removeAttachment(fileName: String,
                          isRealAttachment: Bool,
                          completion: (() -> Void)?) {
        // find attachment to remove
        guard let attachment = self.attachments.first(where: { $0.name.hasPrefix(fileName)
        }) else { return }

        // decrement number of attachments in message manually
        let number = self.attachments.filter { attach in
            if attach.isSoftDeleted {
                return false
            } else if isRealAttachment {
                return !attach.isInline
            }
            return true
        }.count

        let newNum = number > 0 ? number - 1 : 0
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            self.rawMessage?.numAttachments = NSNumber(value: newNum)
            _ = context.saveUpstreamIfNeeded()
        }

        deleteAttachment(attachment) {
            self.updateDraft()
            completion?()
        }
    }

    func addAttachment(
        _ file: FileData,
        shouldStripMetaData: Bool,
        completion: ((AttachmentEntity?) -> Void)?
    ) {
        dependencies.contextProvider.performOnRootSavingContext { context in
            file.contents.toAttachment(context,
                                       fileName: file.name,
                                       type: file.ext,
                                       stripMetadata: shouldStripMetaData,
                                       isInline: false).done { attachment in
                defer {
                    self.updateDraft()
                    completion?(attachment)
                }
                guard let att = attachment else { return }
                self.addAttachment(att.objectID)
            }.cauterize()
        }
    }

    func addMimeAttachments(attachment: MimeAttachment, shouldStripMetaData: Bool, completion: @escaping (AttachmentEntity?) -> Void) {
        dependencies.contextProvider.performOnRootSavingContext { context in
            attachment.toAttachment(context: context, stripMetadata: shouldStripMetaData).done { attachment in
                if let attachment = attachment {
                    self.addAttachment(attachment.objectID)
                }
                self.updateDraft()
                completion(attachment)
            }.cauterize()
        }
    }

    func updateAttachmentCount(isRealAttachment: Bool) {
        // decrement number of attachments in message manually
        let number = self.attachments.filter { attach in
            if attach.isSoftDeleted {
                return false
            } else if isRealAttachment {
                return !attach.isInline
            }
            return true
        }.count

        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            self.rawMessage?.numAttachments = NSNumber(value: number)
            _ = context.saveUpstreamIfNeeded()
        }
        updateDraft()
    }

    func updateAttachmentOrders(completion: @escaping ([AttachmentEntity]) -> Void) {
        guard let msg = rawMessage else {
            completion([])
            return
        }
        dependencies.contextProvider.performOnRootSavingContext { context in
            let attachments = msg.attachments.allObjects.compactMap { $0 as? Attachment }
            // Make the newly added attachment to the bottom of the attachment list.
            attachments.forEach {
                if $0.order == -1 {
                    let numberOfOrderedAttachments = attachments.filter { $0.order != -1 }.count
                    $0.order = Int32(numberOfOrderedAttachments)
                }
                $0.message = msg
            }
            _ = context.saveUpstreamIfNeeded()
            let sortedAttachments = attachments
                .sorted(by: { $0.order < $1.order })
                .map(AttachmentEntity.init)
            completion(sortedAttachments)
        }
    }
}

extension ComposerMessageHelper {
    private func updateDraft() {
        guard let msg = rawMessage else {
            return
        }
        var newDraft: Draft?
        msg.managedObjectContext?.performAndWait {
            newDraft = .init(rawMessage: msg)
        }
        self.draft = newDraft
    }

    private func uploadAttachment(attachment: Attachment) {
        dependencies.messageDataService.upload(att: attachment)
    }

    private func addAttachmentObject(
        _ attachment: Attachment,
        context: NSManagedObjectContext
    ) {
        guard let msg = self.rawMessage else { return }
        attachment.message = msg
        if attachment.headerInfo == nil {
            attachment.setupHeaderInfo(isInline: false, contentID: nil)
        }

        let attachments = msg.attachments
            .compactMap { $0 as? Attachment }
            .filter { !$0.inline() }
        msg.numAttachments = NSNumber(value: attachments.count)

        attachment.order = msg.numAttachments.int32Value
        _ = context.saveUpstreamIfNeeded()
        updateDraft()
    }
}

extension ComposerMessageHelper {
    struct Dependencies {
        let messageDataService: MessageDataServiceProtocol
        let cacheService: CacheServiceProtocol
        let contextProvider: CoreDataContextProviderProtocol
    }
}

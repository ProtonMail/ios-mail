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

import CoreData
import Foundation
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreKeymaker

final class ComposerMessageHelper {
    private(set) var draft: Draft?
    private var rawMessage: Message?

    private let mailboxPassword: Passphrase
    private let dependencies: Dependencies

    var attachments: [AttachmentEntity] {
        return getMessageEntity()?.attachments ?? []
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
        guard let message = getMessageEntity() else {
            return
        }

        do {
            try dependencies.messageDataService.saveDraft(message)
        } catch {
            SystemLogger.log(error: error, category: .draft)
        }
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

    func copyAndCreateDraft(from messageID: MessageID, action: ComposeMessageAction) throws -> [MimeAttachment]? {
        let (messageToAssign, mimeAttachments) = try dependencies.copyMessage.execute(
            parameters: .init(copyAttachments: action == .forward, messageID: messageID)
        )

        rawMessage = messageToAssign
        updateDraft()
        updateMessageByMessageAction(action)

        // TODO: MIME attachments should also be handled by CopyMessageUseCase instead of here
        if action == ComposeMessageAction.forward {
            return mimeAttachments
        }
        return nil
    }

    func updateAddress(to address: Address, uploadDraft: Bool = true, completion: @escaping () -> Void) {
        dependencies.contextProvider.performOnRootSavingContext { context in
            defer {
                self.updateDraft()
                if uploadDraft {
                    self.uploadDraft()
                }
                completion()
            }
            guard let msg = self.rawMessage else { return }
            msg.nextAddressID = address.addressID
            var sender: [String: Any] = msg.sender?.parseJSON() ?? [:]
            sender["Address"] = address.email
            sender["Name"] = address.displayName
            msg.sender = sender.toString()
            _ = context.saveUpstreamIfNeeded()
            self.dependencies.messageDataService.updateAttKeyPacket(
                message: MessageEntity(msg),
                addressID: address.addressID
            )
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
                result = try self.dependencies.messageDataService.messageDecrypter.decrypt(messageObject: msg).body
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
        guard let rawMessage else {
            SystemLogger.log(message: "Raw message not yet loaded", category: .draft)
            return nil
        }

        guard let context = rawMessage.managedObjectContext else {
            SystemLogger.log(message: "Database context not yet loaded", category: .draft)
            return nil
        }

        return context.performAndWait {
            MessageEntity(rawMessage)
        }
    }

    func originalTo() -> String? {
        var originalTo: String?
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            guard let rawMessage = self.rawMessage,
                  let originalID = rawMessage.orginalMessageID else {
                return
            }
            let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == %@", Message.Attributes.messageID, originalID)
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: Message.Attributes.time, ascending: false),
                NSSortDescriptor(key: #keyPath(Message.order), ascending: false)
            ]
            guard
                let originalMessage = try? fetchRequest.execute().first,
                let parsedHeader = originalMessage.parsedHeaders,
                let dict: [String: Any] = parsedHeader.parseJSON()
            else { return }
            originalTo = dict[MessageHeaderKey.originalTo] as? String
        }
        return originalTo
    }

    func originalFrom() -> String? {
        var originalFrom: String?
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            guard let parsedHeader = self.rawMessage?.parsedHeaders,
                  let headerDict: [String: Any] = parsedHeader.parseJSON(),
                  let from = headerDict[MessageHeaderKey.from] as? String,
                  let regex = try? NSRegularExpression(pattern: ".*<(.*)>"),
                  let match = regex.firstMatch(in: from, range: NSRange(from.startIndex..<from.endIndex, in:from)),
                  match.numberOfRanges == 2
            else { return }
            // from = "name <address>"
            let range = match.range(at: 1)
            originalFrom = (from as NSString).substring(with: range)
        }
        return originalFrom
    }
}

// MARK: - Attachment related methods

extension ComposerMessageHelper {
    func addPublicKeyIfNeeded(email: String,
                              fingerprint: String,
                              data: Data,
                              shouldStripMetaDate: Bool) throws -> AttachmentEntity? {
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
            return try addAttachment(data: data,
                               fileName: fileName,
                               shouldStripMetaData: shouldStripMetaDate,
                               type: "application/pgp-keys",
                               isInline: false)
        } else {
            return nil
        }
    }

    func addAttachment(data: Data,
                       fileName: String,
                       shouldStripMetaData: Bool,
                       type: String,
                       isInline: Bool,
                       cid: String? = nil
    ) throws -> AttachmentEntity {
        let attachment: AttachmentEntity = try dependencies.contextProvider.write { context in
            return data.toAttachment(
                context,
                fileName: fileName,
                type: type,
                stripMetadata: shouldStripMetaData,
                cid: cid,
                isInline: isInline
            )
        }

        addAttachment(attachment.objectID)
        updateDraft()

        return attachment
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
        caller: StaticString = #function,
        completion: @escaping () -> Void
    ) {
        SystemLogger.log(message: "CMH deleteAttachment called by \(caller)", category: .draft)
        guard let msgID = draft?.messageID else { return }
        dependencies.messageDataService.delete(
            att: attachment,
            messageID: msgID
        ).done { _ in
            self.updateDraft()
            completion()
        }.cauterize()
    }

    func removeAttachment(
        attachment: AttachmentEntity,
        isRealAttachment: Bool,
        completion: (() -> Void)?
    ) {
        // find attachment to remove
        guard let attachment = attachments.first(where: { $0.id == attachment.id }) else {
            completion?()
            return
        }
        removeAttachmentAndAttachmentCount(attachment, isRealAttachment: isRealAttachment, completion: completion)
    }

    func removeAttachment(
        cid: String,
        isRealAttachment: Bool,
        completion: (() -> Void)?
    ) {
        // find attachment to remove
        guard let attachment = attachments.first(where: { $0.getContentID() == cid }) else {
            completion?()
            return
        }

        removeAttachmentAndAttachmentCount(attachment, isRealAttachment: isRealAttachment, completion: completion)
    }

    private func removeAttachmentAndAttachmentCount(
        _ attachment: AttachmentEntity,
        isRealAttachment: Bool,
        completion: (() -> Void)?
    ) {
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
        isInline: Bool,
        completion: ((AttachmentEntity?) -> Void)?
    ) {
        let attachment: AttachmentEntity? = try? dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            file.contents.toAttachment(
                context,
                fileName: file.name,
                type: file.mimeType,
                stripMetadata: shouldStripMetaData,
                cid: nil,
                isInline: isInline
            )
        }
        if let attachment = attachment {
            addAttachment(attachment.objectID)
            updateDraft()
        }
        completion?(attachment)
    }

    func addMimeAttachments(attachment: MimeAttachment, shouldStripMetaData: Bool, completion: @escaping (AttachmentEntity?) -> Void) {
        let attachment: AttachmentEntity? = try? dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            return attachment.toAttachment(context: context, stripMetadata: shouldStripMetaData)
        }
        if let attachment = attachment {
            addAttachment(attachment.objectID)
            updateAttachmentView?()
            updateDraft()
        }
        completion(attachment)
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
        msg.updateAttachmentMetaDatas()

        attachment.order = msg.numAttachments.int32Value
        attachment.userID = msg.userID
        _ = context.saveUpstreamIfNeeded()
        updateDraft()
    }
}

extension ComposerMessageHelper {
    struct Dependencies {
        let messageDataService: MessageDataServiceProtocol
        let cacheService: CacheServiceProtocol
        let contextProvider: CoreDataContextProviderProtocol
        let copyMessage: CopyMessageUseCase
    }
}

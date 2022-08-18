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
import ProtonCore_DataModel

final class ComposerMessageHelper: NSObject {
    init(
        msgDataService: MessageDataService,
        contextProvider: CoreDataContextProviderProtocol,
        user: UserManager,
        cacheService: CacheService
    ) {
        self.messageDataService = msgDataService
        self.mailboxPassword = user.mailboxPassword
        self.cacheService = cacheService
        context = contextProvider.makeComposerMainContext()
    }

    @objc dynamic private(set) var message: Message?
    let context: NSManagedObjectContext
    let messageDataService: MessageDataService
    let mailboxPassword: String
    let cacheService: CacheService

    var messageID: MessageID? {
        if let msg = self.message {
            return MessageID(msg.messageID)
        } else {
            return nil
        }
    }

    var attachments: [Attachment] {
        return (self.message?.attachments.allObjects as? [Attachment]) ?? []
    }

    var attachmentSize: Int {
        return attachments.reduce(into: 0) {
            $0 += $1.fileSize.intValue
        }
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
        context.performAndWait {
            if message == nil {
                self.message = messageDataService.messageWithLocation(
                    recipientList: recipientList,
                    bccList: bccList,
                    ccList: ccList,
                    title: title,
                    encryptionPassword: "",
                    passwordHint: "",
                    expirationTimeInterval: expiration,
                    body: body,
                    attachments: nil,
                    mailbox_pwd: mailboxPassword,
                    sendAddress: sendAddress,
                    inManagedObjectContext: context)
                self.message?.password = password
                self.message?.passwordHint = passwordHint
                self.message?.unRead = false
                self.message?.expirationOffset = Int32(expiration)
            } else {
                self.message?.toList = recipientList
                self.message?.ccList = ccList
                self.message?.bccList = bccList
                self.message?.title = title
                self.message?.time = Date()
                self.message?.password = password
                self.message?.unRead = false
                self.message?.passwordHint = passwordHint
                self.message?.expirationOffset = Int32(expiration)
                if let msg = self.message {
                    messageDataService
                        .updateMessage(msg,
                                       expirationTimeInterval: expiration,
                                       body: body,
                                       mailbox_pwd: mailboxPassword)
                }
            }
            _ = context.saveUpstreamIfNeeded()

            if let msg = self.message, msg.objectID.isTemporaryID {
                try? context.obtainPermanentIDs(for: [msg])
            }
        }
    }

    func setNewMessage(_ message: Message) {
        self.message = message
        // Cleanup password when user opens the draft
        self.message?.password = .empty
    }

    func updateDraft() {
        messageDataService.saveDraft(self.message)
    }

    func markAsRead() {
        if let msg = message, msg.unRead {
            messageDataService.mark(messages: [MessageEntity(msg)], labelID: Message.Location.draft.labelID, unRead: false)
        }
    }

    func copyAndCreateDraft(from message: Message, shouldCopyAttachment: Bool) {
        self.message = messageDataService.messageDecrypter.copy(message: message, copyAttachments: shouldCopyAttachment, context: context)
    }

    func updateAddressID(addressID: String, completion: @escaping () -> Void) {
        context.perform {
            defer {
                completion()
            }
            guard let msg = self.message else { return }
            msg.nextAddressID = addressID
            _ = self.context.saveUpstreamIfNeeded()
            self.messageDataService.updateAttKeyPacket(message: MessageEntity(msg), addressID: addressID)
        }
    }

    func addPublicKeyIfNeeded(email: String,
                              fingerprint: String,
                              data: Data,
                              shouldStripMetaDate: Bool,
                              completion: @escaping (Attachment?) -> Void) {
        guard let msg = self.message else {
            completion(nil)
            return
        }

        let filename = "publicKey - " + email + " - " + fingerprint + ".asc"
        var attached: Bool = false
        // check if key already attahced
        let atts = attachments.filter({ !$0.isSoftDeleted })
        for att in atts {
            if att.fileName == filename {
                attached = true
                break
            }
        }

        if !attached {
            data.toAttachment(
                msg,
                fileName: filename,
                type: "application/pgp-keys",
                stripMetadata: shouldStripMetaDate
            ).done { attachmentToAdd in
                attachmentToAdd?.setupHeaderInfo(isInline: false, contentID: nil)
                completion(attachmentToAdd)
            }
        } else {
            completion(nil)
        }
    }

    func updateExpirationOffset(expirationTime: TimeInterval,
                                password: String,
                                passwordHint: String,
                                completion: @escaping () -> Void) {
        guard let msg = self.message else {
            completion()
            return
        }
        cacheService.updateExpirationOffset(of: msg,
                                            expirationTime: expirationTime,
                                            pwd: password,
                                            pwdHint: passwordHint,
                                            completion: completion)
    }

    func updateMessageByMessageAction(_ action: ComposeMessageAction) {
        switch action {
        case .reply, .replyAll:
            self.message?.action = action.rawValue as NSNumber?
            if let title = self.message?.title {
                if !title.hasRe() {
                    let re = LocalString._composer_short_reply
                    self.message?.title = "\(re) \(title)"
                }
            }
        case .forward:
            self.message?.action = action.rawValue as NSNumber?
            if let title = self.message?.title {
                if !( title.hasFwd() || title.hasFw() ) {
                    let fwd = LocalString._composer_short_forward
                    self.message?.title = "\(fwd) \(title)"
                }
            }
        default:
            break
        }
    }
}

// MARK: - attachment related functions
extension ComposerMessageHelper {
    func addAttachment(_ file: FileData, shouldStripMetaData: Bool, order: Int? = nil, completion: ((Attachment?) -> Void)?) {
        guard let msg = message else {
            return
        }
        file.contents.toAttachment(msg,
                                   fileName: file.name,
                                   type: file.ext,
                                   stripMetadata: shouldStripMetaData,
                                   isInline: false).done { attachment in
            defer {
                completion?(attachment)
            }
            guard let att = attachment, let msg = self.message else { return }
            self.context.performAndWait {
                att.message = msg
                if let order = order {
                    att.order = Int32(order)
                }
                _ = self.context.saveUpstreamIfNeeded()
            }
            if att.objectID.isTemporaryID {
                self.context.performAndWait {
                    try? self.context.obtainPermanentIDs(for: [att])
                }
            }
        }.cauterize()
    }

    func addMimeAttachments(attachment: MimeAttachment, shouldStripMetaData: Bool, completion: @escaping (Attachment?) -> Void) {
        attachment.toAttachment(message: self.message, stripMetadata: shouldStripMetaData).done { attachment in
            completion(attachment)
        }.cauterize()
    }

    func deleteAttachment(_ attachment: Attachment, completion: @escaping () -> Void) {
        guard let msgID = self.messageID else { return }
        messageDataService.delete(att: AttachmentEntity(attachment),
                                  messageID: msgID).done { _ in
            completion()
        }.cauterize()
    }

    func addAttachment(data: Data,
                       fileName: String,
                       shouldStripMetaData: Bool,
                       isInline: Bool,
                       completion: @escaping (Attachment?) -> Void) {
        guard let msg = self.message else {
            completion(nil)
            return
        }
        data.toAttachment(msg, fileName: fileName,
                          type: "image/png",
                          stripMetadata: shouldStripMetaData,
                          isInline: isInline).done { attachment in
            completion(attachment)
        }.cauterize()
    }

    func addAttachment(_ attachment: Attachment) {
        guard let msg = self.message else { return }
        context.performAndWait {
            attachment.message = msg
            _ = context.saveUpstreamIfNeeded()
        }
    }

    func removeInlineAttachment(fileName: String,
                                isRealAttachment: Bool,
                                completion: (() -> Void)?) {
        // find attachment to remove
        guard let attachment = self.attachments.first(where: { $0.fileName.hasPrefix(fileName)
        }) else { return }

        // decrement number of attachments in message manually
        let number = self.attachments.filter({ attach in
            if attach.isSoftDeleted {
                return false
            } else if isRealAttachment {
                return !attach.inline()
            }
            return true
        }).count

        let newNum = number > 0 ? number - 1 : 0
        context.performAndWait {
            self.message?.numAttachments = NSNumber(value: newNum)
            _ = context.saveUpstreamIfNeeded()
        }

        deleteAttachment(attachment) {
            completion?()
        }
    }

    func updateAttachmentCount(isRealAttachment: Bool) {
        // decrement number of attachments in message manually
        let number = self.attachments.filter({ attach in
            if attach.isSoftDeleted {
                return false
            } else if isRealAttachment {
                return !attach.inline()
            }
            return true
        }).count

        context.performAndWait {
            self.message?.numAttachments = NSNumber(value: number)
             _ = context.saveUpstreamIfNeeded()
        }
    }
}

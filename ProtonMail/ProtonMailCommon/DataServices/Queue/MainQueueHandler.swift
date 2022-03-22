//
//  MainQueueHandler.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton AG
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
import Groot
import PromiseKit
import ProtonCore_Keymaker
import ProtonCore_Networking
import ProtonCore_Services

final class MainQueueHandler: QueueHandler {
    let userID: String
    private let cacheService: CacheService
    private let coreDataService: CoreDataService
    private let apiService: APIService
    private let messageDataService: MessageDataService
    private let conversationDataService: ConversationProvider
    private let labelDataService: LabelsDataService
    private let localNotificationService: LocalNotificationService
    private let contactService: ContactDataService
    private let contactGroupService: ContactGroupsDataService
    private let undoActionManager: UndoActionManagerProtocol
    private weak var user: UserManager?

    init(cacheService: CacheService,
         coreDataService: CoreDataService,
         apiService: APIService,
         messageDataService: MessageDataService,
         conversationDataService: ConversationProvider,
         labelDataService: LabelsDataService,
         localNotificationService: LocalNotificationService,
         undoActionManager: UndoActionManagerProtocol,
         user: UserManager) {
        self.userID = user.userinfo.userId
        self.cacheService = cacheService
        self.coreDataService = coreDataService
        self.apiService = apiService
        self.messageDataService = messageDataService
        self.conversationDataService = conversationDataService
        self.labelDataService = labelDataService
        self.localNotificationService = localNotificationService
        self.contactService = user.contactService
        self.contactGroupService = user.contactGroupService
        self.undoActionManager = undoActionManager
        self.user = user
    }

    func handleTask(_ task: QueueManager.Task, completion: @escaping (QueueManager.Task, QueueManager.TaskResult) -> Void) {
        let completeHandler = handleTaskCompletion(task, notifyQueueManager: completion)
        let action = task.action

        let UID = task.userID
        let uuid = task.uuid
        let isConversation = task.isConversation

        if isConversation {
            // TODO: - v4 refactor conversation method
            switch action {
            case .saveDraft, .uploadAtt, .uploadPubkey, .deleteAtt, .send,
                 .updateLabel, .createLabel, .deleteLabel, .signout, .signin,
                 .fetchMessageDetail, .updateAttKeyPacket,
                 .updateContact, .deleteContact, .addContact,
                 .addContactGroup, .updateContactGroup, .deleteContactGroup:
                fatalError()
            case .emptyTrash, .emptySpam:   // keep this as legacy option for 2-3 releases after 1.11.12
                fatalError()
            case .empty(let labelID):
                self.empty(labelId: labelID, UID: UID, completion: completeHandler)
            case .unread(let currentLabelID, let itemIDs, _):
                self.unreadConversations(itemIDs, labelID: currentLabelID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
            case .read(let itemIDs, _):
                self.readConversations(itemIDs, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
            case .delete(let currentLabelID, let itemIDs):
                self.deleteConversations(itemIDs, labelID: currentLabelID ?? "", writeQueueUUID: uuid, UID: UID, completion: completeHandler)
            case .label(let currentLabelID, _, let isSwipeAction, let itemIDs, _):
                self.labelConversations(itemIDs,
                                        labelID: currentLabelID,
                                        writeQueueUUID: uuid,
                                        UID: UID,
                                        isSwipeAction: isSwipeAction,
                                        completion: completeHandler)
            case .unlabel(let currentLabelID, _, let isSwipeAction, let itemIDs, _):
                self.unlabelConversations(itemIDs,
                                          labelID: currentLabelID,
                                          writeQueueUUID: uuid,
                                          UID: UID,
                                          isSwipeAction: isSwipeAction,
                                          completion: completeHandler)
            case .folder(let nextLabelID, _, let isSwipeAction, let itemIDs, _):
                self.labelConversations(itemIDs,
                                        labelID: nextLabelID,
                                        writeQueueUUID: uuid,
                                        UID: UID,
                                        isSwipeAction: isSwipeAction,
                                        completion: completeHandler)
            }
        } else {
            switch action {
            case .saveDraft(let messageObjectID):
                self.draft(save: messageObjectID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
            case .uploadAtt(let attachmentObjectID):
                self.uploadAttachmentWithAttachmentID(attachmentObjectID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
            case .uploadPubkey(let attachmentObjectID):
                self.uploadPubKey(attachmentObjectID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
            case .deleteAtt(let attachmentObjectID):
                self.deleteAttachmentWithAttachmentID(attachmentObjectID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
            case .updateAttKeyPacket(let messageObjectID, let addressID):
                self.updateAttachmentKeyPacket(messageObjectID: messageObjectID, addressID: addressID, completion: completeHandler)
            case .send(let messageObjectID):
                messageDataService.send(byID: messageObjectID, writeQueueUUID: uuid, UID: UID, completion: completeHandler)
            case .emptyTrash:   // keep this as legacy option for 2-3 releases after 1.11.12
                self.empty(at: .trash, UID: UID, completion: completeHandler)
            case .emptySpam:    // keep this as legacy option for 2-3 releases after 1.11.12
                self.empty(at: .spam, UID: UID, completion: completeHandler)
            case .empty(let currentLabelID):
                self.empty(labelId: currentLabelID, UID: UID, completion: completeHandler)
            case .read(_, let objectIDs):
                self.messageAction(objectIDs, writeQueueUUID: uuid, action: action.rawValue, UID: UID, completion: completeHandler)
            case .unread(_, _, let objectIDs):
                self.messageAction(objectIDs, writeQueueUUID: uuid, action: action.rawValue, UID: UID, completion: completeHandler)
            case .delete(_, let itemIDs):
                self.messageDelete(itemIDs, writeQueueUUID: uuid, action: action.rawValue, UID: UID, completion: completeHandler)
            case .label(let currentLabelID, let shouldFetch, let isSwipeAction, let itemIDs, _):
                self.labelMessage(currentLabelID,
                                  messageIDs: itemIDs,
                                  UID: UID,
                                  shouldFetchEvent: shouldFetch ?? false,
                                  isSwipeAction: isSwipeAction,
                                  completion: completeHandler)
            case .unlabel(let currentLabelID, let shouldFetch, let isSwipeAction, let itemIDs, _):
                self.unLabelMessage(currentLabelID,
                                    messageIDs: itemIDs,
                                    UID: UID,
                                    shouldFetchEvent: shouldFetch ?? false,
                                    isSwipeAction: isSwipeAction,
                                    completion: completeHandler)
            case .folder(let nextLabelID, let shouldFetch, let isSwipeAction, let itemIDs, _):
                self.labelMessage(nextLabelID,
                                  messageIDs: itemIDs,
                                  UID: UID,
                                  shouldFetchEvent: shouldFetch ?? false,
                                  isSwipeAction: isSwipeAction,
                                  completion: completeHandler)
            case .updateLabel(let labelID, let name, let color):
                self.updateLabel(labelID: labelID, name: name, color: color, completion: completeHandler)
            case .createLabel(let name, let color, let isFolder):
                self.createLabel(name: name, color: color, isFolder: isFolder, completion: completeHandler)
            case .deleteLabel(let labelID):
                self.deleteLabel(labelID: labelID, completion: completeHandler)
            case .signout:
                self.signout(completion: completeHandler)
            case .signin:
                break
            case .fetchMessageDetail:
                self.fetchMessageDetail(messageID: task.messageID, completion: completeHandler)
            case .updateContact(let objectID, let cardDatas):
                self.updateContact(objectID: objectID, cardDatas: cardDatas, completion: completeHandler)
            case .deleteContact(let objectID):
                self.deleteContact(objectID: objectID, completion: completeHandler)
            case .addContact(let objectID, let cardDatas):
                self.addContact(objectID: objectID, cardDatas: cardDatas, completion: completeHandler)
            case .addContactGroup(let objectID, let name, let color, let emailIDs):
                self.createContactGroup(objectID: objectID, name: name, color: color, emailIDs: emailIDs, completion: completeHandler)
            case .updateContactGroup(let objectID, let name, let color, let addedEmailList, let removedEmailList):
                self.updateContactGroup(objectID: objectID, name: name, color: color, addedEmailList: addedEmailList, removedEmailList: removedEmailList, completion: completeHandler)
            case .deleteContactGroup(let objectID):
                self.deleteContactGroup(objectID: objectID, completion: completeHandler)
            }
        }
    }

    private func handleTaskCompletion(_ queueTask: QueueManager.Task, notifyQueueManager: @escaping (QueueManager.Task, QueueManager.TaskResult) -> Void) -> CompletionBlock {
        return { task, response, error in
            let helper = TaskCompletionHelper()
            helper.handleResult(queueTask: queueTask,
                                response: response,
                                error: error,
                                notifyQueueManager: notifyQueueManager)
        }
    }
}

// MARK: shared queue actions
extension MainQueueHandler {
    func empty(labelId: String, UID: String, completion: CompletionBlock?) {
        if let location = Message.Location(rawValue: labelId) {
            self.empty(at: location, UID: UID, completion: completion)
        } else {
            self.empty(labelID: labelId, completion: completion)
        }
    }

    private func empty(at location: Message.Location, UID: String, completion: CompletionBlock?) {
        // TODO:: check is label valid
        if location != .spam && location != .trash && location != .draft {
            completion?(nil, nil, nil)
            return
        }

        guard user?.userinfo.userId == UID else {
            completion?(nil, nil, NSError.userLoggedOut())
            return
        }

        let api = EmptyMessage(labelID: location.rawValue)
        self.apiService.exec(route: api, responseObject: VoidResponse()) { (task, response) in
            completion?(task, nil, response.error?.toNSError)
        }
        self.setupTimerToCleanSoftDeletedMessage()
    }

    private func empty(labelID: String, completion: CompletionBlock?) {
        let api = EmptyMessage(labelID: labelID)
        self.apiService.exec(route: api, responseObject: VoidResponse()) { (task, response) in
            completion?(task, nil, response.error?.toNSError)
        }
        self.setupTimerToCleanSoftDeletedMessage()
    }

    private func setupTimerToCleanSoftDeletedMessage() {
        DispatchQueue.main.async {
            // BE schedule a task to delete
            // The task should be executed right after initialization
            // The execute duration depends on the folder size
            Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
                self?.user?.cacheService.cleanSoftDeletedMessagesAndConversation()
            }
        }
    }
}

// MARK: queue actions for single message
extension MainQueueHandler {
    /// - parameter messageObjectID: message objectID string
    fileprivate func draft(save messageObjectID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.operationContext
        var isAttachmentKeyChanged = false
        self.coreDataService.enqueue(context: context) { (context) in
            guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(messageObjectID) else {
                // error: while trying to get objectID
                completion?(nil, nil, NSError.badParameter(messageObjectID))
                return
            }

            guard self.user?.userinfo.userId == UID else {
                completion?(nil, nil, NSError.userLoggedOut())
                return
            }

            do {
                guard let message = try context.existingObject(with: objectID) as? Message else {
                    // error: object is not a Message
                    completion?(nil, nil, NSError.badParameter(messageObjectID))
                    return
                }

                let completionWrapper: CompletionBlock = { task, response, error in
                    guard let mess = response else {
                        defer {
                            // error: response nil
                            completion?(task, nil, error)
                        }
                        guard let err = error else { return }
                        DispatchQueue.main.async {
                            NSError.alertSavingDraftError(details: err.localizedDescription)
                        }
                        if err.isStorageExceeded {
                            context.delete(message)
                            _ = context.saveUpstreamIfNeeded()
                        }
                        return
                    }

                    guard let messageID = mess["ID"] as? String else {
                        // The error is messageID missing from the response
                        // But this is meanless to users
                        // I think parse error is more understandable
                        let parseError = NSError.unableToParseResponse("messageID")
                        NSError.alertSavingDraftError(details: parseError.localizedDescription)
                        completion?(task, nil, error)
                        return
                    }

                    guard let message = try? context.existingObject(with: objectID) as? Message else {
                        // If the message is nil
                        // That means this message is deleted
                        // Should send delete API to make sure this message is deleted
                        let mockAction: MessageAction = .delete(currentLabelID: nil, itemIDs: [])
                        self.messageDelete([messageID], writeQueueUUID: UUID(), action: mockAction.rawValue, UID: UID, completion: nil)
                        completion?(task, nil, nil)
                        return
                    }

                    if message.messageID != messageID {
                        // Cancel scheduled local notification and re-schedule
                        self.localNotificationService
                            .rescheduleMessage(oldID: message.messageID, details: .init(messageID: messageID, subtitle: message.title))
                    }
                    message.messageID = messageID
                    message.isDetailDownloaded = true

                    if let conversationID = mess["ConversationID"] as? String {
                        message.conversationID = conversationID
                    }

                    var hasTemp = false
                    let attachments = message.mutableSetValue(forKey: "attachments")
                    for att in attachments {
                        if let att = att as? Attachment {
                            if att.isTemp {
                                hasTemp = true
                                context.delete(att)
                            }
                            // Prevent flag being overide if current call do not change the key
                            if isAttachmentKeyChanged {
                                att.keyChanged = false
                            }
                        }
                    }

                    if let subject = mess["Subject"] as? String {
                        message.title = subject
                    }
                    if let timeValue = mess["Time"] {
                        if let timeString = timeValue as? NSString {
                            let time = timeString.doubleValue as TimeInterval
                            if time != 0 {
                                message.time = time.asDate()
                            }
                        } else if let dateNumber = timeValue as? NSNumber {
                            let time = dateNumber.doubleValue as TimeInterval
                            if time != 0 {
                                message.time = time.asDate()
                            }
                        }
                    }

                    _ = context.saveUpstreamIfNeeded()

                    if hasTemp {
                        do {
                            try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName, fromJSONDictionary: mess, in: context)
                            _ = context.saveUpstreamIfNeeded()
                        } catch let exc as NSError {
                            completion?(task, response, exc)
                            return
                        }
                    }
                    completion?(task, response, error)
                }

                if let atts = message.attachments.allObjects as? [Attachment] {
                    for att in atts {
                        if att.keyChanged {
                            isAttachmentKeyChanged = true
                        }
                    }
                }

                if message.isDetailDownloaded && UUID(uuidString: message.messageID) == nil {
                    let addr = self.messageDataService.fromAddress(message) ?? message.cachedAddress ?? self.messageDataService.defaultAddress(message)
                    let api = UpdateDraft(message: message, fromAddr: addr, authCredential: message.cachedAuthCredential)
                    self.apiService.exec(route: api, responseObject: UpdateDraftResponse()) { (task, response) in
                        context.perform {
                            if let err = response.error {
                                completionWrapper(task, nil, err.toNSError)
                            } else {
                                completionWrapper(task, response.responseDict, nil)
                            }
                        }
                    }
                } else {
                    let addr = self.messageDataService.fromAddress(message) ?? message.cachedAddress ?? self.messageDataService.defaultAddress(message)
                    let api = CreateDraft(message: message, fromAddr: addr)
                    self.apiService.exec(route: api, responseObject: UpdateDraftResponse()) { (task, response) in
                        context.perform {
                            if let err = response.error {
                                completionWrapper(task, nil, err.toNSError)
                            } else {
                                completionWrapper(task, response.responseDict, nil)
                            }
                        }
                    }
                }
            } catch let ex as NSError {
                // error: context thrown trying to get Message
                completion?(nil, nil, ex)
                return
            }
        }
    }

    fileprivate func uploadPubKey(_ managedObjectID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.operationContext
        guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(managedObjectID),
            let managedObject = try? context.existingObject(with: objectID),
            let _ = managedObject as? Attachment else {
            completion?(nil, nil, NSError.badParameter(managedObjectID))
            return
        }

        self.uploadAttachmentWithAttachmentID(managedObjectID, writeQueueUUID: writeQueueUUID, UID: UID, completion: completion)
        return
    }
    
    private func handleAttachmentResponse(error: NSError?,
                                          response: [String : Any]?,
                                          task: URLSessionDataTask?,
                                          context: NSManagedObjectContext,
                                          attachment: Attachment,
                                          keyPacket: Data,
                                          completion: CompletionBlock?) {
        if error == nil,
           let attDict = response?["Attachment"] as? [String : Any],
           let id = attDict["ID"] as? String
        {
            self.coreDataService.enqueue(context: context) { (context) in
                attachment.attachmentID = id
                attachment.keyPacket = keyPacket.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                attachment.fileData = nil // encrypted attachment is successfully uploaded -> no longer need it cleartext

                // proper headers from BE - important for inline attachments
                if let headerInfoDict = attDict["Headers"] as? Dictionary<String, String> {
                    attachment.headerInfo = "{" + headerInfoDict.compactMap { " \"\($0)\":\"\($1)\" " }.joined(separator: ",") + "}"
                }
                attachment.cleanLocalURLs()

                _ = context.saveUpstreamIfNeeded()
                NotificationCenter
                    .default
                    .post(name: .attachmentUploaded,
                          object: nil,
                          userInfo: ["objectID": attachment.objectID.uriRepresentation().absoluteString,
                                     "attachmentID": attachment.attachmentID])
                completion?(task, response, error)
            }
        } else {
            defer {
                completion?(task, response, error)
            }
            guard let err = error else { return }

            let reason = err.localizedDescription
            NotificationCenter
                .default
                .post(name: .attachmentUploadFailed,
                      object: nil,
                      userInfo: ["objectID": attachment.objectID.uriRepresentation().absoluteString,
                                 "reason": reason,
                                 "code": err.code])
        }
    }

    private func uploadAttachmentWithAttachmentID (_ managedObjectID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.operationContext
        context.perform {
            guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(managedObjectID),
                  let managedObject = try? context.existingObject(with: objectID),
                  let attachment = managedObject as? Attachment else {
                completion?(nil, nil, NSError.badParameter(managedObjectID))
                return
            }

            guard self.user?.userinfo.userId == UID else {
                completion?(nil, nil, NSError.userLoggedOut())
                return
            }

            guard let attachments = attachment.message.attachments.allObjects as? [Attachment] else {
                return
            }
            if let _ = attachments
                .first(where: { $0.contentID() == attachment.contentID() &&
                        $0.attachmentID != "0" }) {
                // This upload is duplicated
                context.delete(attachment)
                _ = context.saveUpstreamIfNeeded()
                completion?(nil, nil, nil)
                return
            }

            let params = [
                "Filename": attachment.fileName,
                "MIMEType": attachment.mimeType,
                "MessageID": attachment.message.messageID,
                "ContentID": attachment.contentID() ?? attachment.fileName,
                "Disposition": attachment.disposition()
            ]

            let addressID = attachment.message.cachedAddress?.addressID ?? self.messageDataService.getAddressID(attachment.message)
            guard
                let key = attachment.message.cachedAddress?.keys.first ?? self.user?.getAddressKey(address_id: addressID),
                let passphrase = attachment.message.cachedPassphrase ?? self.user?.mailboxPassword,
                let userKeys = attachment.message.cachedUser?.userPrivateKeysArray ?? self.user?.userPrivateKeys else {
                completion?(nil, nil, NSError.encryptionError())
                return
            }
            
            autoreleasepool(){
                do {
                    guard let (keyPacket, dataPacketURL) = try attachment.encrypt(byKey: key, mailbox_pwd: passphrase) else
                    {
                        MainQueueHandlerHelper
                            .removeAllAttachmentsNotUploaded(of: attachment.message,
                                                             context: context)
                        completion?(nil, nil, NSError.encryptionError())
                        return
                    }

                    Crypto().freeGolangMem()
                    let signed = attachment.sign(byKey: key,
                                                 userKeys: userKeys,
                                                 passphrase: passphrase)
                    let completionWrapper: CompletionBlock = { task, response, error in
                        self.handleAttachmentResponse(error: error,
                                                      response: response,
                                                      task: task,
                                                      context: context,
                                                      attachment: attachment,
                                                      keyPacket: keyPacket,
                                                      completion: completion)
                    }

                    ///sharedAPIService.upload( byPath: Constants.App.API_PATH + "/attachments",
                    self.user?.apiService.uploadFromFile(byPath: "/attachments",
                                                         parameters: params,
                                                         keyPackets: keyPacket,
                                                         dataPacketSourceFileURL: dataPacketURL,
                                                         signature: signed,
                                                         headers: .empty,
                                                         authenticated: true,
                                                         customAuthCredential: attachment.message.cachedAuthCredential,
                                                         completion: completionWrapper)

                } catch let error {
                    MainQueueHandlerHelper
                        .removeAllAttachmentsNotUploaded(of: attachment.message,
                                                         context: context)
                    let err = error as NSError
                    completion?(nil, nil, err)
                    return
                }
            }
        }
    }

    fileprivate func deleteAttachmentWithAttachmentID (_ deleteObject: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.operationContext
        self.coreDataService.enqueue(context: context) { (context) in
            var authCredential: AuthCredential?
            guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(deleteObject),
                let managedObject = try? context.existingObject(with: objectID),
                let att = managedObject as? Attachment else {

                completion?(nil, nil, NSError.badParameter("Object ID"))
                return
            }
            authCredential = att.message.cachedAuthCredential

            guard self.user?.userinfo.userId == UID else {
                completion?(nil, nil, NSError.userLoggedOut())
                return
            }

            guard att.attachmentID != "0" || !att.attachmentID.isEmpty else {
                completion?(nil, nil, nil)
                return
            }

            let api = DeleteAttachment(attID: att.attachmentID, authCredential: authCredential)
            self.apiService.exec(route: api, responseObject: VoidResponse()) { (task, response) in
                completion!(task, nil, response.error?.toNSError)
            }
        }
    }

    private func updateAttachmentKeyPacket(messageObjectID: String, addressID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.operationContext
        self.coreDataService.enqueue(context: context) { [weak self] (context) in
            guard let self = self,
                  let objectID = self.coreDataService
                    .managedObjectIDForURIRepresentation(messageObjectID) else {
                // error: while trying to get objectID
                completion?(nil, nil, NSError.badParameter(messageObjectID))
                return
            }

            guard let user = self.user else {
                completion?(nil, nil, NSError.userLoggedOut())
                return
            }

            do {
                guard let message = try context
                        .existingObject(with: objectID) as? Message,
                      let attachments = message.attachments.allObjects as? [Attachment] else {
                    // error: object is not a Message
                    completion?(nil, nil, NSError.badParameter(messageObjectID))
                    return
                }

                guard let address = user.userinfo.userAddresses.address(byID: addressID),
                      let key = address.keys.first else {
                    completion?(nil, nil, NSError.badParameter("Address ID"))
                    return
                }

                for att in attachments where !att.isSoftDeleted && att.attachmentID != "0" {
                    guard let sessionPack = user.newSchema ?
                            try att.getSession(userKey: user.userPrivateKeys,
                                               keys: user.addressKeys,
                                               mailboxPassword: user.mailboxPassword) :
                            try att.getSession(keys: user.addressPrivateKeys,
                                               mailboxPassword: user.mailboxPassword) else { // DONE
                        continue
                    }
                    guard let newKeyPack = try sessionPack.key?.getKeyPackage(publicKey: key.publicKey, algo: sessionPack.algo)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) else {
                        continue
                    }
                    att.keyPacket = newKeyPack
                    att.keyChanged = true
                }
                guard let decryptedBody = try self.messageDataService.messageDecrypter.decrypt(message: message) else {
                            // error: object is not a Message
                            completion?(nil, nil, NSError.badParameter("decrypted body"))
                            return
                        }
                message.addressID = addressID
                if message.nextAddressID == addressID {
                    message.nextAddressID = nil
                }
                let mailbox_pwd = user.mailboxPassword
                self.messageDataService.encryptBody(message, clearBody: decryptedBody, mailbox_pwd: mailbox_pwd, error: nil)
                self.messageDataService.saveDraft(message)
                completion?(nil, nil, nil)
            } catch let ex as NSError {
                // error: context thrown trying to get Message
                completion?(nil, nil, ex)
                return
            }
        }
    }

    fileprivate func messageAction(_ managedObjectIds: [String], writeQueueUUID: UUID, action: String, UID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.operationContext
        context.performAndWait {
            let messages = managedObjectIds.compactMap { (id: String) -> Message? in
                if let objectID = self.coreDataService.managedObjectIDForURIRepresentation(id),
                    let managedObject = try? context.existingObject(with: objectID) {
                    return managedObject as? Message
                }
                return nil
            }

            guard self.user?.userinfo.userId == UID else {
                completion!(nil, nil, NSError.userLoggedOut())
                return
            }

            let messageIds = messages.map { $0.messageID }
            guard messageIds.count > 0 else {
                completion!(nil, nil, nil)
                return
            }
            let api = MessageActionRequest(action: action, ids: messageIds)
            self.apiService.exec(route: api, responseObject: VoidResponse()) { (task, response) in
                completion!(task, nil, response.error?.toNSError)
            }
        }
    }

    /// delete a message
    ///
    /// - Parameters:
    ///   - messageIDs: must be the real message id. becuase the message is deleted before this triggered
    ///   - writeQueueUUID: queue UID
    ///   - action: action type. should .delete here
    ///   - completion: call back
    fileprivate func messageDelete(_ messageIDs: [String], writeQueueUUID: UUID, action: String, UID: String, completion: CompletionBlock?) {
        guard user?.userinfo.userId == UID else {
            completion?(nil, nil, NSError.userLoggedOut())
            return
        }
        guard !messageIDs.isEmpty else {
            completion?(nil, nil, nil)
            return
        }

        let api = MessageActionRequest(action: action, ids: messageIDs)
        self.apiService.exec(route: api, responseObject: VoidResponse()) { (task, response) in
            completion!(task, nil, response.error?.toNSError)
        }
    }

    fileprivate func labelMessage(_ labelID: String,
                                  messageIDs: [String],
                                  UID: String,
                                  shouldFetchEvent: Bool,
                                  isSwipeAction: Bool,
                                  completion: CompletionBlock?) {
        guard user?.userinfo.userId == UID else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }

        let api = ApplyLabelToMessagesRequest(labelID: labelID, messages: messageIDs)
        apiService.exec(route: api) { [weak self] (result: Swift.Result<ApplyLabelToMessagesResponse, ResponseError>) in
            if shouldFetchEvent {
                self?.user?.eventsService.fetchEvents(labelID: labelID)
            }
            switch result {
            case .success(let response):
                if let undoTokenData = response.undoTokenData {
                    let type = self?.undoActionManager.calculateUndoActionBy(labelID: labelID)
                    self?.undoActionManager.addUndoToken(undoTokenData,
                                                         undoActionType: type)
                }
                completion?(nil, nil, nil)
            case .failure(let error):
                completion?(nil, nil, error.toNSError)
            }
        }
    }

    fileprivate func unLabelMessage(_ labelID: String,
                                    messageIDs: [String],
                                    UID: String,
                                    shouldFetchEvent: Bool,
                                    isSwipeAction: Bool,
                                    completion: CompletionBlock?) {
        guard user?.userinfo.userId == UID else {
            completion!(nil, nil, NSError.userLoggedOut())
            return
        }

        let api = RemoveLabelFromMessagesRequest(labelID: labelID, messages: messageIDs)
        apiService.exec(route: api) { [weak self] (result: Swift.Result<RemoveLabelFromMessagesResponse, ResponseError>) in
            if shouldFetchEvent {
                self?.user?.eventsService.fetchEvents(labelID: labelID)
            }
            switch result {
            case .success(let response):
                if let undoTokenData = response.undoTokenData {
                    let type = self?.undoActionManager.calculateUndoActionBy(labelID: labelID)
                    self?.undoActionManager.addUndoToken(undoTokenData,
                                                         undoActionType: type)
                }
                completion?(nil, nil, nil)
            case .failure(let error):
                completion?(nil, nil, error.toNSError)
            }
        }
    }

    private func createLabel(name: String, color: String, isFolder: Bool, parentID: String? = nil, notify: Bool = true, expanded: Bool = true, completion: CompletionBlock?) {

        let type: PMLabelType = isFolder ? .folder: .label
        let api = CreateLabelRequest(name: name, color: color, type: type, parentID: parentID, notify: notify, expanded: expanded)
        self.apiService.exec(route: api, responseObject: CreateLabelRequestResponse()) { (task, response) in
            guard response.error == nil else {
                completion?(nil, nil, response.error?.toNSError)
                return
            }
            self.labelDataService.addNewLabel(response.label)
            completion?(task, nil, response.error?.toNSError)
        }
    }

    private func updateLabel(labelID: String, name: String, color: String, completion: CompletionBlock?) {
        let api = UpdateLabelRequest(id: labelID, name: name, color: color)
        self.apiService.exec(route: api, responseObject: VoidResponse()) { [weak self] (task, response) in
            self?.user?.eventsService.fetchEvents(labelID: labelID)
            completion?(task, nil, response.error?.toNSError)
        }
    }

    private func deleteLabel(labelID: String, completion: CompletionBlock?) {
        let api = DeleteLabelRequest(lable_id: labelID)
        self.apiService.exec(route: api, responseObject: VoidResponse()) { (task, response) in
            completion?(task, nil, response.error?.toNSError)
        }
    }

    private func signout(completion: CompletionBlock?) {
        let api = AuthDeleteRequest()
        self.apiService.exec(route: api, responseObject: VoidResponse()) { (task: URLSessionDataTask?, response) in
            completion?(task, nil, response.error?.toNSError)
            // probably we want to notify user the session will seem active on website in case of error
        }
    }

    private func fetchMessageDetail(messageID: String, completion: CompletionBlock?) {
        let context = self.coreDataService.operationContext
        self.coreDataService.enqueue(context: context) { [weak self] (context) in
            guard let message = Message
                    .messageForMessageID(messageID, inManagedObjectContext: context) else {
                completion?(nil, nil, nil)
                return
            }
            self?.messageDataService.ForcefetchDetailForMessage(message, runInQueue: false, completion: { _, _, _, error in
                guard error == nil else {
                    completion?(nil, nil, error)
                    return
                }
                completion?(nil, nil, nil)
            })
        }
    }
}

// MARK: Contact service
extension MainQueueHandler {
    private func updateContact(objectID: String, cardDatas: [CardData], completion: CompletionBlock?) {
        let dataService = self.coreDataService
        let context = self.coreDataService.operationContext
        let service = self.contactService
        context.perform {
            guard let managedID = dataService.managedObjectIDForURIRepresentation(objectID),
                  let managedObject = try? context.existingObject(with: managedID),
                  let contact = managedObject as? Contact else {
                completion?(nil, nil, NSError.badParameter("contact objectID"))
                return
            }
            service.update(contactID: contact.contactID, cards: cardDatas) { contact, error in
                completion?(nil, nil, error)
            }
        }
    }

    private func deleteContact(objectID: String, completion: CompletionBlock?) {
        let dataService = self.coreDataService
        let context = self.coreDataService.operationContext
        let service = self.contactService
        context.perform {
            guard let managedID = dataService.managedObjectIDForURIRepresentation(objectID),
                  let managedObject = try? context.existingObject(with: managedID),
                  let contact = managedObject as? Contact else {
                completion?(nil, nil, NSError.badParameter("contact objectID"))
                return
            }
            service.delete(contactID: contact.contactID) { error in
                completion?(nil, nil, error)
            }
        }
    }

    private func addContact(objectID: String, cardDatas: [CardData], completion: CompletionBlock?) {
        let service = self.contactService
        service.add(cards: [cardDatas], authCredential: nil, objectID: objectID) { contacts, error in
            completion?(nil, nil, error)
        }
    }

    /// - Parameters:
    ///   - objectID: CoreData object ID of temp group label
    ///   - name: Group label name
    ///   - color: Group label color
    ///   - emailIDs: Email id array
    ///   - completion: Completion
    private func createContactGroup(objectID: String, name: String, color: String, emailIDs: [String], completion: CompletionBlock?) {
        let service = self.contactGroupService
        firstly {
            return service.createContactGroup(name: name,
                                              color: color,
                                              objectID: objectID)
        }.then { (id: String) -> Promise<Void> in
            return service.addEmailsToContactGroup(groupID: id,
                                                   emailList: [],
                                                   emailIDs: emailIDs)
        }.done {
            completion?(nil, nil, nil)
        }.catch { error in
            completion?(nil, nil, error as NSError)
        }
    }

    /// - Parameters:
    ///   - objectID: Core data object of the group label
    ///   - name: Group label name
    ///   - color: Group label color
    ///   - addedEmailList: The emailID list that will add to this group label
    ///   - removedEmailList: The emailID list that will remove from this group label
    ///   - completion: Completion
    private func updateContactGroup(objectID: String, name: String, color: String, addedEmailList: [String], removedEmailList: [String], completion: CompletionBlock?) {
        let dataService = self.coreDataService
        let context = self.coreDataService.operationContext
        let service = self.contactGroupService
        context.perform {
            guard let managedID = dataService.managedObjectIDForURIRepresentation(objectID),
                  let managedObject = try? context.existingObject(with: managedID),
                  let label = managedObject as? Label else {
                completion?(nil, nil, NSError.badParameter("Group label objectID"))
                return
            }
            let groupID = label.labelID
            firstly {
                return service.editContactGroup(groupID: groupID, name: name, color: color)
            }.then {
                return service.addEmailsToContactGroup(groupID: groupID,
                                                       emailList: [],
                                                       emailIDs: addedEmailList)
            }.then {
                return service.removeEmailsFromContactGroup(groupID: groupID,
                                                            emailList: [],
                                                            emailIDs: removedEmailList)
            }.done {
                completion?(nil, nil, nil)
            }.catch { error in
                completion?(nil, nil, error as NSError)
            }
        }
    }

    private func deleteContactGroup(objectID: String, completion: CompletionBlock?) {
        let dataService = self.coreDataService
        let context = self.coreDataService.operationContext
        let service = self.contactGroupService
        context.perform {
            guard let managedID = dataService.managedObjectIDForURIRepresentation(objectID),
                  let managedObject = try? context.existingObject(with: managedID),
                  let label = managedObject as? Label else {
                completion?(nil, nil, NSError.badParameter("Group label objectID"))
                return
            }
            let groupID = label.labelID
            service.deleteContactGroup(groupID: groupID).done {
                completion?(nil, nil, nil)
            }.catch { error in
                completion?(nil, nil, error as NSError)
            }
        }
    }
}

// MARK: queue actions for conversation
extension MainQueueHandler {
    fileprivate func unreadConversations(_ conversationIds: [String], labelID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        conversationDataService.markAsUnread(conversationIDs: conversationIds, labelID: labelID) { result in
            completion?(nil, nil, result.nsError)
        }
    }

    fileprivate func readConversations(_ conversationIds: [String], writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        conversationDataService.markAsRead(conversationIDs: conversationIds, labelID: "") { result in
            completion?(nil, nil, result.nsError)
        }
    }

    fileprivate func deleteConversations(_ conversationIds: [String], labelID: String, writeQueueUUID: UUID, UID: String, completion: CompletionBlock?) {
        conversationDataService.deleteConversations(with: conversationIds, labelID: labelID) { result in
            completion?(nil, nil, result.nsError)
        }
    }

    fileprivate func labelConversations(_ conversationIds: [String],
                                        labelID: String,
                                        writeQueueUUID: UUID,
                                        UID: String,
                                        isSwipeAction: Bool,
                                        completion: CompletionBlock?) {
        conversationDataService.label(conversationIDs: conversationIds, as: labelID, isSwipeAction: isSwipeAction) { result in
            completion?(nil, nil, result.nsError)
        }
    }

    fileprivate func unlabelConversations(_ conversationIds: [String],
                                          labelID: String,
                                          writeQueueUUID: UUID,
                                          UID: String,
                                          isSwipeAction: Bool,
                                          completion: CompletionBlock?) {
        conversationDataService.unlabel(conversationIDs: conversationIds, as: labelID, isSwipeAction: isSwipeAction) { result in
            completion?(nil, nil, result.nsError)
        }
    }
}

enum MainQueueHandlerHelper {
    static func removeAllAttachmentsNotUploaded(of message: Message,
                                                context: NSManagedObjectContext) {
        let toBeDeleted = message.attachments
            .compactMap({ $0 as? Attachment })
            .filter({ !$0.isUploaded })

        toBeDeleted.forEach { attachment in
            context.delete(attachment)
        }
        let attachmentCount = message.numAttachments.intValue
        message.numAttachments = NSNumber(integerLiteral: max(attachmentCount - toBeDeleted.count, 0))
        _ = context.saveUpstreamIfNeeded()
        context.refreshAllObjects()
    }
}

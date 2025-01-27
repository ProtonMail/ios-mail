//
//  MainQueueHandler.swift
//  Proton Mail
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
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreServices
import enum ProtonCoreUtilities.Either

final class MainQueueHandler: QueueHandler {
    typealias Completion = (Error?) -> Void

    let userID: UserID
    private let coreDataService: CoreDataContextProviderProtocol
    private let apiService: APIService
    private let messageDataService: MessageDataService
    private let conversationDataService: ConversationProvider
    private let labelDataService: LabelsDataService
    private let contactService: ContactDataService
    private let contactGroupService: ContactGroupsDataService
    private let undoActionManager: UndoActionManagerProtocol
    private weak var user: UserManager?
    private let sendMessageResultHandler = SendMessageResultNotificationHandler()
    private let sendMessageTask: SendMessageTask
    private let dependencies: Dependencies

    init(coreDataService: CoreDataContextProviderProtocol,
         fetchMessageDetail: FetchMessageDetailUseCase,
         apiService: APIService,
         messageDataService: MessageDataService,
         conversationDataService: ConversationProvider,
         labelDataService: LabelsDataService,
         localNotificationService: LocalNotificationService,
         undoActionManager: UndoActionManagerProtocol,
         user: UserManager
    ) {
        self.userID = user.userID
        self.coreDataService = coreDataService
        self.apiService = apiService
        self.messageDataService = messageDataService
        self.conversationDataService = conversationDataService
        self.labelDataService = labelDataService
        self.contactService = user.contactService
        self.contactGroupService = user.contactGroupService
        self.undoActionManager = undoActionManager
        self.user = user

        let sendUseCase = SendMessageBuilder.make(
            userData: user,
            apiService: apiService,
            messageDataService: messageDataService,
            prepareSendMetadataBuilderDependencies: user.container
        )
        let isUserAuthenticated: (UserID) -> Bool = { [weak user] userID in
            guard let userManager = user else {
                return false
            }
            return userManager.userID == userID
        }
        let sendDepenedencies = SendMessageTask.Dependencies(
            isUserAuthenticated: isUserAuthenticated,
            messageDataService: messageDataService,
            fetchMessageDetail: fetchMessageDetail,
            sendMessage: sendUseCase,
            localNotificationService: localNotificationService,
            eventsFetching: user.eventsService,
            undoActionManager: undoActionManager
        )
        self.sendMessageTask = SendMessageTask(dependencies: sendDepenedencies)
        sendMessageResultHandler.startObservingResult()

        let uploadDraftUseCase = UploadDraft(
            dependencies: .init(
                apiService: apiService,
                coreDataService: coreDataService,
                messageDataService: messageDataService
            )
        )

        let uploadAttachment = UploadAttachment(
            dependencies: .init(
                messageDataService: user.messageService,
                user: user
            )
        )
        let messageActionUpdate = MessageActionUpdate(dependencies: .init(apiService: apiService, contextProvider: coreDataService))
        let unSnooze = UnSnooze(dependencies: .init(apiService: apiService))

        self.dependencies = Dependencies(
            incomingDefaultService: user.incomingDefaultService,
            uploadDraft: uploadDraftUseCase,
            uploadAttachment: uploadAttachment, 
            messageActionUpdate: messageActionUpdate,
            unSnooze: unSnooze
        )
    }

    func handleTask(_ task: QueueManager.Task, completion: @escaping (QueueManager.Task, QueueManager.TaskResult) -> Void) {
        let completeHandler = handleTaskCompletion(task, notifyQueueManager: completion)
        let action = task.action

        let UID = task.userID.rawValue
        let isConversation = task.isConversation

        if isConversation {
            // TODO: - v4 refactor conversation method
            switch action {
            case .saveDraft, .uploadAtt, .uploadPubkey, .deleteAtt, .send,
                 .updateLabel, .createLabel, .deleteLabel, .signout, .signin,
                 .fetchMessageDetail, .updateAttKeyPacket,
                 .updateContact, .deleteContact, .addContact, .addContacts, .fetchContactDetail,
                 .addContactGroup, .updateContactGroup, .deleteContactGroup,
                 .blockSender, .unblockSender:
                fatalError()
            case .emptyTrash, .emptySpam:   // keep this as legacy option for 2-3 releases after 1.11.12
                fatalError()
            case .empty(let labelID):
                self.empty(labelId: labelID, UID: UID, completion: completeHandler)
            case .unread(let currentLabelID, let itemIDs, _):
                self.unreadConversations(itemIDs, labelID: currentLabelID, completion: completeHandler)
            case .read(let itemIDs, _):
                self.readConversations(itemIDs, completion: completeHandler)
            case .delete(let currentLabelID, let itemIDs):
                self.deleteConversations(itemIDs, labelID: currentLabelID ?? "", completion: completeHandler)
            case .label(let currentLabelID, _, let itemIDs, _):
                self.labelConversations(itemIDs,
                                        labelID: currentLabelID,
                                        completion: completeHandler)
            case .unlabel(let currentLabelID, _, let itemIDs, _):
                self.unlabelConversations(itemIDs,
                                          labelID: currentLabelID,
                                          completion: completeHandler)
            case .folder(let nextLabelID, _, let itemIDs, _):
                self.labelConversations(itemIDs,
                                        labelID: nextLabelID,
                                        completion: completeHandler)
            case .unsnooze(let conversationID):
                unSnooze(conversationID: conversationID, completion: completeHandler)
            case .snooze(let conversationIDs, let date):
                snooze(conversationIDs: conversationIDs, on: date, completion: completeHandler)
            case let .notificationAction(messageID, action):
                notificationAction(messageId: messageID, action: action, completion: completeHandler)
            }
        } else {
            switch action {
            case .saveDraft(let messageObjectID):
                self.draft(save: messageObjectID, completion: completeHandler)
            case .uploadAtt(let attachmentObjectID), .uploadPubkey(let attachmentObjectID):
                self.uploadAttachment(with: attachmentObjectID, completion: completeHandler)
            case .deleteAtt(let attachmentObjectID, let attachmentID):
                self.deleteAttachmentWithAttachmentID(
                    attachmentObjectID,
                    attachmentID: attachmentID,
                    UID: UID,
                    completion: completeHandler
                )
            case .updateAttKeyPacket(let messageObjectID, let addressID):
                do {
                    try self.updateAttachmentKeyPacket(messageObjectID: messageObjectID, addressID: addressID)
                    completeHandler(nil)
                } catch {
                    completeHandler(error)
                }
            case .send:
                // This looks like duplicated but we need it
                // Some how the value of deliveryTime in switch case .send(...) is wrong
                // But correct in if case let
                if case let .send(messageObjectID, deliveryTime) = action {
                    let params = SendMessageTask.Params(
                        messageURI: messageObjectID,
                        deliveryTime: deliveryTime,
                        undoSendDelay: user?.userInfo.delaySendSeconds ?? 0,
                        userID: UserID(rawValue: UID)
                    )
                    sendMessageTask.run(params: params, completion: completeHandler)
                } else {
                    SystemLogger.log(message: "Sending could not proceed", category: .sendMessage)
                }
            case .emptyTrash:   // keep this as legacy option for 2-3 releases after 1.11.12
                self.empty(at: .trash, UID: UID, completion: completeHandler)
            case .emptySpam:    // keep this as legacy option for 2-3 releases after 1.11.12
                self.empty(at: .spam, UID: UID, completion: completeHandler)
            case .empty(let currentLabelID):
                self.empty(labelId: currentLabelID, UID: UID, completion: completeHandler)
            case .read(_, let objectIDs):
                messageAction(.left(objectIDs), action: .read, UID: UID, completion: completeHandler)
            case .unread(_, _, let objectIDs):
                messageAction(.left(objectIDs), action: .unread, UID: UID, completion: completeHandler)
            case .delete(_, let itemIDs):
                // must be the real message id. because the message is deleted before this triggered
                let ids = itemIDs.map(MessageID.init(rawValue:))
                messageAction(.right(ids), action: .delete, UID: UID, completion: completeHandler)
            case .label(let currentLabelID, let shouldFetch, let itemIDs, _):
                self.labelMessage(LabelID(currentLabelID),
                                  messageIDs: itemIDs,
                                  UID: UID,
                                  shouldFetchEvent: shouldFetch ?? false,
                                  completion: completeHandler)
            case .unlabel(let currentLabelID, let shouldFetch, let itemIDs, _):
                self.unLabelMessage(LabelID(currentLabelID),
                                    messageIDs: itemIDs,
                                    UID: UID,
                                    shouldFetchEvent: shouldFetch ?? false,
                                    completion: completeHandler)
            case .folder(let nextLabelID, let shouldFetch, let itemIDs, _):
                self.labelMessage(LabelID(nextLabelID),
                                  messageIDs: itemIDs,
                                  UID: UID,
                                  shouldFetchEvent: shouldFetch ?? false,
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
            case .addContact(let objectID, let contactCards, let importFromDevice):
                self.addContacts(
                    objectsURIs: [objectID],
                    contactsCards: [contactCards],
                    importFromDevice: importFromDevice,
                    completion: completeHandler
                )
            case .addContacts(let contactsLocalURIs, let contactsCards, let importFromDevice):
                self.addContacts(
                    objectsURIs: contactsLocalURIs,
                    contactsCards: contactsCards,
                    importFromDevice: true,
                    completion: completeHandler
                )
            case .fetchContactDetail(let contactIDs):
                fetchContactDetails(IDs: contactIDs, completion: completeHandler)
            case .addContactGroup(let objectID, let name, let color, let emailIDs):
                self.createContactGroup(objectID: objectID, name: name, color: color, emailIDs: emailIDs, completion: completeHandler)
            case .updateContactGroup(let objectID, let name, let color, let addedEmailIDs, let removedEmailIDs):
                self.updateContactGroup(objectID: objectID, name: name, color: color, addedEmailIDs: addedEmailIDs, removedEmailIDs: removedEmailIDs, completion: completeHandler)
            case .deleteContactGroup(let objectID):
                self.deleteContactGroup(objectID: objectID, completion: completeHandler)
            case let .notificationAction(messageID, action):
                notificationAction(messageId: messageID, action: action, completion: completeHandler)
            case .blockSender(let emailAddress):
                blockSender(emailAddress: emailAddress, completion: completeHandler)
            case .unblockSender(let emailAddress):
                unblockSender(emailAddress: emailAddress, completion: completeHandler)
            case .unsnooze, .snooze:
                fatalError()
            }
        }
    }

    private func fetchContactDetails(IDs: [String], completion: @escaping Completion) {
        Task {
            let contactIDs = IDs.map { ContactID(rawValue: $0) }
            await contactService.fetchContactsInParallel(contactIDs: contactIDs)
            completion(nil)
        }
    }

    private func handleTaskCompletion(_ queueTask: QueueManager.Task, notifyQueueManager: @escaping (QueueManager.Task, QueueManager.TaskResult) -> Void) -> Completion {
        { error in
            let helper = TaskCompletionHelper()
            helper.handleResult(queueTask: queueTask,
                                error: error as NSError?,
                                notifyQueueManager: notifyQueueManager)
        }
    }
}

// MARK: shared queue actions
extension MainQueueHandler {
    func empty(labelId: String, UID: String, completion: @escaping Completion) {
        if let location = Message.Location(rawValue: labelId) {
            self.empty(at: location, UID: UID, completion: completion)
        } else {
            self.empty(labelID: labelId, completion: completion)
        }
    }

    private func empty(at location: Message.Location, UID: String, completion: @escaping Completion) {
        // TODO:: check is label valid
        if location != .spam && location != .trash && location != .draft {
            completion(nil)
            return
        }

        guard user?.userInfo.userId == UID else {
            completion(NSError.userLoggedOut())
            return
        }

        let api = EmptyMessageRequest(labelID: location.rawValue)
        self.apiService.perform(request: api, response: VoidResponse()) { _, response in
            completion(response.error)
        }
        self.setupTimerToCleanSoftDeletedMessage()
    }

    private func empty(labelID: String, completion: @escaping Completion) {
        let api = EmptyMessageRequest(labelID: labelID)
        self.apiService.perform(request: api, response: VoidResponse()) { _, response in
            completion(response.error)
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
    fileprivate func draft(save messageObjectID: String, completion: @escaping Completion) {
        Task {
            do {
                try await self.dependencies.uploadDraft.execute(messageObjectID: messageObjectID)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    private func uploadAttachment(with attachmentURI: String, completion: @escaping Completion) {
        Task {
            do {
                try await dependencies.uploadAttachment.execute(attachmentURI: attachmentURI)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    private func deleteAttachmentWithAttachmentID(
        _ deleteObjectID: String,
        attachmentID: String?,
        UID: String,
        completion: @escaping Completion
    ) {
        coreDataService.performOnRootSavingContext { [weak self] context in
            guard let self = self else {
                completion(nil)
                return
            }
            var authCredential: AuthCredential?
            guard let objectID = self.coreDataService.managedObjectIDForURIRepresentation(deleteObjectID),
                  let managedObject = try? context.existingObject(with: objectID),
                  let att = managedObject as? Attachment else {
                      completion(NSError.badParameter("Object ID"))
                      return
                  }
            authCredential = att.message.cachedAuthCredential

            guard self.user?.userInfo.userId == UID else {
                completion(NSError.userLoggedOut())
                return
            }

            let attachmentIDToDelete: String
            if let nonEmptyAttachmentID = attachmentID, nonEmptyAttachmentID != "0" {
                attachmentIDToDelete = nonEmptyAttachmentID
            } else {
                attachmentIDToDelete = att.attachmentID
            }

            if attachmentIDToDelete == "0" || attachmentIDToDelete.isEmpty {
                completion(nil)
                return
            }

            let api = DeleteAttachment(attID: attachmentIDToDelete, authCredential: authCredential)
            self.apiService.perform(request: api, response: VoidResponse()) { _, response in
                completion(response.error)
            }
        }
    }

    private func updateAttachmentKeyPacket(messageObjectID: String, addressID: String) throws {
        try coreDataService.write { [weak self] context in
            guard let self = self,
                  let objectID = self.coreDataService
                    .managedObjectIDForURIRepresentation(messageObjectID) else {
                throw NSError.badParameter(messageObjectID)
            }

            guard let user = self.user else {
                throw NSError.userLoggedOut()
            }

                guard let message = try context
                        .existingObject(with: objectID) as? Message,
                      let attachments = message.attachments.allObjects as? [Attachment] else {
                    // error: object is not a Message
                    throw NSError.badParameter(messageObjectID)
                }

                guard let address = user.userInfo.userAddresses.address(byID: addressID),
                      let key = address.keys.first else {
                    throw NSError.badParameter("Address ID")
                }

                for attachment in attachments where !attachment.isSoftDeleted && attachment.attachmentID != "0" {
                    guard let sessionPack = try attachment.getSession(
                        userKeys: user.userInfo.userPrivateKeys,
                        keys: user.userInfo.addressKeys,
                        mailboxPassword: user.mailboxPassword
                    ) else {
                        continue
                    }
                    guard let newKeyPack = try sessionPack.sessionKey.getKeyPackage(
                        publicKey: key.publicKey,
                        algo: sessionPack.algo.value
                    )?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) else {
                        continue
                    }
                    attachment.keyPacket = newKeyPack
                    attachment.keyChanged = true
                }
                let decryptedBody = try self.messageDataService.messageDecrypter.decrypt(messageObject: message).body
                message.addressID = addressID
                if message.nextAddressID == addressID {
                    message.nextAddressID = nil
                }
                let mailboxPassword = user.mailboxPassword
                message.mimeType = Message.MimeType.textHTML.rawValue
                message.body = try self.messageDataService.encryptBody(
                    .init(addressID),
                    clearBody: decryptedBody,
                    mailbox_pwd: mailboxPassword
                )
        }
    }

    private func messageAction(
        _ ids: Either<[MessageActionUpdateUseCase.MessageURI], [MessageID]>,
        action: MessageActionUpdate.Action,
        UID: String,
        completion: @escaping Completion
    ) {
        guard user?.userInfo.userId == UID else {
            completion(NSError.userLoggedOut())
            return
        }
        ConcurrencyUtils.runWithCompletion(
            block: dependencies.messageActionUpdate.execute,
            arguments: (ids, action)
        ) { result in
            completion(result.error)
        }
    }

    fileprivate func labelMessage(_ labelID: LabelID,
                                  messageIDs: [String],
                                  UID: String,
                                  shouldFetchEvent: Bool,
                                  completion: @escaping Completion) {
        guard user?.userInfo.userId == UID else {
            completion(NSError.userLoggedOut())
            return
        }

        let api = ApplyLabelToMessagesRequest(labelID: labelID, messages: messageIDs)
        apiService.perform(request: api) { [weak self] (_, result: Swift.Result<ApplyLabelToMessagesResponse, ResponseError>) in
            if shouldFetchEvent {
                self?.user?.eventsService.fetchEvents(labelID: labelID)
            }
            switch result {
            case .success(let response):
                if let undoTokenData = response.undoToken {
                    let type = self?.undoActionManager.calculateUndoActionBy(labelID: labelID)
                    self?.undoActionManager.addUndoToken(undoTokenData,
                                                         undoActionType: type)
                }
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    fileprivate func unLabelMessage(_ labelID: LabelID,
                                    messageIDs: [String],
                                    UID: String,
                                    shouldFetchEvent: Bool,
                                    completion: @escaping Completion) {
        guard user?.userInfo.userId == UID else {
            completion(NSError.userLoggedOut())
            return
        }

        let api = RemoveLabelFromMessagesRequest(labelID: labelID, messages: messageIDs)
        apiService.perform(request: api) { [weak self] (_, result: Swift.Result<RemoveLabelFromMessagesResponse, ResponseError>) in
            if shouldFetchEvent {
                self?.user?.eventsService.fetchEvents(labelID: labelID)
            }
            switch result {
            case .success(let response):
                if let undoTokenData = response.undoToken {
                    let type = self?.undoActionManager.calculateUndoActionBy(labelID: labelID)
                    self?.undoActionManager.addUndoToken(undoTokenData,
                                                         undoActionType: type)
                }
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    private func createLabel(name: String, color: String, isFolder: Bool, parentID: String? = nil, notify: Bool = true, expanded: Bool = true, completion: @escaping Completion) {
        let type: PMLabelType = isFolder ? .folder: .label
        let api = CreateLabelRequest(name: name, color: color, type: type, parentID: parentID, notify: notify, expanded: expanded)
        self.apiService.perform(request: api, response: CreateLabelRequestResponse()) { _, response in
            guard response.error == nil else {
                completion(response.error)
                return
            }
            self.labelDataService.addNewLabel(response.label)
            completion(response.error)
        }
    }

    private func updateLabel(labelID: String, name: String, color: String, completion: @escaping Completion) {
        let api = UpdateLabelRequest(id: labelID, name: name, color: color)
        self.apiService.perform(request: api, response: VoidResponse()) { [weak self] _, response in
            self?.user?.eventsService.fetchEvents(labelID: LabelID(labelID))
            completion(response.error)
        }
    }

    private func deleteLabel(labelID: String, completion: @escaping Completion) {
        let api = DeleteLabelRequest(lable_id: labelID)
        self.apiService.perform(request: api, response: VoidResponse()) { _, response in
            completion(response.error)
        }
    }

    private func signout(completion: @escaping Completion) {
        let api = AuthDeleteRequest()
        self.apiService.perform(request: api, response: VoidResponse()) { _, response in
            completion(response.error)
            // probably we want to notify user the session will seem active on website in case of error
        }
    }

    private func fetchMessageDetail(messageID: String, completion: @escaping Completion) {
        coreDataService.enqueueOnRootSavingContext { [weak self] context in
            guard let message = Message
                    .messageForMessageID(messageID, inManagedObjectContext: context) else {
                completion(nil)
                return
            }
            self?.messageDataService.forceFetchDetailForMessage(MessageEntity(message), runInQueue: false, completion: { error in
                guard error == nil else {
                    completion(error)
                    return
                }
                completion(nil)
            })
        }
    }
}

// MARK: Contact service
extension MainQueueHandler {
    private func updateContact(objectID: String, cardDatas: [CardData], completion: @escaping Completion) {
        let dataService = self.coreDataService
        let service = self.contactService
        coreDataService.performOnRootSavingContext { context in
            guard let managedID = dataService.managedObjectIDForURIRepresentation(objectID),
                  let managedObject = try? context.existingObject(with: managedID),
                  let contact = managedObject as? Contact else {
                completion(NSError.badParameter("contact objectID"))
                return
            }
            service.update(contactID: ContactID(contact.contactID), cards: cardDatas) { error in
                completion(error)
            }
        }
    }

    private func deleteContact(objectID: String, completion: @escaping Completion) {
        let dataService = self.coreDataService
        let service = self.contactService
        coreDataService.performOnRootSavingContext { context in
            guard let managedID = dataService.managedObjectIDForURIRepresentation(objectID),
                  let managedObject = try? context.existingObject(with: managedID),
                  let contact = managedObject as? Contact else {
                completion(NSError.badParameter("contact objectID"))
                return
            }
            service.delete(contactID: ContactID(contact.contactID)) { error in
                completion(error)
            }
        }
    }

    private func addContacts(
        objectsURIs: [String],
        contactsCards: [[CardData]],
        importFromDevice: Bool,
        completion: @escaping Completion
    ) {
        let service = self.contactService
        service.add(
            contactsCards: contactsCards,
            objectsURIs: objectsURIs,
            importFromDevice: importFromDevice,
            completion: completion
        )
    }

    /// - Parameters:
    ///   - objectID: CoreData object ID of temp group label
    ///   - name: Group label name
    ///   - color: Group label color
    ///   - emailIDs: Email id array
    ///   - completion: Completion
    private func createContactGroup(objectID: String, name: String, color: String, emailIDs: [String], completion: @escaping Completion) {
        let service = self.contactGroupService
        firstly {
            return service.createContactGroup(name: name,
                                              color: color,
                                              objectID: objectID)
        }.then { (id: String) -> Promise<Void> in
            return service.addEmailsToContactGroup(groupID: LabelID(id),
                                                   emailList: [],
                                                   emailIDs: emailIDs)
        }.done {
            completion(nil)
        }.catch { error in
            completion(error as NSError)
        }
    }

    /// - Parameters:
    ///   - objectID: Core data object of the group label
    ///   - name: Group label name
    ///   - color: Group label color
    ///   - addedEmailIDs: The emailID list that will add to this group label
    ///   - removedEmailIDs: The emailID list that will remove from this group label
    ///   - completion: Completion
    private func updateContactGroup(objectID: String, name: String, color: String, addedEmailIDs: [String], removedEmailIDs: [String], completion: @escaping Completion) {
        let dataService = self.coreDataService
        let service = self.contactGroupService
        coreDataService.performOnRootSavingContext { context in
            guard let managedID = dataService.managedObjectIDForURIRepresentation(objectID),
                  let managedObject = try? context.existingObject(with: managedID),
                  let label = managedObject as? Label else {
                completion(NSError.badParameter("Group label objectID"))
                return
            }
            let groupID = label.labelID
            firstly {
                return service.editContactGroup(groupID: groupID, name: name, color: color)
            }.then {
                return service.addEmailsToContactGroup(groupID: LabelID(groupID),
                                                       emailList: [],
                                                       emailIDs: addedEmailIDs)
            }.then {
                return service.removeEmailsFromContactGroup(groupID: LabelID(groupID),
                                                            emailList: [],
                                                            emailIDs: removedEmailIDs)
            }.done {
                completion(nil)
            }.catch { error in
                completion(error as NSError)
            }
        }
    }

    private func deleteContactGroup(objectID: String, completion: @escaping Completion) {
        let dataService = self.coreDataService
        let service = self.contactGroupService
        coreDataService.performOnRootSavingContext { context in
            guard let managedID = dataService.managedObjectIDForURIRepresentation(objectID),
                  let managedObject = try? context.existingObject(with: managedID),
                  let label = managedObject as? Label else {
                completion(NSError.badParameter("Group label objectID"))
                return
            }
            let groupID = label.labelID
            service.deleteContactGroup(groupID: groupID).done {
                completion(nil)
            }.catch { error in
                completion(error as NSError)
            }
        }
    }
}

// MARK: queue actions for conversation
extension MainQueueHandler {
    fileprivate func unreadConversations(_ conversationIds: [String], labelID: String, completion: @escaping Completion) {
        conversationDataService
            .markAsUnread(conversationIDs: conversationIds.map{ConversationID($0)},
                          labelID: LabelID(labelID)) { result in
                completion(result.error)
        }
    }

    fileprivate func readConversations(_ conversationIds: [String], completion: @escaping Completion) {
        conversationDataService
            .markAsRead(conversationIDs: conversationIds.map{ConversationID($0)},
                        labelID: "") { result in
            completion(result.error)
        }
    }

    fileprivate func deleteConversations(_ conversationIds: [String], labelID: String, completion: @escaping Completion) {
        conversationDataService
            .deleteConversations(with: conversationIds.map{ConversationID($0)},
                                 labelID: LabelID(labelID)) { result in
            completion(result.error)
        }
    }

    fileprivate func labelConversations(_ conversationIds: [String],
                                        labelID: String,
                                        completion: @escaping Completion) {
        conversationDataService
            .label(conversationIDs: conversationIds.map{ConversationID($0)},
                   as: LabelID(labelID)) { result in
            completion(result.error)
        }
    }

    fileprivate func unlabelConversations(_ conversationIds: [String],
                                          labelID: String,
                                          completion: @escaping Completion) {
        conversationDataService
            .unlabel(conversationIDs: conversationIds.map{ConversationID($0)},
                     as: LabelID(labelID)) { result in
            completion(result.error)
        }
    }

    func unSnooze(conversationID: String, completion: @escaping Completion) {
        ConcurrencyUtils.runWithCompletion(
            block: dependencies.unSnooze.execute,
            argument: ConversationID(conversationID)
        ) { [weak self] result in
            self?.user?.eventsService.fetchEvents(labelID: Message.Location.snooze.labelID)
            completion(result.error)
        }
    }

    func snooze(conversationIDs: [String], on date: Date, completion: @escaping Completion) {
        let request = ConversationSnoozeRequest(
            conversationIDs: conversationIDs.map { ConversationID($0) },
            snoozeTime: date.timeIntervalSince1970
        )
        apiService.perform(request: request) { [weak self] _, result in
            completion(result.error)
            self?.user?.eventsService.fetchEvents(labelID: Message.Location.snooze.labelID)
        }
    }
}

// MARK: queue actions for notification actions

extension MainQueueHandler {

    func notificationAction(messageId: String, action: PushNotificationAction, completion: @escaping Completion) {
        guard let user = user else {
            return
        }
        let params = ExecuteNotificationAction.Parameters(
            apiService: user.apiService,
            action: action,
            messageId: messageId
        )
        dependencies.actionRequest.execute(params: params) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
}

// MARK: block sender

extension MainQueueHandler {
    private func blockSender(emailAddress: String, completion: @escaping Completion) {
        dependencies.incomingDefaultService.performRemoteUpdate(
            emailAddress: emailAddress,
            newLocation: .blocked,
            completion: completion
        )
    }

    private func unblockSender(emailAddress: String, completion: @escaping Completion) {
        dependencies.incomingDefaultService.performRemoteDeletion(emailAddress: emailAddress, completion: completion)
    }
}

extension MainQueueHandler {
    struct Dependencies {
        let actionRequest: ExecuteNotificationActionUseCase
        let incomingDefaultService: IncomingDefaultServiceProtocol
        let uploadDraft: UploadDraftUseCase
        let uploadAttachment: UploadAttachmentUseCase
        let messageActionUpdate: MessageActionUpdateUseCase
        let unSnooze: UnSnoozeUseCase

        init(
            actionRequest: ExecuteNotificationActionUseCase = ExecuteNotificationAction(),
            incomingDefaultService: IncomingDefaultServiceProtocol,
            uploadDraft: UploadDraftUseCase,
            uploadAttachment: UploadAttachmentUseCase,
            messageActionUpdate: MessageActionUpdateUseCase,
            unSnooze: UnSnoozeUseCase
        ) {
            self.actionRequest = actionRequest
            self.incomingDefaultService = incomingDefaultService
            self.uploadDraft = uploadDraft
            self.uploadAttachment = uploadAttachment
            self.messageActionUpdate = messageActionUpdate
            self.unSnooze = unSnooze
        }
    }
}

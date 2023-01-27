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
import Groot
import ProtonCore_Services

/// Update given message's detail
/// There are 2 common cases
/// 1. The message was fetched by mailbox list, there is no detail data locally
/// 2. Open a draft, needs to update draft data in case it is updated through other devices
typealias FetchMessageDetailUseCase = NewUseCase<FetchMessageDetail.Output, FetchMessageDetail.Params>

final class FetchMessageDetail: FetchMessageDetailUseCase {
    typealias Output = MessageEntity

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        let isMessageMissingData = params.message.body.isEmpty || !params.message.isDetailDownloaded

        if params.ignoreDownloaded || isMessageMissingData || params.message.parsedHeaders.isEmpty {
            if params.hasToBeQueued {
                dependencies.queueManager?.addBlock { [weak self] in
                    self?.fetchMessageDetail(params: params, callback: callback)
                }
            } else {
                fetchMessageDetail(params: params, callback: callback)
            }
        } else {
            handleDownloaded(entity: params.message, callback: callback)
        }
    }

    private func fetchMessageDetail(params: Params, callback: @escaping Callback) {
        dependencies
            .apiService
            .messageDetail(messageID: params.message.messageID) { [weak self] _, result in
                guard let self = self else {
                    callback(.failure(Errors.selfIsReleased))
                    return
                }

                    let response: JSONDictionary
                    switch result {
                    case .success(let value):
                        response = value
                    case .failure(let error):
                        callback(.failure(error))
                        return
                    }
                    guard let messageDict = response["Message"] as? [String: Any] else {
                        callback(.failure(NSError.badResponse()))
                        return
                    }

                    do {
                        let handledMessage = try self.handle(
                            messageDict: messageDict,
                            messageObjectID: params.message.objectID,
                            ignoreDownloaded: params.ignoreDownloaded,
                            userID: params.userID
                        )
                        callback(.success(handledMessage))
                    } catch {
                        callback(.failure(error))
                    }
                }
    }

    private func handle(
        messageDict: [String: Any],
        messageObjectID: ObjectID,
        ignoreDownloaded: Bool,
        userID: UserID
    ) throws -> MessageEntity {
        var result: Result<MessageEntity, Error>!

        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            do {
                guard let message = context.object(with: messageObjectID.rawValue) as? Message else {
                    throw Errors.coreDataObjectNotExist
                }

                if !ignoreDownloaded,
                   message.isDetailDownloaded,
                   let responseTime = messageDict["Time"] as? Int,
                   case let responseInterval = TimeInterval(responseTime),
                   let cacheTime = message.time?.timeIntervalSince1970,
                   cacheTime > responseInterval {
                    result = .success(MessageEntity(message))
                    return
                }

                let uploadingAttachments = self.uploadingAttachment(from: message)
                // This will remove all attachments that are still not uploaded to BE
                try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName,
                                                fromJSONDictionary: messageDict,
                                                in: context)
                self.restoreUploading(attachments: uploadingAttachments, to: message, context: context)

                message.isDetailDownloaded = true
                message.messageStatus = 1

                if let error = context.saveUpstreamIfNeeded() {
                    throw error
                } else {
                    result = .success(MessageEntity(message))
                }
            } catch {
                result = .failure(error)
            }
        }

        let messageEntity = try result.get()
        return try updatingUnread(message: messageEntity)
    }

    private func uploadingAttachment(from message: Message) -> [Attachment] {
        let realAttachments = dependencies.realAttachmentsFlagProvider.realAttachments
        let localAttachments = message.attachments.allObjects
            .compactMap { $0 as? Attachment }
            .filter { attach in
                if attach.isUploaded || attach.isSoftDeleted { return false }
                if realAttachments {
                    return !attach.inline()
                }
                return true
            }
        return localAttachments
    }

    private func restoreUploading(attachments: [Attachment],
                                  to message: Message,
                                  context: NSManagedObjectContext) {
        // Adds back the attachments that are still uploading
        for attachment in attachments {
            if attachment.managedObjectContext == nil {
                let objectID = attachment.objectID
                if let cache = context.object(with: objectID) as? Attachment,
                   !message.attachments.contains(cache) {
                    cache.message = message
                }
            } else {
                if !message.attachments.contains(attachment) {
                    attachment.message = message
                }
            }
        }
        let realAttachments = dependencies.realAttachmentsFlagProvider.realAttachments
        let attachmentCount = message.attachments
            .compactMap { $0 as? Attachment }
            .filter { !$0.inline() || !realAttachments }
            .count
        message.numAttachments = NSNumber(value: attachmentCount)
    }

    private func updatingUnread(message: MessageEntity) throws -> MessageEntity {
        if let labelID = message.firstValidFolder(), message.unRead {
            _ = dependencies.messageDataAction.mark(messages: [message], labelID: labelID, unRead: false)
        }

        if message.unRead {
            dependencies.cacheService.updateCounterSync(markUnRead: false, on: message.labels.map(\.labelID))
        }

        var result: Result<MessageEntity, Error>!

        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            do {
                guard let messageObject = try context.existingObject(with: message.objectID.rawValue) as? Message else {
                    throw Errors.coreDataObjectNotExist
                }

                messageObject.unRead = false

                result = .success(MessageEntity(messageObject))

                if let error = context.saveUpstreamIfNeeded() {
                    throw error
                }
            } catch {
                result = .failure(error)
            }
        }

        PushUpdater().remove(notificationIdentifiers: [message.messageID.notificationId])

        return try result.get()
    }

    private func handleDownloaded(entity: MessageEntity, callback: @escaping Callback) {
        do {
            let updated = try updatingUnread(message: entity)
            callback(.success(updated))
        } catch {
            callback(.failure(error))
        }
    }
}

extension FetchMessageDetail {
    struct Params {
        let userID: UserID
        let message: MessageEntity
        /// If true, the execution will be scheduled in the task queue
        let hasToBeQueued: Bool
        /// Respect local data or not
        /// If false, compare update time between local cache and BE to use the newer data
        let ignoreDownloaded: Bool

        init(userID: UserID,
             message: MessageEntity,
             hasToBeQueued: Bool = true,
             ignoreDownloaded: Bool = false) {
            self.userID = userID
            self.message = message
            self.hasToBeQueued = hasToBeQueued
            self.ignoreDownloaded = ignoreDownloaded
        }
    }

    struct Dependencies {
        let queueManager: QueueManagerProtocol?
        let apiService: APIService
        let contextProvider: CoreDataContextProviderProtocol
        let realAttachmentsFlagProvider: RealAttachmentsFlagProvider
        let messageDataAction: MessageDataActionProtocol
        let cacheService: CacheServiceProtocol
    }

    enum Errors: Error {
        case selfIsReleased
        case emptyResponse
        case coreDataObjectNotExist
    }
}

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
        if params.hasToBeQueued {
            dependencies.queueManager?.addBlock { [weak self] in
                self?.fetchMessageDetail(params: params, callback: callback)
            }
        } else {
            fetchMessageDetail(params: params, callback: callback)
        }
    }

    private func fetchMessageDetail(params: Params, callback: @escaping Callback) {
        dependencies
            .apiService
            .messageDetail(messageID: params.message.messageID) { [weak self] _, response, error in
                guard let self = self else {
                    callback(.failure(Errors.selfIsReleased))
                    return
                }
                let context = self.dependencies.contextProvider.rootSavingContext
                context.perform { [weak self] in
                    guard let self = self else {
                        callback(.failure(Errors.selfIsReleased))
                        return
                    }
                    guard let response = response,
                          let message = context.object(with: params.message.objectID.rawValue) as? Message else {
                        let error = NSError.unableToParseResponse(response)
                        callback(.failure(error))
                        return
                    }
                    guard let messageDict = response["Message"] as? [String: Any] else {
                        callback(.failure(NSError.badResponse()))
                        return
                    }
                    self.handle(messageDict: messageDict,
                                message: message,
                                ignoreDownloaded: params.ignoreDownloaded,
                                userID: params.userID,
                                context: context,
                                callback: callback)
                }
            }
    }

    private func handle(messageDict: [String: Any],
                        message: Message,
                        ignoreDownloaded: Bool,
                        userID: UserID,
                        context: NSManagedObjectContext,
                        callback: @escaping Callback) {
        var messageDict = messageDict
        messageDict.removeValue(forKey: "Location")
        messageDict.removeValue(forKey: "Starred")
        messageDict.removeValue(forKey: "test")
        messageDict["UserID"] = userID.rawValue
        messageDict.addAttachmentOrderField()

        if !ignoreDownloaded,
           message.isDetailDownloaded,
           let responseTime = messageDict["Time"] as? Int,
           case let responseInterval = TimeInterval(responseTime),
           let cacheTime = message.time?.timeIntervalSince1970,
           cacheTime > responseInterval {
            let msgToReturn = MessageEntity(message)
            callback(.success(msgToReturn))
            return
        }
        do {
            let localAttachments = attachment(from: message)
            // This will remove all attachments that are still not uploaded to BE
            try GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName,
                                            fromJSONDictionary: messageDict,
                                            in: context)
            restoreUploading(attachments: localAttachments,
                             to: message,
                             context: context)

            message.isDetailDownloaded = true
            message.messageStatus = 1
            updateUnread(message: message)
            if let error = context.saveUpstreamIfNeeded() {
                callback(.failure(error))
            } else {
                let msgToReturn = MessageEntity(message)
                callback(.success(msgToReturn))
            }
        } catch {
            callback(.failure(error))
        }
    }

    private func attachment(from message: Message) -> [Attachment] {
        let realAttachments = dependencies.realAttachmentsFlagProvider.realAttachments
        let localAttachments = message.attachments.allObjects
            .compactMap { $0 as? Attachment }
            .filter { attach in
                if attach.isSoftDeleted {
                    return false
                } else if realAttachments {
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
        message.numAttachments = NSNumber(value: message.attachments.count)
    }

    private func updateUnread(message: Message) {
        if let labelID = message.firstValidFolder() {
            _ = dependencies.messageDataAction.mark(messages: [MessageEntity(message)],
                                                    labelID: LabelID(labelID),
                                                    unRead: false)
        }
        if message.unRead {
            dependencies.cacheService.updateCounterSync(markUnRead: false, on: message)
        }
        message.unRead = false
        PushUpdater().remove(notificationIdentifiers: [message.notificationId])
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
    }
}

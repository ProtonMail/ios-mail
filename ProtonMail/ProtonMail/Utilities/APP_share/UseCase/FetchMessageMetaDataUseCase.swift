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

typealias FetchMessageMetaDataUseCase = UseCase<Void, FetchMessageMetaData.Parameters>

final class FetchMessageMetaData: FetchMessageMetaDataUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Parameters, callback: @escaping UseCase<Void, Parameters>.Callback) {
        if params.messageIDs.isEmpty {
            callback(.success(()))
            return
        }

        let uniqueMessageIDs = Array(Set(params.messageIDs))
        let nonEmptyMessageIDs = uniqueMessageIDs.filter { !$0.rawValue.isEmpty }
        let chunks = nonEmptyMessageIDs.chunked(into: 20)
        let group = DispatchGroup()
        self.dependencies
            .queueManager
            .addBlock { [weak self] in
                guard let self = self else {
                    callback(.success(()))
                    return
                }

                for chunk in chunks {
                    group.enter()
                    self.fetchMetaData(with: chunk) {
                        group.leave()
                    }
                }

                group.notify(queue: .global()) {
                    callback(.success(()))
                }
            }
    }
}

// MARK: Private functions

extension FetchMessageMetaData {
    private func fetchMetaData(with messageIDs: [MessageID],
                               completion: @escaping (() -> Void)) {
        self.dependencies
            .messageDataService
            .fetchMessageMetaData(messageIDs: messageIDs) { [weak self] response in
                guard let self = self,
                      response.error == nil else {
                    completion()
                    return
                }
                self.responseProcessor(messageDicts: response.messages,
                                       completion: completion)
            }
    }

    private func responseProcessor(
        messageDicts: [[String: Any]]?,
        completion: @escaping (() -> Void)
    ) {
        guard var messageDicts = messageDicts,
              !messageDicts.isEmpty else {
            completion()
            return
        }

        for index in messageDicts.indices {
            messageDicts[index]["UserID"] = dependencies.userID.rawValue
            messageDicts[index].addAttachmentOrderField()
        }

        dependencies.contextProvider.enqueueOnRootSavingContext { context in
            do {
                guard let messages = try GRTJSONSerialization.objects(
                    withEntityName: Message.Attributes.entityName,
                    fromJSONArray: messageDicts,
                    in: context
                ) as? [Message] else {
                    completion()
                    return
                }
                for message in messages {
                    message.messageStatus = 1
                }
                _ = context.saveUpstreamIfNeeded()
            } catch {}
            completion()
        }
    }
}

// MARK: Input structs

extension FetchMessageMetaData {
    struct Parameters {
        let messageIDs: [MessageID]
    }

    struct Dependencies {
        let userID: UserID
        let contextProvider: CoreDataContextProviderProtocol
        let queueManager: QueueManagerProtocol
        let messageDataService: MessageDataServiceProtocol

        init(
            userID: UserID,
            messageDataService: MessageDataServiceProtocol,
            contextProvider: CoreDataContextProviderProtocol,
            queueManager: QueueManagerProtocol
        ) {
            self.userID = userID
            self.messageDataService = messageDataService
            self.contextProvider = contextProvider
            self.queueManager = queueManager
        }
    }
}

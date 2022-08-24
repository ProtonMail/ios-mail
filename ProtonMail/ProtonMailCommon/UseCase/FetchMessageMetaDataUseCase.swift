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

protocol FetchMessageMetaDataUseCase: UseCase {
    /// Temporal solution to allow to retain and dealloc this use case
    var uuid: UUID { get }

    func execute(with messageIDs: [MessageID], callback: @escaping UseCaseResult<Void>)
}

final class FetchMessageMetaData: FetchMessageMetaDataUseCase {
    private let params: Parameters
    private let dependencies: Dependencies
    let uuid: UUID

    init(params: Parameters, dependencies: Dependencies) {
        self.params = params
        self.dependencies = dependencies
        self.uuid = UUID()
    }

    func execute(with messageIDs: [MessageID], callback: @escaping UseCaseResult<Void>) {
        if messageIDs.isEmpty {
            callback(.success(Void()))
            return
        }

        let chunks = messageIDs.chunked(into: 20)
        let group = DispatchGroup()
        self.dependencies
            .queueManager
            .addBlock { [weak self] in
                guard let self = self else {
                    callback(.success(Void()))
                    return
                }

                for chunk in chunks {
                    group.enter()
                    self.fetchMetaData(with: chunk) {
                        group.leave()
                    }
                }

                group.notify(queue: .global()) {
                    callback(.success(Void()))
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

    private func responseProcessor(messageDicts: [[String: Any]]?,
                                   completion: @escaping (() -> Void)) {
        guard var messageDicts = messageDicts,
              !messageDicts.isEmpty else {
            completion()
            return
        }
        for index in messageDicts.indices {
            messageDicts[index]["UserID"] = self.params.userID
        }
        let context = self.dependencies.contextProvider.rootSavingContext
        self.dependencies
            .contextProvider
            .enqueue(context: context) { context in
                do {
                    guard let messages = try GRTJSONSerialization.objects(
                        withEntityName: Message.Attributes.entityName,
                        fromJSONArray: messageDicts,
                        in: context) as? [Message] else {
                        completion()
                        return
                    }
                    for message in messages {
                        message.messageStatus = 1
                    }
                    _ = context.saveUpstreamIfNeeded()
                } catch { }
                completion()
            }
    }
}

// MARK: Input structs
extension FetchMessageMetaData {

    struct Parameters {
        let userID: String
    }

    struct Dependencies {
        let contextProvider: CoreDataContextProviderProtocol
        let queueManager: QueueManagerProtocol
        let messageDataService: MessageDataServiceProtocol

        init(messageDataService: MessageDataServiceProtocol,
             contextProvider: CoreDataContextProviderProtocol,
             queueManager: QueueManagerProtocol = sharedServices.get(by: QueueManager.self)) {
            self.messageDataService = messageDataService
            self.contextProvider = contextProvider
            self.queueManager = queueManager
        }
    }
}

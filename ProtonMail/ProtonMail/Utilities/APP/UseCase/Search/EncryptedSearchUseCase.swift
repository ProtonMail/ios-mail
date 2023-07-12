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

import Foundation

typealias EncryptedSearchUseCase = UseCase<[MessageEntity], EncryptedSearch.Params>

final class EncryptedSearch: EncryptedSearchUseCase {
    let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(
        params: Params,
        callback: @escaping UseCase<[MessageEntity], Params>.Callback
    ) {
        guard !params.query.isEmpty else {
            callback(.success([]))
            return
        }
        dependencies.encryptedSearchService.search(
            userID: dependencies.userID,
            query: params.query,
            page: params.page
        ) { searchResult in
            switch searchResult {
            case .success(let result):
                let messageIDs = self.collectMessageIDs(from: result)
                guard !messageIDs.isEmpty else {
                    callback(.success([]))
                    return
                }
                self.fetchMessageMetaData(of: messageIDs, completion: callback)
            case .failure(let error):
                callback(.failure(error))
            }
        }
    }

    private func collectMessageIDs(from searchResult: EncryptedSearchService.SearchResult) -> Set<String> {
        var messageIDSet: Set<String> = []
        searchResult.resultFromIndex.forEach { resultList in
            for index in 0..<resultList.length() {
                if let messageID = resultList.get(index)?.message?.id_ {
                    messageIDSet.insert(messageID)
                }
            }
        }
        searchResult.resultFromCache.forEach { resultList in
            for index in 0..<resultList.length() {
                if let messageID = resultList.get(index)?.message?.id_ {
                    messageIDSet.insert(messageID)
                }
            }
        }
        return messageIDSet
    }

    private func fetchMessageMetaData(
        of messageIDs: Set<String>,
        completion: @escaping (Result<[MessageEntity], Error>) -> Void
    ) {
        let messageIDArray = Array(messageIDs).map { MessageID($0) }
        var messageIDsNeedToBeFetch: [MessageID] = messageIDArray
        dependencies.contextProvider.performAndWaitOnRootSavingContext { context in
            let existingMessages = self.dependencies.messageDataService.fetchMessages(
                withIDs: .init(set: messageIDs),
                in: context
            )
            messageIDsNeedToBeFetch = messageIDsNeedToBeFetch.filter { msgID in
                !existingMessages.contains(where: { existMessage in
                    existMessage.messageID == msgID.rawValue
                })
            }
        }

        dependencies.fetchMessageMetaData.execute(
            params: .init(messageIDs: messageIDsNeedToBeFetch)
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                let messages: [MessageEntity] = self.dependencies.contextProvider
                    .read { context in
                        self.dependencies.messageDataService.fetchMessages(withIDs: .init(set: messageIDs), in: context)
                            .map(MessageEntity.init)
                    }
                    .sorted(by: { ($0.time ?? .distantPast) >= ($1.time ?? .distantPast) })

                completion(.success(messages))
            }
        }
    }
}

extension EncryptedSearch {
    struct Params {
        let query: String
        let page: UInt
    }

    struct Dependencies {
        let encryptedSearchService: EncryptedSearchServiceProtocol
        let contextProvider: CoreDataContextProviderProtocol
        let userID: UserID
        let fetchMessageMetaData: FetchMessageMetaDataUseCase
        let messageDataService: LocalMessageDataServiceProtocol
    }
}

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
import Groot
import ProtonCoreServices

typealias BackendSearchUseCase = UseCase<[MessageEntity], BackendSearch.Params>

/// This use case fetches the result of the search query from the user.
/// The result will be cached into the CoreData and be returned to the caller in the form of an array of `MessageEntity`.
/// The caller should maintain the page info to load further results from the BE.
final class BackendSearch: BackendSearchUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(
        params: Params,
        callback: @escaping UseCase<[MessageEntity], Params>.Callback
    ) {
        fetchSearchResult(
            query: params.query
        ) { result in
            switch result {
            case .success(let response):
                self.saveSearchResultToDB(
                    response: response
                ) { saveResult in
                    switch saveResult {
                    case .success(let messages):
                        callback(.success(messages))
                    case .failure(let error):
                        callback(.failure(error))
                    }
                }
            case .failure(let error):
                callback(.failure(error))
            }
        }
    }

    private func fetchSearchResult(
        query: SearchMessageQuery,
        completion: @escaping (Result<[String: Any]?, Error>) -> Void
    ) {
        let request = SearchMessageRequest(query: query)
        dependencies.apiService.perform(
            request: request,
            response: SearchMessageResponse()
        ) { _, response in
            if let error = response.error {
                completion(.failure(error))
            } else {
                completion(.success(response.jsonDic))
            }
        }
    }

    private func saveSearchResultToDB(
        response: [String: Any]?,
        completion: @escaping (Result<[MessageEntity], Error>) -> Void
    ) {
        guard var messagesArray = response?["Messages"] as? [[String: Any]] else {
            completion(.failure(BackendSearchError.unexpectedDataFromAPI))
            return
        }

        for index in messagesArray.indices {
            messagesArray[index]["UserID"] = dependencies.userID.rawValue
        }

        dependencies.contextProvider.performOnRootSavingContext { context in
            do {
                if let messages = try GRTJSONSerialization.objects(
                    withEntityName: Message.Attributes.entityName,
                    fromJSONArray: messagesArray,
                    in: context
                ) as? [Message] {
                    messages.forEach { $0.messageStatus = 1 }

                    if let error = context.saveUpstreamIfNeeded() {
                        completion(.failure(error))
                        return
                    } else {
                        completion(.success(messages.map(MessageEntity.init)))
                    }
                } else {
                    throw BackendSearchError.messageParsingError
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

extension BackendSearch {
    struct Params {
        let query: SearchMessageQuery
    }

    struct Dependencies {
        let apiService: APIService
        let contextProvider: CoreDataContextProviderProtocol
        let userID: UserID
    }

    enum BackendSearchError: Error {
        case messageParsingError
        case unexpectedDataFromAPI
    }
}

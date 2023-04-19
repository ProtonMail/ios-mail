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
import ProtonCore_Networking
import ProtonCore_Services

final class IndexSingleMessageDetailOperation: AsyncOperation {
    private let apiService: APIService
    private let message: ESMessage
    private let userID: UserID
    private(set) var result: Result<ESMessage, Error>?

    init(
        apiService: APIService,
        message: ESMessage,
        userID: UserID
    ) {
        self.apiService = apiService
        self.message = message
        self.userID = userID
    }

    override func main() {
        super.main()

        if message.isDetailsDownloaded ?? false {
            log(message: "indexSingleMessageDetailOperation early return, is downloaded")
            result = .success(message)
            finish()
            return
        }
        downloadMessageDetail(messageID: MessageID(message.id)) { [weak self] result in
            guard let self = self, !self.isCancelled else { return }
            switch result {
            case .failure(let error):
                self.log(
                    message: "indexSingleMessageDetailOperation \(self.message.id) failed use esMessage \(error)",
                    isError: true
                )
                self.result = .failure(error)
            case .success(let message):
                self.log(message: "indexSingleMessageDetailOperation \(self.message.id) success")
                self.result = .success(message)
            }
            self.finish()
        }
    }

    private func downloadMessageDetail(
        messageID: MessageID,
        completion: @escaping (Result<ESMessage, Swift.Error>) -> Void
    ) {
        // TODO try to use FetchMessageDetail but need to get rid of ESMessage
        // And if core data contains the message, doesn't need to call API
        let request = MessageDetailRequest(messageID: messageID, priority: .lowestPriority)
        apiService.perform(request: request, jsonDictionaryCompletion: { [weak self] _, result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let dict):
                self?.parseMessageDetail(response: dict, completion: completion)
            }
        })
    }

    private func parseMessageDetail(
        response: [String: Any],
        completion: (Result<ESMessage, Swift.Error>) -> Void
    ) {
        guard var message = response["Message"] as? [String: Any] else {
            completion(.failure(NSError.unableToParseResponse(response)))
            return
        }
        message["UserID"] = userID.rawValue
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            let message = try JSONDecoder().decode(ESMessage.self, from: jsonData)
            message.isDetailsDownloaded = true
            message.isStarred = false
            completion(.success(message))
        } catch {
            completion(.failure(error))
        }
    }
}

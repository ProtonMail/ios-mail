// Copyright (c) 2022 Proton Technologies AG
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
import class ProtonCore_DataModel.UserInfo
import protocol ProtonCore_Services.APIService
import typealias ProtonCore_Networking.JSONDictionary

typealias SendMessageUseCase = NewUseCase<Void, SendMessage.Params>

final class SendMessage: SendMessageUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        prepareSendMetadata(params: params) { [unowned self] metadataResult in
            switch metadataResult {
            case .failure(let error):
                callback(.failure(error))
            case .success(let metadata):
                self.prepareSendRequest(metadata: metadata, params: params) { requestResult in
                    switch requestResult {
                    case .failure(let error):
                        callback(.failure(error))
                    case .success(let sendRequest):
                        self.sendMessage(request: sendRequest, params: params, callback: callback)
                    }
                }
            }
        }
    }

    private func prepareSendMetadata(
        params: Params,
        completion: @escaping (Result<SendMessageMetadata, Error>) -> Void
    ) {
        dependencies.prepareSendMetadata.execute(
            params: .init(messageSendingData: params.messageSendingData),
            callback: completion
        )
    }

    private func prepareSendRequest(
        metadata: SendMessageMetadata,
        params: Params,
        completion: @escaping (Result<SendMessageRequest, Error>) -> Void
    ) {
        dependencies.prepareSendRequest.execute(
            params: .init(
                authCredential: dependencies.userDataSource.authCredential,
                sendMetadata: metadata,
                scheduleSendDeliveryTime: params.scheduleSendDeliveryTime,
                undoSendDelay: params.undoSendDelay
            ),
            callback: completion
        )
    }

    private func sendMessage(request: SendMessageRequest, params: Params, callback: @escaping Callback) {
        dependencies.apiService.perform(request: request) { [unowned self] _, sendResult in
            switch sendResult {
            case .failure(let error):
                callback(.failure(error))
            case .success(let jsonDict):
                dependencies.messageDataService.updateMessageAfterSend(
                    message: params.messageSendingData.message,
                    sendResponse: jsonDict,
                    completionQueue: executionQueue
                ) {
                    callback(.success(()))
                }
            }
        }
    }
}

extension SendMessage {
    struct Params {
        /// Information needed about the message we want to send
        let messageSendingData: MessageSendingData
        /// Time at which the message is scheduled to be sent
        let scheduleSendDeliveryTime: Date?
        /// Number of seconds the message send is delayed to be able to undo the action
        let undoSendDelay: Int
    }

    struct Dependencies {
        let prepareSendMetadata: PrepareSendMetadataUseCase
        let prepareSendRequest: PrepareSendRequestUseCase
        let apiService: APIService
        let userDataSource: UserDataSource
        let messageDataService: MessageDataServiceProtocol
    }
}

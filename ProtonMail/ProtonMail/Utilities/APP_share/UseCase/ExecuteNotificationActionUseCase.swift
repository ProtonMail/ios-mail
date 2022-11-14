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
import ProtonCore_Networking
import ProtonCore_Services

typealias ExecuteNotificationActionUseCase = NewUseCase<Void, ExecuteNotificationAction.Parameters>

final class ExecuteNotificationAction: ExecuteNotificationActionUseCase {

    override func executionBlock(params: Parameters, callback: @escaping Callback) {
        let messages = [params.messageId]
        let request: Request
        switch params.action {
        case .markAsRead:
            request = MessageActionRequest(action: "read", ids: messages)
        case .archive:
            request = ApplyLabelToMessagesRequest(labelID: Message.Location.archive.labelID, messages: messages)
        case .moveToTrash:
            request = ApplyLabelToMessagesRequest(labelID: Message.Location.trash.labelID, messages: messages)
        }
        params.apiService.perform(request: request) { _, result in
            switch result {
            case .success:
                SystemLogger.log(message: "\(params.action) success", category: .pushNotification)
                callback(.success(Void()))
            case .failure(let responseError):
                let message = "\(params.action) error: \(responseError)"
                SystemLogger.log(message: message, category: .pushNotification, isError: true)
                callback(.failure(responseError))
            }
        }
    }
}

extension ExecuteNotificationAction {
    struct Parameters {
        let apiService: APIService
        let action: PushNotificationAction
        let messageId: String
    }
}

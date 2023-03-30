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

import ProtonCore_DataModel

final class UnblockSender {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(parameters: Parameters) throws {
        let emailAddress = parameters.emailAddress

        try dependencies.incomingDefaultService.softDelete(query: .email(parameters.emailAddress))

        let task = QueueManager.Task(
            messageID: "",
            action: .unblockSender(emailAddress: emailAddress),
            userID: UserID(dependencies.userInfo.userId),
            dependencyIDs: [],
            isConversation: false
        )
        _ = dependencies.queueManager.addTask(task, autoExecute: true)
    }
}

extension UnblockSender {
    struct Dependencies {
        let incomingDefaultService: IncomingDefaultServiceProtocol
        let queueManager: QueueManagerProtocol
        let userInfo: UserInfo
    }

    struct Parameters {
        let emailAddress: String
    }
}

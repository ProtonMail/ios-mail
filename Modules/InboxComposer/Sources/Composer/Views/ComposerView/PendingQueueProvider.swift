// Copyright (c) 2024 Proton Technologies AG
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

import InboxCore
import proton_app_uniffi

struct PendingQueueProvider {
//    private let executePendingActions: () async -> MailUserSessionExecutePendingActionsResult

    init(userSession: MailUserSession) {
        // this will be reworked in https://protonag.atlassian.net/browse/ET-2226
//        self.executePendingActions = userSession.executePendingActions
    }

    func executeActionsInBackgroundTask() {
        Task {
            /// Currently `executePendingActions` in the SDK executes all pending actions sequentially. To have valuable
            /// information of what the user experience is, we log the start and end of this task.
            AppLogger.log(message: "execute pending actions start", category: .send)
//            _ = await self.executePendingActions()
            AppLogger.log(message: "execute pending actions end", category: .send)
        }
    }
}

// Copyright (c) 2025 Proton Technologies AG
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

import proton_app_uniffi

struct UndoScheduleSendProvider {
    let undoScheduleSend: (_ messageId: ID) async -> DraftCancelScheduleSendResult

    init(undoScheduleSend: @escaping (_: ID) async -> DraftCancelScheduleSendResult) {
        self.undoScheduleSend = undoScheduleSend
    }

    static func productionInstance(userSession: MailUserSession) -> UndoScheduleSendProvider {
        .init(
            undoScheduleSend: { messageId in
                await draftCancelScheduleSend(session: userSession, messageId: messageId)
            }
        )
    }

    static var mockInstance: Self {
        mockInstance()
    }

    static func mockInstance(
        stubbedResult: DraftCancelScheduleSendResult = .ok(.init(lastScheduledTime: 1_747_728_129))
    ) -> UndoScheduleSendProvider {
        .init(undoScheduleSend: { _ in stubbedResult })
    }
}

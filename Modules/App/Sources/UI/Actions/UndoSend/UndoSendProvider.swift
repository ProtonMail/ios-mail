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

struct UndoSendProvider {
    let undoSend: (_ messageId: ID) async -> DraftUndoSendError?

    init(undoSend: @escaping (_: ID) async -> DraftUndoSendError?) {
        self.undoSend = undoSend
    }

    static func productionInstance(userSession: MailUserSession) -> UndoSendProvider {
        .init(
            undoSend: { messageId in
                let result = await proton_app_uniffi.draftUndoSend(session: userSession, messageId: messageId)
                switch result {
                case .ok: return nil
                case .error(let error): return error
                }
            }
        )
    }

    static var mockInstance: Self {
        mockInstance()
    }

    static func mockInstance(stubbedResult: DraftUndoSendError? = nil) -> UndoSendProvider {
        .init(undoSend: { _ in stubbedResult })
    }
}

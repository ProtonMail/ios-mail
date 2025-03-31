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

typealias GeneralActionType = (_ session: MailUserSession, _ messageID: ID) async -> VoidActionResult

struct GeneralActionsWrappers {
    let markMessagePhishing: GeneralActionType
}

extension GeneralActionsWrappers {

    static var productionInstance: GeneralActionsWrappers {
        .init(markMessagePhishing: { session, id in .ok })
    }
    
    static var dummy: GeneralActionsWrappers {
        .init(markMessagePhishing: { _, _ in .ok })
    }

}

struct GeneralActionsPerformer {
    let markMessagePhishing: (_ messageID: ID) async -> VoidActionResult
    
    init(session: MailUserSession, generalActions: GeneralActionsWrappers) {
        self.markMessagePhishing = { messageID in await generalActions.markMessagePhishing(session, messageID) }
    }
    
    func markMessagePhishing(messageID: ID) async -> VoidActionResult {
        await markMessagePhishing(messageID)
    }
}

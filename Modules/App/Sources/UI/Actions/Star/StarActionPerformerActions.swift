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

import proton_app_uniffi

typealias StarActionClosure = (_ session: MailUserSession, _ ids: [ID]) async -> VoidActionResult

struct StarActionPerformerActions {
    let starMessage: StarActionClosure
    let starConversation: StarActionClosure

    let unstarMessage: StarActionClosure
    let unstarConversation: StarActionClosure
}

extension StarActionPerformerActions {
    static var productionInstance: StarActionPerformerActions {
        .init(
            starMessage: starMessages,
            starConversation: starConversations,
            unstarMessage: unstarMessages,
            unstarConversation: unstarConversations
        )
    }
}

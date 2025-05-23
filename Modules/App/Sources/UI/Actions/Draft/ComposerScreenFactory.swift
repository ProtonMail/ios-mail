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

import InboxComposer
import proton_app_uniffi

@MainActor
struct ComposerScreenFactory {

    @MainActor
    static func makeComposer(userSession: MailUserSession, composerParams: ComposerModalParams) -> ComposerScreen {
        let contactProvider: ComposerContactProvider = .productionInstance(session: userSession)
        let dependencies = ComposerScreen.Dependencies(contactProvider: contactProvider, userSession: userSession)
        return switch composerParams.draftToPresent {
        case .new(let draft):
            ComposerScreen(
                draft: draft,
                draftOrigin: .new,
                dependencies: dependencies,
                onSendingEvent: { event in
                    Task { try await composerParams.onSendingEvent(draft.messageId().get()!, event) }
                })
        case .openDraftId(let messageId, let lastScheduledTime):
            ComposerScreen(
                messageId: messageId,
                messageLastScheduledTime: lastScheduledTime,
                dependencies: dependencies,
                onSendingEvent: { event in
                    composerParams.onSendingEvent(messageId, event)
                })
        }
    }
}

struct ComposerModalParams {
    let draftToPresent: DraftToPresent
    let onSendingEvent: (ID, SendEvent) -> Void
}

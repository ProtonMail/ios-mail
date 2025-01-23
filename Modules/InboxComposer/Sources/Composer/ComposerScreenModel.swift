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
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

final class ComposerScreenModel: ObservableObject {
    @Published private(set) var state: State
    @Published private(set) var draftError: DraftOpenError?
    private var isCancelled: Bool = false

    init(
        messageId: ID,
        contactProvider: ComposerContactProvider,
        userSession: MailUserSession
    ) {
        self.state = .loadingDraft
        openDraftMessage(session: userSession, messageId: messageId)
    }

    init(draft: AppDraftProtocol, draftOrigin: DraftOrigin, contactProvider: ComposerContactProvider) {
        self.state = .draftLoaded(draft: draft, draftOrigin: draftOrigin)
    }

    private func openDraftMessage(session: MailUserSession, messageId: ID) {
        DispatchQueue.main.async {
            Task { [weak self] in
                guard let self else { return }
                let result = await openDraft(session: session, messageId: messageId)
                guard !isCancelled else { return }
                switch result {
                case .ok(let openDraft):
                    state = .draftLoaded(draft: openDraft.draft, draftOrigin: openDraft.syncStatus.toDraftOrigin())
                case .error(let draftError):
                    self.draftError = draftError
                }
            }
        }
    }

    @MainActor
    func cancel() {
        isCancelled = true
    }

    enum State {
        case loadingDraft
        case draftLoaded(draft: AppDraftProtocol, draftOrigin: DraftOrigin)
    }
}

private extension DraftSyncStatus {

    func toDraftOrigin() -> DraftOrigin {
        switch self {
        case .cached:
            .cache
        case .synced:
            .server
        }
    }
}

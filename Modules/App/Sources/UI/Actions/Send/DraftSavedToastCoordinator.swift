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

import Foundation
import InboxCore
import InboxCoreUI
import proton_app_uniffi

@MainActor
struct DraftSavedToastCoordinator {
    private let mailUSerSession: MailUserSession
    private let toastStoreState: ToastStateStore

    init(mailUSerSession: MailUserSession, toastStoreState: ToastStateStore) {
        self.mailUSerSession = mailUSerSession
        self.toastStoreState = toastStoreState
    }

    func showDraftSavedToast(draftId: ID) {
        toastStoreState.present(toast: .draftSaved(messageId: draftId, undoAction: discardDraft(draftId:)))
    }

    private func discardDraft(draftId: ID) async {
        toastStoreState.dismiss(toast: .draftSaved(messageId: draftId, undoAction: discardDraft(draftId:)))
        switch await draftDiscard(session: mailUSerSession, messageId: draftId) {
        case .ok:
            toastStoreState.present(toast: .draftDiscarded())
        case .error(let error):
            toastStoreState.present(toast: .error(message: error.localizedDescription))
        }
    }
}

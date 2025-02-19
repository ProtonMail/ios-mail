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

struct DraftSavedToastCoordinator {
    private let mailUSerSession: MailUserSession
    private let toastStoreState: ToastStateStore

    init(mailUSerSession: MailUserSession, toastStoreState: ToastStateStore) {
        self.mailUSerSession = mailUSerSession
        self.toastStoreState = toastStoreState
    }

    func showDraftSavedToast(draftId: ID) {
        DispatchQueue.main.async {
            toastStoreState.present(toast: discardDraftToast(draftId: draftId))
        }
    }

    private func discardDraftToast(draftId: ID) -> Toast {
        let discardButton = Toast.Button(
            type: .smallTrailing(content: .title(L10n.Composer.discard.string)),
            action: { self.discardDraft(draftId: draftId) }
        )
        return Toast(
            title: nil,
            message: L10n.Composer.draftSaved.string,
            button: discardButton,
            style: .information,
            duration: .toastDefaultDuration
        )
    }

    private func discardDraft(draftId: ID) {
        DispatchQueue.main.async {
            toastStoreState.dismiss(toast: discardDraftToast(draftId: draftId))
        }
        Task {
            let result = await draftDiscard(session: mailUSerSession, messageId: draftId)
            DispatchQueue.main.async {
                switch result {
                case .ok:
                    toastStoreState.present(toast: .information(message: L10n.Composer.discarded.string))
                case .error(let error):
                    toastStoreState.present(toast: .error(message: error.localizedDescription))
                }
            }
        }
    }
}

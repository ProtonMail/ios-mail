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

import InboxCoreUI

struct DraftSavedToastCoordinator {
    private let toastStoreState: ToastStateStore

    init(toastStoreState: ToastStateStore) {
        self.toastStoreState = toastStoreState
    }

    func showDraftSavedToast(draft: AppDraftProtocol) {
        let discardButton = Toast.Button(
            type: .smallTrailing(content: .title(L10n.Composer.discard.string)),
            action: { self.discardDraft(draft: draft) }
        )
        let toast = Toast(
            title: nil,
            message: L10n.Composer.draftSaved.string,
            button: discardButton,
            style: .information,
            duration: .toastDefaultDuration
        )
        toastStoreState.present(toast: toast)
    }

    private func discardDraft(draft: AppDraftProtocol) {
        Task {
            switch await draft.discard() {
            case .ok:
                toastStoreState.present(toast: .information(message: L10n.Composer.discarded.string))
            case .error(let error):
                toastStoreState.present(toast: .error(message: error.localizedDescription))
            }
        }
    }
}

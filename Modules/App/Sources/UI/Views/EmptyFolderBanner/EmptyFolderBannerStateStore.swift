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

import InboxCore
import InboxCoreUI
import InboxDesignSystem
import InboxIAP
import proton_app_uniffi
import SwiftUI

final class EmptyFolderBannerStateStore: StateStore {
    enum Action {
        case upgradeToAutoDelete
        case emptyFolder
        case deleteConfirmed(DeleteConfirmationAlertAction)
    }

    struct State: Equatable, Copying {
        let icon: ImageResource
        let title: String
        let buttons: [EmptyFolderBanner.ActionButton]
        var alert: AlertModel?
        var presentedUpsell: UpsellScreenModel?
    }

    let model: EmptyFolderBanner
    @Published var state: State
    private let toastStateStore: ToastStateStore
    private let messagesDeleter: AllMessagesDeleter
    private let upsellScreenPresenter: UpsellScreenPresenter

    init(
        model: EmptyFolderBanner,
        toastStateStore: ToastStateStore,
        mailUserSession: MailUserSession,
        wrapper: RustEmptyFolderBannerWrapper,
        upsellScreenPresenter: UpsellScreenPresenter
    ) {
        self.model = model
        self.state = model.state
        self.toastStateStore = toastStateStore
        self.messagesDeleter = .init(mailUserSession: mailUserSession, wrapper: wrapper)
        self.upsellScreenPresenter = upsellScreenPresenter
    }

    // MARK: - StateStore

    func handle(action: Action) async {
        switch action {
        case .upgradeToAutoDelete:
            do {
                let presentedUpsell = try await upsellScreenPresenter.presentUpsellScreen(entryPoint: .autoDelete)
                state = state.copy(\.presentedUpsell, to: presentedUpsell)
            } catch {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        case .emptyFolder:
            let alert: AlertModel = .emptyFolderConfirmation(
                folder: model.folder.type,
                action: { [weak self] action in await self?.handle(action: .deleteConfirmed(action)) }
            )

            state = state.copy(\.alert, to: alert)
        case .deleteConfirmed(let action):
            state = state.copy(\.alert, to: nil)

            if case .delete = action {
                await messagesDeleter.deleteAll(labelID: model.folder.labelID)
            }
        }
    }
}

private extension EmptyFolderBanner {

    var state: EmptyFolderBannerStateStore.State {
        switch userState {
        case .autoDeleteUpsell:
            .init(
                icon: DS.Icon.icTrashClock,
                title: L10n.EmptyFolderBanner.freeUserTitle.string,
                buttons: [.upgradePlan, .emptyLocation],
                alert: .none
            )
        case .autoDeleteEnabled:
            .paidNoAlert(icon: DS.Icon.icTrashClock, title: L10n.EmptyFolderBanner.paidUserAutoDeleteOnTitle)
        case .autoDeleteDisabled:
            .paidNoAlert(icon: DS.Icon.icTrash, title: L10n.EmptyFolderBanner.paidUserAutoDeleteOffTitle)
        }
    }

}

private extension EmptyFolderBannerStateStore.State {

    static func paidNoAlert(icon: ImageResource, title: LocalizedStringResource) -> Self {
        .init(icon: icon, title: title.string, buttons: [.emptyLocation], alert: .none)
    }

}

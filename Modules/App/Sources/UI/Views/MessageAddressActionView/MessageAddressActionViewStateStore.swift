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
import proton_app_uniffi
import SwiftUI

final class MessageAddressActionViewStateStore: StateStore {
    enum Action {
        case onTap(MessageAddressAction)
        case onBlockAlertAction(BlockAddressAlertAction)
    }

    struct State: Copying, Equatable {
        let avatar: AvatarUIModel
        let name: String
        let email: String
        let phoneNumber: String?
        /// Non-nil when the "Block this address" alert should be presented.
        var emailToBlock: String?
    }

    @Published var state: State

    private let session: MailUserSession
    private let toastStateStore: ToastStateStore
    private let clipboard: Clipboard
    private let openURL: URLOpenerProtocol
    private let blockAddress: (_ userSession: MailUserSession, _ emailAddress: String) async -> VoidActionResult
    private let draftPresenter: RecipientDraftPresenter
    private let dismiss: Dismissable

    init(
        avatar: AvatarUIModel,
        name: String,
        email: String,
        phoneNumber: String?,
        session: MailUserSession,
        toastStateStore: ToastStateStore,
        pasteboard: UIPasteboard,
        openURL: URLOpenerProtocol,
        blockAddress: @escaping (_ userSession: MailUserSession, _ emailAddress: String) async -> VoidActionResult,
        draftPresenter: RecipientDraftPresenter,
        dismiss: Dismissable
    ) {
        self.state = .init(avatar: avatar, name: name, email: email, phoneNumber: phoneNumber, emailToBlock: .none)
        self.session = session
        self.toastStateStore = toastStateStore
        self.clipboard = .init(toastStateStore: toastStateStore, pasteboard: pasteboard)
        self.openURL = openURL
        self.blockAddress = blockAddress
        self.draftPresenter = draftPresenter
        self.dismiss = dismiss
    }

    // MARK: - Public

    @MainActor
    func handle(action: Action) async {
        switch action {
        case .onTap(let tapAction):
            await handleTap(action: tapAction)
        case .onBlockAlertAction(let alertAction):
            await handleAlert(action: alertAction)
        }
    }

    // MARK: - Private

    @MainActor
    private func handleTap(action: MessageAddressAction) async {
        switch action {
        case .newMessage:
            do {
                dismiss()
                try await draftPresenter.openDraft(with: .init(name: state.name, email: state.email))
            } catch {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        case .call:
            if let number = state.phoneNumber, let url = URL(string: "tel:\(number)") {
                openURL(url)
            }
        case .copyAddress:
            clipboard.copyToClipboard(value: state.email, forName: L10n.Action.Clipboard.emailAddress)
        case .copyName:
            clipboard.copyToClipboard(value: state.name, forName: L10n.Action.Clipboard.name)
        case .addToContacts:
            toastStateStore.present(toast: .comingSoon)
        case .blockContact:
            state = state.copy(\.emailToBlock, to: state.email)
        }
    }

    @MainActor
    private func handleAlert(action: BlockAddressAlertAction) async {
        switch action {
        case .cancel:
            state = state.copy(\.emailToBlock, to: nil)
        case .confirm:
            if let emailToBlock = state.emailToBlock {
                state = state.copy(\.emailToBlock, to: nil)

                switch await blockAddress(session, emailToBlock) {
                case .ok:
                    toastStateStore.present(toast: .information(message: L10n.BlockAddress.Toast.success.string))
                case .error:
                    toastStateStore.present(toast: .error(message: L10n.BlockAddress.Toast.failure.string))
                }
            }
        }
    }
}

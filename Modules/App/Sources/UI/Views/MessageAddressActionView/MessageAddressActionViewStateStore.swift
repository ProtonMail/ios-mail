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
        /// Non-nil when the "Block this address" alert should be presented.
        var emailToBlock: String?
    }

    @Published var state: State

    private let session: MailUserSession
    private let toastStateStore: ToastStateStore
    private let blockAddress: (MailUserSession, String) async -> VoidActionResult

    init(
        avatar: AvatarUIModel,
        name: String,
        email: String,
        session: MailUserSession,
        toastStateStore: ToastStateStore,
        blockAddress: @escaping (MailUserSession, String) async -> VoidActionResult = blockAddress(session:email:)
    ) {
        self.state = .init(
            avatar: avatar,
            name: name,
            email: email,
            emailToBlock: nil
        )
        self.session = session
        self.toastStateStore = toastStateStore
        self.blockAddress = blockAddress
    }

    // MARK: - Public

    @MainActor
    func handle(action: Action) async {
        switch action {
        case .onTap(let tapAction):
            handleTap(action: tapAction)
        case .onBlockAlertAction(let alertAction):
            await handleAlert(action: alertAction)
        }
    }

    // MARK: - Private

    @MainActor
    private func handleTap(action: MessageAddressAction) {
        switch action {
        case .newMessage, .call, .addToContacts, .copyAddress, .copyName:
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

                await block(email: emailToBlock)
            }
        }
    }

    @MainActor
    private func block(email: String) async {
        let result = await blockAddress(session, email)
        switch result {
        case .ok:
            toastStateStore.present(toast: .information(message: "Sender blocked"))
        case .error:
            toastStateStore.present(toast: .error(message: "Could not block sender"))
        }
    }
}

import InboxCore
import InboxCoreUI

enum BlockAddressAlertAction: AlertActionInfo, CaseIterable {
    case cancel
    case confirm

    var info: (title: LocalizedStringResource, buttonRole: ButtonRole?) {
        switch self {
        case .cancel:
            (CommonL10n.cancel, .cancel)
        case .confirm:
            ("Block".stringResource, .destructive)
        }
    }
}

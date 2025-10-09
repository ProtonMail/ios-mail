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
        case onLoad
        case onTap(MessageAddressAction)
        case onBlockAlertAction(BlockAddressAlertAction)
    }

    struct State: Copying, Equatable {
        var avatar: AvatarUIModel
        let name: String
        let email: String
        let phoneNumber: String?
        /// Non-nil when the "Block this address" alert should be presented.
        var emailToBlock: String?
    }

    @Published var state: State

    private let messageID: Id
    private let mailbox: Mailbox
    private let session: MailUserSession
    private let toastStateStore: ToastStateStore
    private let clipboard: Clipboard
    private let openURL: URLOpenerProtocol
    private let wrapper: RustMessageAddressWrapper
    private let draftPresenter: RecipientDraftPresenter
    private let dismiss: Dismissable
    private let messageBannersNotifier: RefreshMessageBannersNotifier

    init(
        messageID: Id,
        avatar: AvatarUIModel,
        name: String,
        email: String,
        phoneNumber: String?,
        mailbox: Mailbox,
        session: MailUserSession,
        toastStateStore: ToastStateStore,
        pasteboard: UIPasteboard,
        openURL: URLOpenerProtocol,
        wrapper: RustMessageAddressWrapper,
        draftPresenter: RecipientDraftPresenter,
        dismiss: Dismissable,
        messageBannersNotifier: RefreshMessageBannersNotifier
    ) {
        self.messageID = messageID
        self.state = .init(avatar: avatar, name: name, email: email, phoneNumber: phoneNumber, emailToBlock: .none)
        self.mailbox = mailbox
        self.session = session
        self.toastStateStore = toastStateStore
        self.clipboard = .init(toastStateStore: toastStateStore, pasteboard: pasteboard)
        self.openURL = openURL
        self.wrapper = wrapper
        self.draftPresenter = draftPresenter
        self.dismiss = dismiss
        self.messageBannersNotifier = messageBannersNotifier
    }

    // MARK: - Public

    func handle(action: Action) async {
        switch action {
        case .onLoad:
            if case .sender(let senderInfo) = state.avatar.type {
                let isBlocked = await wrapper.isSenderBlocked(mailbox, messageID)
                let blocked: SenderInfo.Blocked = isBlocked ? .yes : .no
                let updatedSenderInfo = senderInfo.copy(\.blocked, to: blocked)
                let updatedAvatar = state.avatar.copy(\.type, to: .sender(updatedSenderInfo))

                state = state.copy(\.avatar, to: updatedAvatar)
            }
        case .onTap(let tapAction):
            await handleTap(action: tapAction)
        case .onBlockAlertAction(let alertAction):
            await handleAlert(action: alertAction)
        }
    }

    // MARK: - Private

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
            if let number = state.phoneNumber, let url = URL(phoneNumber: number) {
                openURL(url)
            }
        case .copyAddress:
            clipboard.copyToClipboard(value: state.email, forName: CommonL10n.Clipboard.emailAddress)
        case .copyName:
            clipboard.copyToClipboard(value: state.name, forName: CommonL10n.Clipboard.name)
        case .addToContacts:
            toastStateStore.present(toast: .comingSoon)
        case .blockContact:
            state = state.copy(\.emailToBlock, to: state.email)
        }
    }

    private func handleAlert(action: BlockAddressAlertAction) async {
        switch action {
        case .cancel:
            state = state.copy(\.emailToBlock, to: nil)
        case .confirm:
            if let emailToBlock = state.emailToBlock {
                state = state.copy(\.emailToBlock, to: nil)

                switch await wrapper.block(session, emailToBlock) {
                case .ok:
                    dismiss()
                    messageBannersNotifier.refresh()
                    toastStateStore.present(toast: .information(message: L10n.BlockAddress.Toast.success.string))
                case .error:
                    toastStateStore.present(toast: .error(message: L10n.BlockAddress.Toast.failure.string))
                }
            }
        }
    }
}

struct RustMessageAddressWrapper {
    let block: @Sendable (_ userSession: MailUserSession, _ emailAddress: String) async -> VoidActionResult
    let isSenderBlocked: @Sendable (_ mailbox: Mailbox, _ messageID: Id) async -> Bool

    init(
        block: @escaping @Sendable (MailUserSession, String) async -> VoidActionResult,
        isSenderBlocked: @escaping @Sendable (Mailbox, Id) async -> Bool
    ) {
        self.block = block
        self.isSenderBlocked = isSenderBlocked
    }
}

extension RustMessageAddressWrapper {

    static func productionInstance() -> Self {
        .init(
            block: { session, email in await blockAddress(session: session, email: email) },
            isSenderBlocked: { mailbox, id in
                guard let isBlocked = try? await isMessageSenderBlocked(mbox: mailbox, messageId: id).get() else {
                    return true
                }

                return isBlocked
            }
        )
    }

}

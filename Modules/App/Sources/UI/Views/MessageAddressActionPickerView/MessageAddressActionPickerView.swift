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

import InboxDesignSystem
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

struct MessageAddressActionPickerView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    let avatarUIModel: AvatarUIModel
    let name: String
    let emailAddress: String
    let mailUserSession: MailUserSession

    var body: some View {
        StoreView(
            store: MessageAddressActionPickerStateStore(
                avatar: avatarUIModel,
                name: name,
                email: emailAddress,
                session: mailUserSession,
                toastStateStore: toastStateStore
            ),
            content: { state, store in
                ActionPickerList(
                    headerContent: {
                        headerView(
                            avatar: state.avatar,
                            name: state.name,
                            email: state.email
                        )
                        .listRowBackground(Color.clear)
                    },
                    sections: sections(avatar: state.avatar),
                    onElementTap: { action in store.handle(action: .onTap(action)) }
                )
                .alert(model: blockConfirmationAlert(state: state, store: store))
            }
        )
    }

    @ViewBuilder
    private func headerView(
        avatar: AvatarUIModel,
        name: String,
        email: String
    ) -> some View {
        VStack(alignment: .center) {
            AvatarView(avatar: avatar)
                .clipShape(Circle())
                .square(size: 70)
            Text(verbatim: name)
                .font(.subheadline)
                .bold()
                .foregroundStyle(DS.Color.Text.norm)
                .accessibilityIdentifier(MessageAddressActionPickerViewIdentifiers.participantName)
            Text(verbatim: email)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
                .accessibilityIdentifier(MessageAddressActionPickerViewIdentifiers.participantAddress)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, DS.Spacing.medium)
    }

    private func sections(avatar: AvatarUIModel) -> [[MessageAddressAction]] {
        [
            [.newMessage, .addToContacts],
            [.copyAddress, .copyName],
            avatar.type.isSender ? [.blockContact] : [],
        ]
    }

    private func blockConfirmationAlert(
        state: MessageAddressActionPickerStateStore.State,
        store: MessageAddressActionPickerStateStore
    ) -> Binding<AlertModel?> {
        .readonly {
            state.emailToBlock.map { emailToBlock in
                AlertModel.blockSender(
                    for: emailToBlock,
                    action: { action in await store.handle(action: .onBlockAlertAction(action)) }
                )
            }
        }
    }
}

#Preview {
    HStack {
        MessageAddressActionPickerView(
            avatarUIModel: .init(
                info: .init(initials: "Aa", color: .purple),
                type: .sender(params: .init())
            ),
            name: "Aaron",
            emailAddress: "aaron@proton.me",
            mailUserSession: .dummy
        )
    }
}

struct MessageAddressActionPickerViewIdentifiers {
    static let participantName = "actionPicker.participant.name"
    static let participantAddress = "actionPicker.participant.address"
}

private extension AlertModel {
    static func blockSender(
        for email: String,
        action: @escaping @MainActor @Sendable (BlockAddressAlertAction) async -> Void
    ) -> AlertModel {
        let actions: [AlertAction] = BlockAddressAlertAction.allCases.map { actionType in
            .init(details: actionType, action: { await action(actionType) })
        }

        return AlertModel(
            title: "Block this address".notLocalized.stringResource,
            message: "Emails from \(email) will no longer be delivered and will be permanently deleted. You can manage blocked email addresses in the settings.".notLocalized.stringResource,
            actions: actions
        )
    }
}

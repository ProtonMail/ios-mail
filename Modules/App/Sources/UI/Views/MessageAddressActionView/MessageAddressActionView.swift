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
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

struct MessageAddressActionView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    @Environment(\.openURL) var openURL
    @Environment(\.pasteboard) var pasteboard
    @Environment(\.dismissTestable) var dismiss
    let avatarUIModel: AvatarUIModel
    let name: String
    let emailAddress: String
    let mailUserSession: MailUserSession
    let draftPresenter: RecipientDraftPresenter

    var body: some View {
        StoreView(
            store: MessageAddressActionViewStateStore(
                avatar: avatarUIModel,
                name: name,
                email: emailAddress,
                phoneNumber: .none,
                session: mailUserSession,
                toastStateStore: toastStateStore,
                pasteboard: pasteboard,
                openURL: openURL,
                blockAddress: blockAddress(session:email:),
                draftPresenter: draftPresenter,
                dismiss: dismiss
            ),
            content: { state, store in
                ActionPickerList(
                    headerContent: {
                        headerView(state: state)
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
    private func headerView(state: MessageAddressActionViewStateStore.State) -> some View {
        VStack(alignment: .center) {
            AvatarView(avatar: state.avatar)
                .clipShape(Circle())
                .square(size: 70)
            Text(verbatim: state.name)
                .font(.subheadline)
                .bold()
                .foregroundStyle(DS.Color.Text.norm)
                .accessibilityIdentifier(MessageAddressActionPickerViewIdentifiers.participantName)
            Text(verbatim: state.email)
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
        ]
    }

    private func blockConfirmationAlert(
        state: MessageAddressActionViewStateStore.State,
        store: MessageAddressActionViewStateStore
    ) -> Binding<AlertModel?> {
        .readonly {
            state.emailToBlock.map { emailToBlock in
                AlertModel.blockSender(
                    email: emailToBlock,
                    action: { action in await store.handle(action: .onBlockAlertAction(action)) }
                )
            }
        }
    }
}

#Preview {
    HStack {
        MessageAddressActionView(
            avatarUIModel: .init(
                info: .init(initials: "Aa", color: .purple),
                type: .sender(params: .init())
            ),
            name: "Aaron",
            emailAddress: "aaron@proton.me",
            mailUserSession: .dummy,
            draftPresenter: DraftPresenter(
                userSession: .dummy,
                draftProvider: .dummy,
                undoSendProvider: .mockInstance,
                undoScheduleSendProvider: .mockInstance
            )
        )
    }
}

struct MessageAddressActionPickerViewIdentifiers {
    static let participantName = "actionPicker.participant.name"
    static let participantAddress = "actionPicker.participant.address"
}

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
import SwiftUI

struct MessageAddressActionPickerView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    let avatarUIModel: AvatarUIModel
    let name: String
    let emailAddress: String

    var body: some View {
        StoreView(
            store: MessageAddressActionPickerStateStore(
                avatar: avatarUIModel,
                name: name,
                email: emailAddress,
                session: .dummy,
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
                    sections: [
                        MessageAddressActionPickerSection.first.actions(),
                        MessageAddressActionPickerSection.second.actions(),
                        MessageAddressActionPickerSection.third(state.avatar).actions(),
                    ],
                    onElementTap: {
                        toastStateStore.present(toast: .comingSoon)
                        print($0)
                    }
                )
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
}

private enum MessageAddressActionPickerSection {
    case first
    case second
    case third(AvatarUIModel)

    func actions() -> [MessageAddressAction] {
        switch self {
        case .first:
            [.newMessage, .addToContacts]
        case .second:
            [.copyAddress, .copyName]
        case .third(let avatarUIModel):
            avatarUIModel.type.isSender ? [.blockContact] : []
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
            emailAddress: "aaron@proton.me"
        )
    }
}

struct MessageAddressActionPickerViewIdentifiers {
    static let participantName = "actionPicker.participant.name"
    static let participantAddress = "actionPicker.participant.address"
}

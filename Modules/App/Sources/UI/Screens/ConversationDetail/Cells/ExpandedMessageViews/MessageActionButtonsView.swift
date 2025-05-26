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
import InboxDesignSystem
import SwiftUI
import enum proton_app_uniffi.ReplyAction

struct MessageActionButtonsView: View {
    let isSingleRecipient: Bool
    var onEvent: (ReplyAction) -> Void

    var body: some View {
        HStack() {
            MessageActionButtonView(imageSystemName: DS.SFSymbols.reply, text: L10n.Action.Send.reply) { onEvent(.reply) }
            MessageActionButtonView(imageSystemName: DS.SFSymbols.replyAll, text: L10n.Action.Send.replyAll) { onEvent(.replyAll) }
                .removeViewIf(isSingleRecipient)
            MessageActionButtonView(imageSystemName: DS.SFSymbols.forward, text: L10n.Action.Send.forward) { onEvent(.forward) }
        }
        .padding(.horizontal, DS.Spacing.large)
    }
}

private struct MessageActionButtonView: View {
    let imageSystemName: String
    let text: LocalizedStringResource
    var onButtonTap: () -> Void

    var body: some View {
        Button(action: onButtonTap) {
            HStack(spacing: DS.Spacing.medium) {
                Image(systemName: imageSystemName)
                    .foregroundColor(DS.Color.Icon.norm)
                    .aspectRatio(contentMode: .fill)
                    .square(size: 20)
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .tint(DS.Color.Text.norm)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(12.0)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    Capsule()
                        .fill(DS.Color.InteractionWeak.norm)
                }
            )
        }
    }
}

#Preview {
    MessageActionButtonsView(isSingleRecipient: false, onEvent: { _ in })
}

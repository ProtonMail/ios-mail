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

import DesignSystem
import SwiftUI

struct MessageActionButtonsView: View {
    let isSingleRecipient: Bool

    var body: some View {
        HStack() {
            MessageActionButtonView(
                image: DS.Icon.icReplay,
                text: LocalizationTemp.MessageAction.reply
            )
            MessageActionButtonView(
                image: DS.Icon.icReplayAll,
                text: LocalizationTemp.MessageAction.replyAll
            )
            .removeViewIf(isSingleRecipient)
            MessageActionButtonView(
                image: DS.Icon.icForward,
                text: LocalizationTemp.MessageAction.forward
            )
        }
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, DS.Spacing.large)
    }
}

private struct MessageActionButtonView: View {
    let image: UIImage
    let text: String

    var body: some View {
        Button(action: {

        }) {
            HStack(spacing: DS.Spacing.medium) {
                Image(uiImage: image)
                    .resizable()
                    .foregroundColor(DS.Color.Icon.norm)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 16, height: 16)
                Text(text)
                    .fontBody3()
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
                        .fill(DS.Color.Background.norm)
                        .strokeBorder(DS.Color.Border.strong, lineWidth: 1)
                }
            )
        }
    }
}

#Preview {
    MessageActionButtonsView(isSingleRecipient: false)
}

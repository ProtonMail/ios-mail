// Copyright (c) 2026 Proton Technologies AG
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
import SwiftUI

struct RegularUnreadButton: View {
    private let state: UnreadButtonState
    private let action: () -> Void

    init(state: UnreadButtonState, action: @escaping () -> Void) {
        self.state = state
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.compact) {
                HStack(spacing: DS.Spacing.small) {
                    Text(L10n.Mailbox.unread)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(state.counterState.string)
                        .fontWeight(.semibold)
                }
                if state.isSelected {
                    Image(symbol: .xmark)
                        .fontWeight(.heavy)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(BorderedButtonStyle(isSelected: state.isSelected))
    }
}

struct BorderedButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(.all, DS.Spacing.moderatelyLarge)
            .foregroundStyle(isSelected ? DS.Color.Text.inverted : DS.Color.Text.norm)
            .background(isSelected ? DS.Color.InteractionBrand.pressed : DS.Color.InteractionFab.norm)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(DS.Color.Border.light, lineWidth: 1)
            )
            .clipShape(Capsule(style: .continuous))
            .shadow(DS.Shadows.liftedFull, isVisible: true)
    }
}

#Preview {
    @Previewable @State var isSelected = false

    VStack {
        Spacer()

        RegularUnreadButton(
            state: .init(
                isSelected: isSelected,
                counterState: .known(unreadCount: 100))
        ) {
            isSelected.toggle()
        }
    }
}

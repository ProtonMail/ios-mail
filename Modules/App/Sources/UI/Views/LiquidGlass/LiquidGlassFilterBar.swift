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
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

@available(iOS 26, *)
struct LiquidGlassFilterBar: View {
    @Binding var state: FilterBarState
    let onSelectAllTapped: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer {
                HStack {
                    switch state.visibilityMode {
                    case .regular:
                        unreadButton()

                        if case .visible(let isSelected) = state.spamTrashToggleState {
                            spamTrashToggle(isSelected: isSelected)
                        }
                    case .selectionMode:
                        selectAllButton()
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
                .padding(.vertical, DS.Spacing.standard)
            }
            .animation(.default, value: state.visibilityMode)
            .animation(.default, value: state.spamTrashToggleState.isSelected)
            .animation(.default, value: state.isUnreadButtonSelected)
        }
        .scrollClipDisabled()
    }

    private func selectAllButton() -> some View {
        Button(action: onSelectAllTapped) {
            HStack {
                Image(symbol: state.selectAll.button.icon)
                Text(state.selectAll.button.text)
            }
            .font(.footnote)
        }
        .tint(DS.Color.Icon.norm)
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, DS.Spacing.medium)
        .glassEffect(.regular.interactive())
    }

    private func spamTrashToggle(isSelected: Bool) -> some View {
        filterToggleButton(
            isSelected: isSelected,
            action: {
                state.spamTrashToggleState = state.spamTrashToggleState.toggled()
            }
        ) {
            Text(L10n.Mailbox.includeTrashSpamToggleTitle)
        }
    }

    private func unreadButton() -> some View {
        filterToggleButton(
            isSelected: state.isUnreadButtonSelected,
            action: {
                state.isUnreadButtonSelected.toggle()
            }
        ) {
            Text(L10n.Mailbox.unread)
            Text(state.unreadCount.string)
                .fontWeight(.semibold)
        }
    }

    private func filterToggleButton(
        isSelected: Bool,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> some View
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.small) {
                label()
                if isSelected {
                    Image(symbol: .xmark)
                }
            }
            .font(.footnote)
            .padding(.vertical, DS.Spacing.standard)
            .padding(.horizontal, DS.Spacing.medium)
        }
        .tint(isSelected ? DS.Color.Brand.plus30 : DS.Color.Text.norm)
        .glassEffect(.regular.interactive().tint(isSelected ? DS.Color.InteractionBrandWeak.norm : nil))
    }
}

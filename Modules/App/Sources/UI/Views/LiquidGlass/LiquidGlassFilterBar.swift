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

struct MailboxFilterBarState: Equatable {
    enum Mode: Equatable {
        case regular
        case selection
    }

    var mode: Mode
    var isUnreadSelected: Bool
    var unreadCount: UnreadCounterState
    var spamTrashToggleState: SpamTrashToggleState
    var selectAll: SelectAllState
}

enum LiquidGlassFilterBarEvent {
    case unreadButtonTapped
    case spamTrashToggleTapped
    case selectAllTapped
}

@available(iOS 26, *)
struct LiquidGlassFilterBar: View {
    enum Variant: Equatable {
        case mailbox(MailboxFilterBarState)
        case search(SpamTrashToggleState)
    }

    let content: Variant
    let onEvent: (LiquidGlassFilterBarEvent) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer {
                HStack {
                    switch content {
                    case .mailbox(let state):
                        switch state.mode {
                        case .regular:
                            unreadButton(state: state)

                            if case .visible(let isSelected) = state.spamTrashToggleState {
                                spamTrashToggle(isSelected: isSelected)
                            }
                        case .selection:
                            selectAllButton(state: state)
                        }
                    case .search(let state):
                        if case .visible(let isSelected) = state {
                            spamTrashToggle(isSelected: isSelected)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.large)
                .padding(.vertical, DS.Spacing.standard)
            }
            .animation(.default, value: content)
        }
        .scrollClipDisabled()
    }

    private func selectAllButton(state: MailboxFilterBarState) -> some View {
        Button(action: { onEvent(.selectAllTapped) }) {
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
            action: { onEvent(.spamTrashToggleTapped) }
        ) {
            Text(L10n.Mailbox.includeTrashSpamToggleTitle)
        }
    }

    private func unreadButton(state: MailboxFilterBarState) -> some View {
        filterToggleButton(
            isSelected: state.isUnreadSelected,
            action: { onEvent(.unreadButtonTapped) }
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

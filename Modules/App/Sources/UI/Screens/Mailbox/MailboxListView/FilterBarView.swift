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

import proton_app_uniffi
import InboxDesignSystem
import SwiftUI

struct FilterBarView: View {
    @ScaledMetric var scale: CGFloat = 1

    @Binding var state: FilterBarState

    let onSelectAllTapped: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                switch state.visibilityMode {
                case .regular:
                    HStack {
                        unreadButton()

                        if case .visible(let isSelected) = state.spamTrashToggleState {
                            spamTrashToggle(isSelected: isSelected)
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: state)
                case .selectionMode:
                    selectAllButton()
                }
            }
        }
        .scrollClipDisabled()
        .padding(.horizontal, DS.Spacing.large)
        .padding(.vertical, DS.Spacing.standard)
        .background(DS.Color.Background.norm)
        .accessibilityIdentifier(UnreadFilterIdentifiers.rootElement)
    }

    private func spamTrashToggle(isSelected: Bool) -> some View {
        SelectableCapsuleButton(isSelected: isSelected) {
            state.spamTrashToggleState = state.spamTrashToggleState.toggled()
        } label: {
            Text(L10n.Mailbox.includeTrashSpamToggleTitle)
        }
    }

    private func unreadButton() -> some View {
        SelectableCapsuleButton(isSelected: state.isUnreadButtonSelected) {
            state.isUnreadButtonSelected.toggle()
        } label: {
            HStack(spacing: DS.Spacing.small) {
                Text(L10n.Mailbox.unread)
                    .accessibilityIdentifier(UnreadFilterIdentifiers.countLabel)
                Text(state.unreadCount.string)
                    .fontWeight(.semibold)
                    .accessibilityIdentifier(UnreadFilterIdentifiers.countValue)
            }
        }
    }

    private func selectAllButton() -> some View {
        Button {
            onSelectAllTapped()
        } label: {
            HStack(spacing: DS.Spacing.compact) {
                Image(symbol: state.selectAll.button.icon)
                    .font(.footnote)
                    .tint(state.selectAll.button.iconColor)
                Text(state.selectAll.button.text)
                    .font(.footnote)
                    .foregroundStyle(state.selectAll.button.textColor)
            }
        }
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, DS.Spacing.medium * scale)
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.massive * scale, style: .continuous)
                .stroke(DS.Color.Border.norm)
        }
    }
}

enum FilterBarVivibilityMode: Equatable {
    case regular
    case selectionMode
}

enum UnreadCounterState: Equatable {
    case known(unreadCount: UInt64)
    case unknown

    var string: String {
        switch self {
        case .known(let unreadCount):
            UnreadCountFormatter.string(count: unreadCount, maxCount: 99)
        case .unknown:
            "-".notLocalized
        }
    }
}

enum SelectAllState: Equatable {
    struct ButtonStyle {
        let icon: DS.SFSymbol
        let iconColor: Color
        let text: LocalizedStringResource
        let textColor: Color
    }

    case canSelectMoreItems
    case noMoreItemsToSelect
    case selectionLimitReached

    var button: ButtonStyle {
        let symbol: DS.SFSymbol
        let text: LocalizedStringResource

        switch self {
        case .canSelectMoreItems:
            symbol = .square
            text = L10n.Mailbox.selectAll
        case .noMoreItemsToSelect, .selectionLimitReached:
            symbol = .checkmarkSquare
            text = L10n.Mailbox.unselectAll
        }

        return .init(icon: symbol, iconColor: DS.Color.Icon.norm, text: text, textColor: DS.Color.Text.norm)
    }
}

enum SpamTrashToggleState: Equatable {
    case visible(isSelected: Bool)
    case hidden
}

extension SpamTrashToggleState {
    func toggled() -> Self {
        if case .visible(let isSelected) = self {
            .visible(isSelected: !isSelected)
        } else {
            .hidden
        }
    }

    var isSelected: Bool {
        switch self {
        case .visible(let isSelected):
            isSelected
        case .hidden:
            false
        }
    }

    var includeSpamTrash: IncludeSwitch {
        isSelected ? .withSpamAndTrash : .default
    }
}

struct FilterBarState: Equatable {
    var visibilityMode: FilterBarVivibilityMode = .regular
    var isUnreadButtonSelected: Bool = false
    var selectAll: SelectAllState = .canSelectMoreItems
    var unreadCount: UnreadCounterState = .unknown
    var spamTrashToggleState: SpamTrashToggleState = .hidden
}

private struct UnreadFilterIdentifiers {
    static let rootElement = "unread.filter.button"
    static let countLabel = "unread.filter.label"
    static let countValue = "unread.filter.value"
}

#Preview {
    struct Preview: View {
        @State var stateRegular: FilterBarState = .init(visibilityMode: .regular, unreadCount: .known(unreadCount: 3))
        @State var stateRegularUnknownCount: FilterBarState = .init(visibilityMode: .regular, unreadCount: .unknown)
        @State var stateSelectAllAvailable: FilterBarState = .init(visibilityMode: .selectionMode, selectAll: .canSelectMoreItems)
        @State var stateSelectAllAllSelected: FilterBarState = .init(visibilityMode: .selectionMode, selectAll: .noMoreItemsToSelect)
        @State var stateSelectAllDisabled: FilterBarState = .init(visibilityMode: .selectionMode, selectAll: .selectionLimitReached)
        var body: some View {
            VStack {
                FilterBarView(state: $stateRegular) { fatalError("button should be hidden") }
                FilterBarView(state: $stateRegularUnknownCount) { fatalError("button should be hidden") }
                FilterBarView(state: $stateSelectAllAvailable) { print("select all tapped") }
                FilterBarView(state: $stateSelectAllAllSelected) { print("select all tapped") }
                FilterBarView(state: $stateSelectAllDisabled) { fatalError("button should be disabled") }
            }
            .border(.red)
        }
    }

    return Preview()
}

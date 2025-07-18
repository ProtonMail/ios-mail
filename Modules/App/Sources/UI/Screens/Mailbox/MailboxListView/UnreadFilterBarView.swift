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

struct UnreadFilterBarView: View {
    @ScaledMetric var scale: CGFloat = 1

    @Binding var state: FilterBarState

    let onSelectAllTapped: () -> Void

    var body: some View {
        HStack {
            switch state.visibilityMode {
            case .regular:
                unreadButton()
            case .selectionMode:
                selectAllButton()
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.large)
        .padding(.vertical, DS.Spacing.standard)
        .background(DS.Color.Background.norm)
        .accessibilityIdentifier(UnreadFilterIdentifiers.rootElement)
    }

    private func unreadButton() -> some View {
        Button {
            state.isUnreadButtonSelected.toggle()
        } label: {
            HStack(spacing: DS.Spacing.small) {
                Text(L10n.Mailbox.unread)
                    .accessibilityIdentifier(UnreadFilterIdentifiers.countLabel)
                Text(state.unreadCount.string)
                    .fontWeight(.semibold)
                    .accessibilityIdentifier(UnreadFilterIdentifiers.countValue)
                if state.isUnreadButtonSelected {
                    Image(symbol: .xmark)
                        .foregroundStyle(DS.Color.Brand.plus30)
                        .transition(
                            .scale
                            .combined(with: .opacity)
                        )
                        .zIndex(-1)
                }
            }
            .animation(.easeIn(duration: 0.1), value: state.isUnreadButtonSelected)
            .font(.footnote)
            .foregroundStyle(state.isUnreadButtonSelected ? DS.Color.Brand.plus30 : DS.Color.Text.norm)
        }
        .accessibilityAddTraits(state.isUnreadButtonSelected ? .isSelected : [])
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, DS.Spacing.medium * scale)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.massive * scale, style: .continuous)
                .fill(state.isUnreadButtonSelected ? DS.Color.InteractionBrandWeak.norm : DS.Color.Background.norm)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.massive * scale, style: .continuous)
                .stroke(state.isUnreadButtonSelected ? .clear : DS.Color.Border.norm)
        }
        .animation(.easeOut(duration: 0.2), value: state.isUnreadButtonSelected)
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

enum FilterBarVivibilityMode {
    case regular
    case selectionMode
}

enum UnreadCounterState {
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

enum SelectAllState {
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

struct FilterBarState {
    var visibilityMode: FilterBarVivibilityMode = .regular
    var isUnreadButtonSelected: Bool = false
    var selectAll: SelectAllState = .canSelectMoreItems
    var unreadCount: UnreadCounterState = .unknown
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
                UnreadFilterBarView(state: $stateRegular) { fatalError("button should be hidden") }
                UnreadFilterBarView(state: $stateRegularUnknownCount) { fatalError("button should be hidden") }
                UnreadFilterBarView(state: $stateSelectAllAvailable) { print("select all tapped") }
                UnreadFilterBarView(state: $stateSelectAllAllSelected) { print("select all tapped") }
                UnreadFilterBarView(state: $stateSelectAllDisabled) { fatalError("button should be disabled") }
            }
            .border(.red)
        }
    }

    return Preview()
}

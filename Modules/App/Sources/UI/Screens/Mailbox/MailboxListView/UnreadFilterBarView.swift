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
                    .accessibilityIdentifier(UnreadFilterIdentifiers.countValue)
            }
            .font(.footnote)
            .foregroundStyle(DS.Color.Text.norm)
        }
        .accessibilityAddTraits(state.isUnreadButtonSelected ? .isSelected : [])
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, DS.Spacing.medium * scale)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.massive * scale, style: .continuous)
                .fill(state.isUnreadButtonSelected ? DS.Color.InteractionWeak.pressed : DS.Color.Background.norm)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.massive * scale, style: .continuous)
                .stroke(DS.Color.Border.norm)
        }
    }

    private func selectAllButton() -> some View {
        Button {
            onSelectAllTapped()
        } label: {
            HStack(spacing: DS.Spacing.compact) {
                Image(symbol: state.selectAll.icon)
                    .font(.footnote)
                    .tint(state.selectAll.iconColor)
                Text(state.selectAll.string)
                    .font(.footnote)
                    .foregroundStyle(state.selectAll.textColor)
            }
        }
        .disabled(state.selectAll.isDisabled)
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
    case canSelectMoreItems
    case noMoreItemsToSelect
    case selectionLimitReached

    var icon: DS.SFSymbol {
        switch self {
        case .canSelectMoreItems, .selectionLimitReached:
            .square
        case .noMoreItemsToSelect:
            .checkmarkSquare
        }
    }

    var iconColor: Color {
        isDisabled ? DS.Color.Icon.disabled : DS.Color.Icon.norm
    }

    var string: LocalizedStringResource {
        switch self {
        case .canSelectMoreItems, .selectionLimitReached:
            L10n.Mailbox.selectAll
        case .noMoreItemsToSelect:
            L10n.Mailbox.unselectAll
        }
    }

    var textColor: Color {
        isDisabled ? DS.Color.Text.disabled : DS.Color.Text.norm
    }

    var isDisabled: Bool {
        switch self {
        case .canSelectMoreItems, .noMoreItemsToSelect:
            false
        case .selectionLimitReached:
            true
        }
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

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
    @EnvironmentObject var toastStateStore: ToastStateStore
    @ScaledMetric var scale: CGFloat = 1

    @Binding var state: FilterBarState

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
                Image(DS.Icon.icEnvelopeDot)
                    .resizable()
                    .square(size: 16)
                    .tint(DS.Color.Icon.norm)

                Text(L10n.Mailbox.unread)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.weak)
                    .accessibilityIdentifier(UnreadFilterIdentifiers.countLabel)
                Text(state.unreadCount.string)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.weak)
                    .accessibilityIdentifier(UnreadFilterIdentifiers.countValue)
            }
        }
        .accessibilityAddTraits(state.isUnreadButtonSelected ? .isSelected : [])
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, DS.Spacing.medium*scale)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.massive*scale, style: .continuous)
                .fill(state.isUnreadButtonSelected ? DS.Color.InteractionWeak.pressed : DS.Color.Background.norm)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.massive*scale, style: .continuous)
                .stroke(DS.Color.Border.norm)
        }
    }

    private func selectAllButton() -> some View {
        Button {
            toastStateStore.present(toast: .comingSoon)
        } label: {
            HStack(spacing: DS.Spacing.small) {
                Image(DS.Icon.icCheckmarkCircle)
                    .resizable()
                    .square(size: 16)
                    .tint(DS.Color.Icon.norm)

                Text(L10n.Mailbox.selectAll)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.weak)
            }
        }
        .padding(.vertical, DS.Spacing.standard)
        .padding(.horizontal, DS.Spacing.medium*scale)
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.massive*scale, style: .continuous)
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

struct FilterBarState {
    var visibilityMode: FilterBarVivibilityMode = .regular
    var isUnreadButtonSelected: Bool = false
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
        @State var stateSelectionMode: FilterBarState = .init(visibilityMode: .selectionMode)
        var body: some View {
            VStack {
                UnreadFilterBarView(state: $stateRegular)
                UnreadFilterBarView(state: $stateRegularUnknownCount)
                UnreadFilterBarView(state: $stateSelectionMode)
            }
            .border(.red)
        }
    }

    return Preview()
}


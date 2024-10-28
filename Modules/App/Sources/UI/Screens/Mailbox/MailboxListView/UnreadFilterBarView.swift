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
import SwiftUI

struct UnreadFilterBarView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    @ScaledMetric var scale: CGFloat = 1
    @Binding var isSelected: Bool
    let unread: UInt64

    var body: some View {
        if let unreadFormatted = UnreadCountFormatter.string(count: unread, maxCount: 99) {
            HStack {
                Button {
                    toastStateStore.present(toast: .comingSoon)
                } label: {
                    HStack(spacing: DS.Spacing.small) {
                        Text(L10n.Mailbox.unread)
                            .font(.footnote)
                            .foregroundStyle(DS.Color.Text.weak)
                            .accessibilityIdentifier(UnreadFilterIdentifiers.countLabel)
                        Text(unreadFormatted)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(DS.Color.Text.norm)
                            .accessibilityIdentifier(UnreadFilterIdentifiers.countValue)
                    }
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .padding(.vertical, DS.Spacing.standard)
                .padding(.horizontal, DS.Spacing.medium*scale)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.huge*scale, style: .continuous)
                        .fill(isSelected ? DS.Color.Background.secondary : DS.Color.Background.norm)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: DS.Radius.huge*scale, style: .continuous)
                        .stroke(DS.Color.Border.norm)
                }
                Spacer()
            }
            .padding(.horizontal, DS.Spacing.large)
            .padding(.vertical, DS.Spacing.standard)
            .background(DS.Color.Background.norm)
            .accessibilityIdentifier(UnreadFilterIdentifiers.rootElement)
        }
    }
}

#Preview {
    struct Preview: View {
        @State var isSelected = false
        var body: some View {
            VStack {
                UnreadFilterBarView(isSelected: $isSelected, unread: 0)
                UnreadFilterBarView(isSelected: $isSelected, unread: 187)
            }
            .border(.red)
        }
    }

    return Preview()
}

private struct UnreadFilterIdentifiers {
    static let rootElement = "unread.filter.button"
    static let countLabel = "unread.filter.label"
    static let countValue = "unread.filter.value"
}

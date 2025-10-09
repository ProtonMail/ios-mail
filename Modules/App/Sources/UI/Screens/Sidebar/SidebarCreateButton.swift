// Copyright (c) 2025 Proton Technologies AG
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

struct SidebarCreateButton: View {
    let item: SidebarOtherItem
    let isTappable: Bool
    let isListEmpty: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isTappable {
                action()
            }
        }) {
            HStack(spacing: .zero) {
                Image(item.icon)
                    .resizable()
                    .renderingMode(.template)
                    .square(size: 20)
                    .foregroundStyle(DS.Color.Sidebar.iconWeak)
                    .padding(.trailing, DS.Spacing.extraLarge)
                    .accessibilityIdentifier(SidebarScreenIdentifiers.icon)
                Text(item.name)
                    .font(.subheadline)
                    .foregroundStyle(isListEmpty ? DS.Color.Sidebar.textNorm : DS.Color.Sidebar.textWeak)
                    .lineLimit(1)
                    .accessibilityIdentifier(SidebarScreenIdentifiers.textItem)
                Spacer()
            }
        }
        .buttonStyle(SidebarItemButtonStyle(isSelected: item.isSelected, isTappable: isTappable))
        .accessibilityIdentifier(SidebarScreenIdentifiers.otherButton(type: item.type))
    }
}

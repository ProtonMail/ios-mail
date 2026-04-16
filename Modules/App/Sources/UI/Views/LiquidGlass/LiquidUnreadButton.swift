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

@available(iOS 26, *)
struct LiquidUnreadButton: ToolbarContent {
    let isSelected: Bool
    let action: () -> Void

    var body: some ToolbarContent {
        if isSelected {
            ToolbarItem(placement: .bottomBar) {
                Button(action: action) {
                    HStack(spacing: DS.Spacing.standard) {
                        Text(L10n.Mailbox.unread)
                            .font(.body)
                        Image(symbol: .xmark)
                            .font(.callout)
                    }
                }
                .fontWeight(.medium)
                .buttonStyle(.glassProminent)
                .tint(DS.Color.InteractionBrand.norm)
            }
        } else {
            ToolbarItem(placement: .bottomBar) {
                Button(L10n.Mailbox.unread, action: action)
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
    }
}

#Preview {
    @Previewable @State var isSelected = false

    NavigationStack {
        Color.clear
            .toolbar {
                if #available(iOS 26, *) {
                    LiquidUnreadButton(
                        isSelected: isSelected,
                        action: { isSelected.toggle() }
                    )
                }
            }
            .animation(.default, value: isSelected)
    }
}

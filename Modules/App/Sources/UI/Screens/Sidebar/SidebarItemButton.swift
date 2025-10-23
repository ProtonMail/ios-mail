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

import SwiftUI

struct SidebarItemButton<Content: View>: View {
    private let item: SidebarItem
    private let isTappable: Bool
    private let action: () -> Void
    @ViewBuilder private let content: () -> Content

    init(
        item: SidebarItem,
        isTappable: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.item = item
        self.isTappable = isTappable
        self.action = action
        self.content = content
    }

    var body: some View {
        Button(action: {
            if isTappable {
                action()
            }
        }) {
            content()
        }
        .buttonStyle(SidebarButtonStyle(isSelected: item.isSelected, isTappable: isTappable))
    }
}

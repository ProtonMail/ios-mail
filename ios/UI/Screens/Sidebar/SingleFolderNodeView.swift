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
import DesignSystem

struct SingleFolderNodeView: View {

    private let folder: SidebarFolder
    private let padding: CGFloat
    private let selected: (SidebarFolder) -> Void
    @State private var isExpanded: Bool

    init(folder: SidebarFolder, padding: CGFloat = 0, selected: @escaping (SidebarFolder) -> Void) {
        self.folder = folder
        self.padding = padding
        self.selected = selected
        self.isExpanded = folder.expanded
    }

    var body: some View {
        VStack {
            SidebarItemButton(item: .folder(folder), action: { selected(folder) }) {
                HStack {
                    Image(folder.childFolders.isEmpty ? DS.Icon.icFolder : DS.Icon.icFolders)
                        .renderingMode(.template)
                        .square(size: 20)
                        .tint(folder.displayColor)
                        .padding(.trailing, DS.Spacing.extraLarge)
                    Text(folder.name)
                        .font(.subheadline)
                        .fontWeight(folder.isSelected ? .bold : .regular)
                        .foregroundStyle(folder.isSelected ? DS.Color.Sidebar.textSelected : DS.Color.Sidebar.textNorm)
                        .lineLimit(1)
                    Spacer()
                    if !folder.childFolders.isEmpty {
                        Button(action: { isExpanded.toggle() }) {
                            Image(isExpanded ? DS.Icon.icChevronUpFilled : DS.Icon.icChevronDownFilled)
                                .resizable()
                                .square(size: 16)
                                .tint(DS.Color.Sidebar.iconWeak)
                                .background(DS.Color.Global.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .square(size: 16)
                        .animation(.default, value: isExpanded)
                    }
                    VStack {
                        if let unreadFormatted = UnreadCountFormatter.string(count: folder.unreadCount) {
                            Text(unreadFormatted)
                                .foregroundStyle(
                                    folder.isSelected ? DS.Color.Sidebar.textNorm : DS.Color.Sidebar.textWeak
                                )
                                .font(.caption)
                        }
                    }
                    .frame(width: 32, alignment: .trailing)
                }
                .padding(.leading, padding)
            }

            if !folder.childFolders.isEmpty, isExpanded {
                FolderNodeView(
                    folders: folder.childFolders,
                    padding: padding + DS.Spacing.large,
                    selected: selected
                )
            }
        }
    }

}

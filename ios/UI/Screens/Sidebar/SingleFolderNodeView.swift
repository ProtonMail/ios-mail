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

    private let folderNode: SidebarFolderNode
    private let selected: (SidebarFolder) -> Void
    private let padding: CGFloat
    @State var isExpanded: Bool

    init(folderNode: SidebarFolderNode, padding: CGFloat = 0, selected: @escaping (SidebarFolder) -> Void) {
        self.folderNode = folderNode
        self.padding = padding
        self.selected = selected
        self.isExpanded = folderNode.folder.expanded
    }

    var body: some View {
        VStack {
            Button(action: { selected(folderNode.folder) }) {
                HStack {
                    Image(folderNode.children.isEmpty ? DS.Icon.icFolder : DS.Icon.icFolders)
                        .renderingMode(.template)
                        .square(size: 20)
                        .tint(Color(hex: folderNode.folder.color))
                        .padding(.trailing, DS.Spacing.extraLarge)
                    Text(folderNode.folder.name)
                        .font(.subheadline)
                        .fontWeight(folderNode.folder.isSelected ? .bold : .regular)
                        .foregroundStyle(folderNode.folder.isSelected ? DS.Color.Sidebar.textSelected : DS.Color.Sidebar.textNorm)
                        .lineLimit(1)
                    Spacer()
                    if !folderNode.children.isEmpty {
                        Button(action: { isExpanded.toggle() }) {
                            Image(isExpanded ? DS.Icon.icChevronUpFilled : DS.Icon.icChevronDownFilled)
                                .resizable()
                                .square(size: 16)
                                .tint(DS.Color.Sidebar.iconWeak)
                                .background(DS.Color.Global.white.opacity(0.04)) // FIXME: - Check the color with Zuza
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .square(size: 16)
                        .background(.red)
                        .animation(.default, value: isExpanded)
                    }
                    VStack {
                        if let unreadBadge = folderNode.folder.unreadBadge {
                            Text(unreadBadge)
                                .foregroundStyle(folderNode.folder.isSelected ? DS.Color.Sidebar.textNorm : DS.Color.Sidebar.textWeak)
                                .font(.caption)
                        }
                    }
                    .frame(width: 32, alignment: .trailing)
                }
                .padding(.leading, padding)
            }
            .padding(.vertical, DS.Spacing.medium)
            .padding(.horizontal, DS.Spacing.extraLarge)
            .background(folderNode.folder.isSelected ? DS.Color.Sidebar.interactionPressed : .clear)

            if !folderNode.children.isEmpty, isExpanded {
                FolderNodeView(
                    folders: folderNode.children,
                    padding: padding + DS.Spacing.large,
                    selected: selected
                )
            }
        }
    }

}

private extension SidebarFolder {

    var unreadBadge: String? {
        unreadCount == 0 ? nil : unreadCount.toBadgeCapped()
    }

}

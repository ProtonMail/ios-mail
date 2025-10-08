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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct SingleFolderNodeView<UnreadText: View>: View {
    private let folder: SidebarFolder
    private let isTappable: Bool
    private let padding: CGFloat
    private let selected: (SidebarFolder) -> Void
    private let toggle: (SidebarFolder, Bool) -> Void
    private let unreadTextView: (_ count: String, _ isSelected: Bool) -> UnreadText
    @State private var isExpanded: Bool

    init(
        folder: SidebarFolder,
        isTappable: Bool,
        padding: CGFloat = 0,
        selected: @escaping (SidebarFolder) -> Void,
        toggle: @escaping (SidebarFolder, Bool) -> Void,
        unreadTextView: @escaping (_ count: String, _ isSelected: Bool) -> UnreadText
    ) {
        self.folder = folder
        self.isTappable = isTappable
        self.padding = padding
        self.selected = selected
        self.toggle = toggle
        self.unreadTextView = unreadTextView
        self.isExpanded = folder.expanded
    }

    var body: some View {
        VStack {
            SidebarItemButton(
                item: .folder(folder),
                isTappable: isTappable,
                action: { selected(folder) }
            ) {
                HStack(spacing: .zero) {
                    Image(folder.childFolders.isEmpty ? DS.Icon.icFolderFilled : DS.Icon.icFoldersFilled)
                        .renderingMode(.template)
                        .resizable()
                        .square(size: 20)
                        .tint(folder.displayColor)
                        .padding(.trailing, DS.Spacing.extraLarge)
                        .accessibilityIdentifier(SidebarFolderNodeViewIdentifiers.icon)
                    Text(folder.name)
                        .font(.subheadline)
                        .fontWeight(folder.isSelected ? .bold : .regular)
                        .foregroundStyle(folder.isSelected ? DS.Color.Sidebar.textSelected : DS.Color.Sidebar.textNorm)
                        .lineLimit(1)
                        .accessibilityIdentifier(SidebarFolderNodeViewIdentifiers.textItem)
                    Spacer()

                    if !folder.childFolders.isEmpty {
                        Button(action: { toggleChildFoldersVisibility() }) {
                            Image(isExpanded ? DS.Icon.icChevronUpFilled : DS.Icon.icChevronDownFilled)
                                .resizable()
                                .square(size: 16)
                                .tint(DS.Color.Sidebar.iconWeak)
                                .background(DS.Color.Global.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .square(size: 16)
                        .animation(.default, value: isExpanded)
                        .accessibilityIdentifier(SidebarFolderNodeViewIdentifiers.chevronItem)
                    }
                    Group {
                        if let unreadFormatted = UnreadCountFormatter.stringIfGreaterThan0(count: folder.unreadCount) {
                            unreadTextView(unreadFormatted, folder.isSelected)
                        }
                    }
                    .frame(width: 35, alignment: .trailing)
                }
                .padding(.leading, padding)
                .accessibilityElement(children: .contain)
            }

            if !folder.childFolders.isEmpty, isExpanded {
                ForEach(folder.childFolders) { childFolder in
                    SingleFolderNodeView(
                        folder: childFolder,
                        isTappable: isTappable,
                        padding: padding + DS.Spacing.large,
                        selected: selected,
                        toggle: toggle,
                        unreadTextView: unreadTextView
                    )
                }
            }
        }
    }

    private func toggleChildFoldersVisibility() {
        isExpanded.toggle()
        toggle(folder, isExpanded)
    }
}

private struct SidebarFolderNodeViewIdentifiers {
    static let icon = "sidebar.button.icon"
    static let textItem = "sidebar.button.text"
    static let chevronItem = "sidebar.button.chevron"
}

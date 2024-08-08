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

struct FolderNodeView: View {

    private let folders: [SidebarFolderNode]
    private let selected: (SidebarFolder) -> Void
    private let padding: CGFloat

    init(folders: [SidebarFolderNode], padding: CGFloat = 0, selected: @escaping (SidebarFolder) -> Void) {
        self.folders = folders
        self.padding = padding
        self.selected = selected
    }

    var body: some View {
        ForEach(folders) { folderNode in
            SingleFolderNodeView(folderNode: folderNode, padding: padding, selected: selected)
        }
    }

}

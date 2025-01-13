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
import proton_app_uniffi
import class SwiftUI.UIImage

struct CustomFolderNode: Sendable {
    var folder: PMCustomFolder
    var children: [CustomFolderNode]

    /**
     Flattens the folder structure.
     - Returns: An array of flattened CustomFolders where the parent folder is followed by its child folders

     Runs a tree traversal that follows the Root-Left-Right policy where:

     1. The root node of the subtree is visited first.
     2. Then the left subtree  is traversed.
     3. At last, the right subtree is traversed.

     Example:

     the following structure
     ```
     F1
     |- F11
      |- F111
      |- F112
     |- F12
     ```
     would return [F1, F11, F111, F112, F12]
    */
    func preorderTreeTraversal() -> [CustomFolderNode] {
        return [self] + children.flatMap { $0.preorderTreeTraversal() }
    }
}

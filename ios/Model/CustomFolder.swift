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

import DesignSystem
import proton_mail_uniffi
import class SwiftUI.UIImage

struct CustomFolder: Sendable {
    var folder: LocalLabel
    var children: [CustomFolder]

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
    func preorderTreeTraversal() -> [CustomFolder] {
        return [self] + children.flatMap { $0.preorderTreeTraversal() }
    }
}

extension Array where Element == CustomFolder {

    /// Sorts every folder, and child folder, using the comparison logic
    func recursivelySorted(by comparison: (Self.Element, Self.Element) -> Bool) -> [Element] {
        var sorted = sorted(by: comparison)
        for (index, _) in sorted.enumerated() {
            sorted[index].children = sorted[index].children.recursivelySorted(by: comparison)
        }
        return sorted
    }
}

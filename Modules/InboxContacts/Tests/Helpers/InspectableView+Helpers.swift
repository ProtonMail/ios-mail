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

@testable import ViewInspector
import SwiftUI
import InboxCoreUI

extension InspectableView {

    func find(buttonWithImage imageResource: ImageResource) throws -> InspectableView<ViewType.Button> {
        try find(ViewType.Button.self) { button in
            let buttonWithImage = try button
                .findAll(Image.self)
                .first { image in try image.actualView() == Image(imageResource) }

            return buttonWithImage != nil
        }
    }

    /// Finds all `Toolbar` modifiers at the current view level.
    ///
    /// This method identifies and extracts all `Toolbar` modifiers applied directly to the current view,
    /// returning them as `InspectableView<ViewType.Toolbar>` instances. It does not search nested or child views.
    ///
    /// ### Example Usage:
    /// ```swift
    /// let toolbars = try view.findToolbars()
    /// XCTAssertEqual(toolbars.count, 2)
    /// ```
    ///
    /// - Returns: An array of `InspectableView<ViewType.Toolbar>`.
    /// - Throws: Errors if modifier extraction or content unwrapping fails.
    /// - Note: This method operates only on the current view level for efficiency.
    func findToolbars() throws -> [InspectableView<ViewType.Toolbar>] {
        try modifiersMatching { modifier in
            let modifierName = modifier.modifierType(prefixOnly: true)
            return modifierName == ViewType.Toolbar.typePrefix
        }
        .enumerated()
        .map { index, modifier -> InspectableView<ViewType.Toolbar> in
            let root = try Inspector.attribute(label: "modifier", value: modifier)
            let medium = content.medium.resettingViewModifiers()
            let content = try Inspector.unwrap(content: Content(root, medium: medium))
            let call = ViewType.inspectionCall(
                base: ViewType.Toolbar.inspectionCall(typeName: ""),
                index: index
            )
            return try .init(content, parent: self, call: call, index: index)
        }
    }

}

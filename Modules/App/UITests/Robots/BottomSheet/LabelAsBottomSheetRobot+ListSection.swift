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

import Foundation
import XCTest

extension LabelAsBottomSheetRobot {
    // MARK: UI Elements

    private var labelsList: XCUIElement {
        rootElement.collectionViews[Identifiers.labelsList]
    }

    // MARK: Assertions

    func hasAlsoArchive(toggled: Bool = false) {
        let model = UITestBottomSheetLabelAsAlsoArchiveEntryModel(parent: rootElement)

        model.hasText()
        model.hasToggledState(toggled)
    }

    func hasCreationEntryAt(_ index: Int) {
        let model = UITestBottomSheetLabelAsCreateEntryModel(
            index: index,
            parent: labelsList
        )

        model.hasIcon()
        model.hasTitle("Create new label")
        model.hasCheckmarkIcon(false)
    }

    func hasEntries(_ entries: [UITestLabelAsBottomSheetEntry]) {
        for entry in entries {
            hasEntry(entry)
        }
    }

    private func hasEntry(_ entry: UITestLabelAsBottomSheetEntry) {
        let model = UITestBottomSheetLabelAsEntryModel(
            index: entry.index,
            parent: labelsList
        )

        model.hasIcon()
        model.hasTitle(entry.text)
        model.hasCheckmarkIcon(entry.hasCheckmarkIcon)
    }
}

private struct Identifiers {
    static let labelsList = "bottomSheet.labelAs.labelsList"
}

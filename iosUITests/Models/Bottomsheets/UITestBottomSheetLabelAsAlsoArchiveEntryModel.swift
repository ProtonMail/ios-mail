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

struct UITestBottomSheetLabelAsAlsoArchiveEntryModel: ApplicationHolder {
    let parent: XCUIElement

    // MARK: UI Elements

    private var rootElement: XCUIElement {
        parent.otherElements[Identifiers.rootElement]
    }

    private var icon: XCUIElement {
        rootElement.images[Identifiers.alsoArchiveIcon]
    }

    private var toggle: XCUIElement {
        rootElement.switches[Identifiers.alsoArchiveToggle]
    }

    // MARK: Assertions

    func hasText() {
        XCTAssertEqual("Also archive?", toggle.label)
    }

    func hasToggledState(_ value: Bool) {
        XCTAssertEqual(value, toggle.value.booleanValue)
    }
}

private struct Identifiers {
    static let rootElement = "bottomSheet.labelAs.alsoArchive"
    static let alsoArchiveIcon = "bottomSheet.labelAs.alsoArchive.icon"
    static let alsoArchiveToggle = "bottomSheet.labelAs.alsoArchive.toggle"
}

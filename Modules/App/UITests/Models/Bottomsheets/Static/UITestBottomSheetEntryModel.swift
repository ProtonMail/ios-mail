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

protocol UITestBottomSheetEntryModel {
    var index: Int { get }
    var parent: XCUIElement { get }
    var rootElement: XCUIElement { get }
    var type: UITestBottomSheetEntryType { get }
}

extension UITestBottomSheetEntryModel {
    // MARK: UI Elements

    var rootElement: XCUIElement {
        parent.otherElements["\(type.identifier())\(index)"]
    }

    private var imageIcon: XCUIElement {
        switch type {
        case .createLabel, .createFolder: rootElement.images[Identifiers.cellIcon]
        case .label, .folder: rootElement.otherElements[Identifiers.cellIcon]
        }
    }

    private var titleText: XCUIElement {
        rootElement.staticTexts[Identifiers.cellText]
    }

    private var checkMarkIcon: XCUIElement {
        rootElement.images[Identifiers.cellSelectionIcon]
    }

    // MARK: Assertions

    func hasIcon() {
        XCTAssert(imageIcon.exists)
    }

    func hasTitle(_ title: String) {
        XCTAssertEqual(title, titleText.label)
    }

    func hasCheckmarkIcon(_ value: Bool) {
        XCTAssertEqual(value, checkMarkIcon.isHittable)
    }
}

private struct Identifiers {
    static let cellText = "bottomSheet.cell.text"
    static let cellIcon = "bottomSheet.cell.icon"
    static let cellSelectionIcon = "bottomSheet.cell.selectionIcon"
}

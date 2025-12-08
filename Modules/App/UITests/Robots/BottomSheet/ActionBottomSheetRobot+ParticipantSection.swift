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

extension ActionBottomSheetRobot {
    private var avatarText: XCUIElement {
        rootElement.staticTexts[Identifiers.avatarText]
    }

    private var participantName: XCUIElement {
        rootElement.staticTexts[Identifiers.participantName]
    }

    private var participantAddress: XCUIElement {
        rootElement.staticTexts[Identifiers.participantAddress]
    }

    func hasParticipant(entry: UITestActionSheetParticipantEntry) {
        XCTAssertEqual(avatarText.label, entry.avatarText)
        XCTAssertEqual(participantName.label, entry.participantName)
        XCTAssertEqual(participantAddress.label, entry.participantAddress)
    }
}

private struct Identifiers {
    static let avatarText = "avatar.text"
    static let participantName = "actionPicker.participant.name"
    static let participantAddress = "actionPicker.participant.address"
}

struct UITestActionSheetParticipantEntry {
    let avatarText: String
    let participantName: String
    let participantAddress: String
}

// Copyright (c) 2025 Proton Technologies AG
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

import InboxCore
import InboxDesignSystem
import SwiftUI
import Testing

@testable import InboxRSVP

struct EventMenuParticipantOptionTests {
    typealias Expected = (displayName: String, trailingIcon: ImageResource)

    @Test(
        arguments:
            zip(
                EventMenuParticipantOption.allCases,
                [
                    Expected(displayName: L10n.OrganizerMenuOption.copyAction.string, DS.Icon.icSquares),
                    Expected(displayName: L10n.OrganizerMenuOption.newMessage.string, DS.Icon.icPenSquare),
                ]
            )
    )
    func testDisplayNameAndTrailingIcon(_ given: EventMenuParticipantOption, expected: Expected) {
        #expect(given.displayName.string == expected.displayName)
        #expect(given.trailingIcon == expected.trailingIcon)
    }
}

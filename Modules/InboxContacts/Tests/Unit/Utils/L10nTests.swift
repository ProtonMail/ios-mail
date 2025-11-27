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

import Testing

@testable import InboxContacts

final class L10nTests {
    @Test
    func testContactsGroupSubtitle_For1Member_ReturnsCorrectString() {
        #expect(L10n.Contacts.groupSubtitle(membersCount: 1).string == "1 member")
    }

    @Test
    func testContactsGroupSubtitle_For2Members_ReturnsCorrectString() {
        #expect(L10n.Contacts.groupSubtitle(membersCount: 2).string == "2 members")
    }
}

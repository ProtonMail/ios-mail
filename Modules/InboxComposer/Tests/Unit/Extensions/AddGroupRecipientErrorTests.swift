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

@testable import InboxComposer
import proton_app_uniffi
import Testing

final class AddGroupRecipientErrorTests {

    @Test
    func testLocalizedErrorMessage_itReturnsCorrectMessage() throws {
        var sut = AddGroupRecipientError.duplicate([])
        #expect(sut.localizedErrorMessage()?.string == nil)

        sut = AddGroupRecipientError.duplicate(["a@example.com"])
        #expect(sut.localizedErrorMessage()?.string == "Removed duplicate recipient: a@example.com")

        sut = AddGroupRecipientError.duplicate(["a@example.com", "b@example.com"])
        #expect(sut.localizedErrorMessage()?.string == "Removed duplicate recipients: a@example.com, b@example.com")
    }
}

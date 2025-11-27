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

import Foundation
import Testing
import proton_app_uniffi

@testable import InboxComposer

struct DraftExpirationTimeTests {
    @Test
    func isCustomDate_whenCustomCase_itShouldReturnTrue() {
        let timestamp = UnixTimestamp(Date().timeIntervalSince1970)
        let time = DraftExpirationTime.custom(timestamp)
        #expect(time.isCustomDate == true)
    }

    @Test
    func isCustomDate_whenNonCustomCase_itShouldReturnFalse() {
        let time = DraftExpirationTime.oneDay
        #expect(time.isCustomDate == false)
    }

    @Test
    func customDate_whenCustomCase_itShouldReturnCorrectDate() {
        let unixTimestamp = UnixTimestamp(1_697_000_000)
        let expectedDate = Date(timeIntervalSince1970: TimeInterval(unixTimestamp))
        let time = DraftExpirationTime.custom(unixTimestamp)

        #expect(time.customDate == expectedDate)
    }

    @Test
    func customDate_whenNonCustomCase_itShouldReturnNil() {
        let time = DraftExpirationTime.oneHour
        #expect(time.customDate == nil)
    }
}

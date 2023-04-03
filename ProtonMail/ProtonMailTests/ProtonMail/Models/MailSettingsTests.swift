// Copyright (c) 2023 Proton Technologies AG
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

import XCTest
@testable import ProtonMail

class MailSettingsTests: XCTestCase {
    func testMailSettingsDecode_valueIsMoreThan0_flagIsTrue() throws {
        let value = Int.random(in: 1...Int.max)
        let json: [String: Any] = [
            "NextMessageOnMove": value,
            "HideSenderImages": value
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let result = try decoder.decode(MailSettings.self, from: data)
        XCTAssertTrue(result.nextMessageOnMove)
        XCTAssertTrue(result.hideSenderImages)
    }

    func testMailSettingsDecode_valueIsSmallerThan1_flagIsFalse() throws {
        let value = Int.random(in: Int.min...0)
        let json: [String: Any] = [
            "NextMessageOnMove": value,
            "HideSenderImages": value
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let result = try decoder.decode(MailSettings.self, from: data)
        XCTAssertFalse(result.nextMessageOnMove)
        XCTAssertFalse(result.hideSenderImages)
    }
}

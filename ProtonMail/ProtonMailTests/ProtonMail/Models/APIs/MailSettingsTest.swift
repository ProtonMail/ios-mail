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

final class MailSettingsTest: XCTestCase {
    var sut: MailSettings!

    override func setUpWithError() throws {
        sut = MailSettings()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testUpdateKey_valueShouldUpdatedByGivenValue() throws {
        // Default value is false
        sut.update(key: .hideSenderImages, to: true)
        XCTAssertTrue(sut.hideSenderImages)

        // Default is implicitlyDisabled
        sut.update(key: .nextMessageOnMove, to: true)
        XCTAssertEqual(sut.nextMessageOnMove, .explicitlyEnabled)

        sut.update(key: .nextMessageOnMove, to: false)
        XCTAssertEqual(sut.nextMessageOnMove, .explicitlyDisabled)

        sut.update(key: .autoDeleteSpamTrashDays, to: true)
        XCTAssertEqual(sut.autoDeleteSpamTrashDays, .explicitlyEnabled)

        sut.update(key: .autoDeleteSpamTrashDays, to: false)
        XCTAssertEqual(sut.autoDeleteSpamTrashDays, .explicitlyDisabled)

        sut.update(key: .almostAllMail, to: true)
        XCTAssertEqual(sut.almostAllMail, true)
    }

    func testMailSettingsDecode_valueIsMoreThan0_flagIsTrue() throws {
        let value = Int.random(in: 1...Int.max)
        let json: [String: Any] = [
            "NextMessageOnMove": 1,
            "HideSenderImages": value,
            "AutoDeleteSpamAndTrashDays": 30,
            "AlmostAllMail": 1
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let result = try decoder.decode(MailSettings.self, from: data)
        XCTAssertEqual(result.nextMessageOnMove, .implicitlyDisabled)
        XCTAssertTrue(result.hideSenderImages)
        XCTAssertEqual(result.autoDeleteSpamTrashDays, .explicitlyEnabled)
        XCTAssertEqual(result.almostAllMail, true)
    }

    func testMailSettingsDecode_valueIsSmallerThan1_flagIsFalse() throws {
        let value = Int.random(in: Int.min...0)
        let json: [String: Any] = [
            "NextMessageOnMove": 0,
            "HideSenderImages": value,
            "AutoDeleteSpamAndTrashDays": 0,
            "AlmostAllMail": 0
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let result = try decoder.decode(MailSettings.self, from: data)
        XCTAssertEqual(result.nextMessageOnMove, .explicitlyDisabled)
        XCTAssertFalse(result.hideSenderImages)
        XCTAssertEqual(result.autoDeleteSpamTrashDays, .explicitlyDisabled)
        XCTAssertEqual(result.almostAllMail, false)
    }

    func testMailSettingsDecode_valueIsNull_flagIsImplicitlyDisabled() throws {
        let json: [String: Any] = [:]
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        let result = try decoder.decode(MailSettings.self, from: data)
        XCTAssertEqual(result.autoDeleteSpamTrashDays, .implicitlyDisabled)
    }
}

// Copyright (c) 2022 Proton Technologies AG
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

@testable import ProtonMail
import XCTest

final class MessageIDTests: XCTestCase {
    func testHasLocalFormat() {
        let sut = MessageID.generateLocalID()

        XCTAssertTrue(sut.hasLocalFormat)
    }

    func testHasLocalFormat_withNonUUID_returnFalse() {
        let sut = MessageID("cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==")

        XCTAssertFalse(sut.hasLocalFormat)
    }

    func testMessageID_below9Characters_hasNoNotificationID() {
        for length in 1..<9 {
            let rawMessageID = String.randomString(length)
            let messageID = MessageID(rawMessageID)
            let generatedUUID = messageID.notificationId
            XCTAssertNil(generatedUUID, "Expected nil for \(rawMessageID) (\(length) characters)")
        }
    }

    func testMessageID_ofAtLeast10Characters_hasNotificationID() {
        for length in 10...100 {
            let rawMessageID = String.randomString(length)
            let messageID = MessageID(rawMessageID)
            let generatedUUID = messageID.notificationId
            XCTAssertNotNil(generatedUUID, "Expected a value for \(rawMessageID) (\(length) characters)")
        }
    }

    func testNotificationID_specificExamplesToCompareAgainstBackendCalculation() {
        let pairs: [(messageId: String, uuid: String)] = [
            ("l8vWAXHBQmv0u7OVtPbcqMa4iwQaBqowINSQjPrxAr-Da8fVPKUkUcqAq30_BCxj1X0nW70HQRmAa-rIvzmKUA==",
             "6c387657-4158-4842-516d"),
            ("uRA-Yxg_D1aU_WssF71zbN2Cd_FVkmhu2PdvNnt6Fz4fiMJhXTjTVqDJJBxcetoX8ja6qRCzRdMLw65AiPbgRA==",
             "7552412d-5978-675f-4431")
        ]
        pairs.forEach { messageId, expectedUUID in
            let notificationId = MessageID(messageId).notificationId
            XCTAssertEqual(notificationId, expectedUUID)
        }
    }
}

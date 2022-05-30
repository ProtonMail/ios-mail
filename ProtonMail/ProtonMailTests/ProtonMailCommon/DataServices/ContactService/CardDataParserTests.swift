// Copyright (c) 2022 Proton AG
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

import ProtonCore_DataModel
import XCTest

@testable import ProtonMail

class CardDataParserTests: XCTestCase {
    private var sut: CardDataParser!
    private let email = "emaile@aaa.bbb"

    override func setUpWithError() throws {
        try super.setUpWithError()

        let userPrivateKey = Key(keyID: "", privateKey: ContactParserTestData.privateKey)
        sut = CardDataParser(userKeys: [userPrivateKey])
    }

    override func tearDownWithError() throws {
        sut = nil

        try super.tearDownWithError()
    }

    func testParsesCorrectContactWithValidSignature() throws {
        let cardData = CardData(
            t: .SignedOnly,
            d: ContactParserTestData.signedOnlyData,
            s: ContactParserTestData.signedOnlySignature
        )

        let parsed = try sut.verifyAndParseContact(with: email, from: [cardData]).wait()
        XCTAssertEqual(parsed.email, email)
    }

    func testRejectsCorrectContactIfSignatureIsInvalid() {
        let cardData = CardData(
            t: .SignedOnly,
            d: ContactParserTestData.signedOnlyData,
            s: "invalid signature"
        )

        XCTAssertThrowsError(try sut.verifyAndParseContact(with: email, from: [cardData]).wait())
    }

    func testIgnoresCardDataTypesOtherThanSignedOnly() {
        let ignoredTypes: [CardDataType] = [.PlainText, .EncryptedOnly, .SignAndEncrypt]
        let unhandledCards = ignoredTypes.map {
            CardData(
                t: $0,
                d: ContactParserTestData.signedOnlyData,
                s: ContactParserTestData.signedOnlySignature
            )
        }

        XCTAssertThrowsError(try sut.verifyAndParseContact(with: email, from: unhandledCards).wait())
    }
}

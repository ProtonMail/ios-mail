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

import Foundation
import XCTest
@testable import ProtonMail

class ArrayRecipientSendPreferencesTests: XCTestCase {
    private var sut: [RecipientSendPreferences]!

    private let requiringPGPMime = ArrayRecipientSendPreferencesTests.makePreferences(pgpScheme: .pgpMIME)
    private let requiringCleartextMime = ArrayRecipientSendPreferencesTests.makePreferences(pgpScheme: .cleartextMIME)
    private let notRequiringMime1 = ArrayRecipientSendPreferencesTests.makePreferences(pgpScheme: .cleartextInline)
    private let notRequiringMime2 = ArrayRecipientSendPreferencesTests.makePreferences(pgpScheme: .pgpInline)

    private let requiringPlainText = ArrayRecipientSendPreferencesTests.makePreferences(mimeType: .plainText)
    private let notRequiringPlainText = ArrayRecipientSendPreferencesTests.makePreferences(mimeType: .mime)

    func testAtLeastOneRequiresMimeFormat_whenThereIsNone_returnsFalse() {
        sut = [notRequiringMime1, notRequiringMime2]
        XCTAssertFalse(sut.atLeastOneRequiresMimeFormat)
    }

    func testAtLeastOneRequiresMimeFormat_whenThereAreSome_returnsTrue() {
        sut = [notRequiringMime1, requiringPGPMime, notRequiringMime2, requiringCleartextMime]
        XCTAssertTrue(sut.atLeastOneRequiresMimeFormat)
    }

    func testAtLeastOneRequiresPlainTextFormat_whenThereIsNone_returnsFalse() {
        sut = [notRequiringPlainText]
        XCTAssertFalse(sut.atLeastOneRequiresPlainTextFormat)
    }

    func testAtLeastOneRequiresPlainTextFormat_whenThereAreSome_returnsTrue() {
        sut = [notRequiringPlainText, requiringPlainText]
        XCTAssertTrue(sut.atLeastOneRequiresPlainTextFormat)
    }
}

extension ArrayRecipientSendPreferencesTests {

    private static func makePreferences(
        pgpScheme: PGPScheme = .pgpMIME,
        mimeType: SendMIMEType = .plainText
    ) -> RecipientSendPreferences {
        return RecipientSendPreferences(
            emailAddress: "dummy@example.com",
            sendPreferences: SendPreferences(
                encrypt: false,
                sign: false,
                pgpScheme: pgpScheme,
                mimeType: mimeType,
                publicKeys: nil,
                isPublicKeyPinned: false,
                hasApiKeys: false,
                hasPinnedKeys: false,
                error: nil
            )
        )
    }
}

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

@testable import ProtonMail
import XCTest

class ContactAddRequestTest: XCTestCase {
    func testParameters_withImportFromDeviceIsTrue_containsImportFlag() throws {
        let sut = ContactAddRequest(cards: [],
                                    authCredential: nil,
                                    importedFromDevice: true)
        let parameters = try XCTUnwrap(sut.parameters)
        XCTAssertEqual(parameters["Import"] as? Int, 1)
    }

    func testParameters_withoutImportFromDeviceIsFalse_notContainsImportFlag()  throws {
        let sut = ContactAddRequest(cards: [],
                                    authCredential: nil,
                                    importedFromDevice: false)
        let parameters = try XCTUnwrap(sut.parameters)
        XCTAssertNil(parameters["Import"] as? Int)
    }
}

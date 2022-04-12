// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class ComposeViewControllerHelperTests: XCTestCase {

    var sut: ComposeViewControllerHelper!

    override func setUp() {
        super.setUp()
        sut = ComposeViewControllerHelper()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testShouldShowExpirationWarning() throws {
        XCTAssertTrue(sut.shouldShowExpirationWarning(havingPGPPinned: true,
                                                      isPasswordSet: false,
                                                      havingNonPMEmail: false))
        XCTAssertTrue(sut.shouldShowExpirationWarning(havingPGPPinned: false,
                                                      isPasswordSet: false,
                                                      havingNonPMEmail: true))
        XCTAssertFalse(sut.shouldShowExpirationWarning(havingPGPPinned: false,
                                                       isPasswordSet: false,
                                                       havingNonPMEmail: false))
        XCTAssertTrue(sut.shouldShowExpirationWarning(havingPGPPinned: true,
                                                      isPasswordSet: false,
                                                      havingNonPMEmail: true))
        // without password set
        XCTAssertFalse(sut.shouldShowExpirationWarning(havingPGPPinned: true,
                                                       isPasswordSet: true,
                                                       havingNonPMEmail: false))
        XCTAssertFalse(sut.shouldShowExpirationWarning(havingPGPPinned: false,
                                                       isPasswordSet: true,
                                                       havingNonPMEmail: true))
        XCTAssertFalse(sut.shouldShowExpirationWarning(havingPGPPinned: false,
                                                       isPasswordSet: true,
                                                       havingNonPMEmail: false))
        XCTAssertFalse(sut.shouldShowExpirationWarning(havingPGPPinned: true,
                                                       isPasswordSet: true,
                                                       havingNonPMEmail: true))
    }

}

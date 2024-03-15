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

import XCTest
@testable import ProtonMail

final class MessageSwipeNavigationViewModelTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var sut: MessageSwipeNavigationViewModel!
    private let suitName = "unit.proton.test"

    override func setUpWithError() throws {
        userDefaults = UserDefaults(suiteName: suitName)
        sut = .init(userDefaults: userDefaults)
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: suitName)
        userDefaults = nil
        sut = nil
        try super.tearDownWithError()
    }

    func testConstantText() throws {
        XCTAssertEqual(sut.title, "Swipe to next message")
        let footer = try XCTUnwrap(sut.sectionFooter(section: 0))
        switch footer {
        case .left(let text):
            XCTAssertEqual(text, "Allow navigating through messages by swiping left or right.")
        case .right:
            XCTFail("Unexpected")
        }
        XCTAssertNil(sut.sectionHeader())
    }

    func testToggle() throws {
        XCTAssertTrue(userDefaults[.isMessageSwipeNavigationEnabled])
        let expectation1 = expectation(description: "Disalbe feature")
        sut.toggle(for: .init(row: 0, section: 0), to: false) { error in
            XCTAssertNil(error)
            XCTAssertFalse(self.userDefaults[.isMessageSwipeNavigationEnabled])
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1)
        let expectation2 = expectation(description: "Enable feature")
        sut.toggle(for: .init(row: 0, section: 0), to: true) { error in
            XCTAssertNil(error)
            XCTAssertTrue(self.userDefaults[.isMessageSwipeNavigationEnabled])
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1)
    }

}

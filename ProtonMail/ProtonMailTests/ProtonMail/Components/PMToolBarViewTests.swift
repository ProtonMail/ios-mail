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

final class PMToolBarViewTests: XCTestCase {

    var sut: PMToolBarView!
    override func setUp() {
        super.setUp()

        sut = PMToolBarView()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testInit_buttonIsEmpty() {
        XCTAssertTrue(sut.types.isEmpty)
    }

    func testSetupOneAction_oneItemInTheView() throws {
        let expectation1 = expectation(description: "Closure is called")
        let handler: () -> Void = {
            expectation1.fulfill()
        }
        let action = PMToolBarView.ActionItem(type: .delete, handler: handler)

        sut.setUpActions([action])
        let button = try  XCTUnwrap(sut.btnStackView.arrangedSubviews.compactMap{ $0 as? UIButton }.first)
        button.sendActions(for: .touchUpInside)

        XCTAssertEqual(sut.types.count, 1)
        XCTAssertEqual(sut.types, [action.type])

        waitForExpectations(timeout: 1)
    }

//    func testSetupMoreThan5Actions_onlyFirst5ActionsShowOnView() {
//        let actions: [PMToolBarView.ActionItem] = [
//            .init(type: .delete, handler: {}),
//            .init(type: .trash, handler: {}),
//            .init(type: .markAsUnread, handler: {}),
//            .init(type: .labelAs, handler: {}),
//            .init(type: .markAsRead, handler: {}),
//            .init(type: .more, handler: {})
//        ]
//
//        sut.setUpActions(actions)
//
//        XCTAssertEqual(sut.types.count, 5)
//        XCTAssertEqual(sut.types, [.delete, .trash, .markAsUnread, .labelAs, .markAsRead])
//        XCTAssertEqual(
//            sut.btnStackView.arrangedSubviews.compactMap { $0 as? UIButton }.count,
//            5
//        )
//    }
}

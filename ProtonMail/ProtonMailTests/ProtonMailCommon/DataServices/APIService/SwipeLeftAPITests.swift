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

import XCTest
@testable import ProtonMail

final class SwipeLeftAPITests: XCTestCase {
    private let allowedActions: [SwipeActionSettingType] = [.trash, .spam, .starAndUnstar, .archive, .readAndUnread]

    func testInit_withAllowedAction() throws {
        for action in allowedActions {
            let sut = try XCTUnwrap(SwipeLeftRequest(action: action))
            XCTAssertEqual(sut.method, .put)
            XCTAssertEqual(sut.path, "/settings/mail/swipeleft")
            let value = try XCTUnwrap(sut.parameters?["SwipeLeft"] as? Int)
            switch action {
            case .trash:
                XCTAssertEqual(value, 0)
            case .spam:
                XCTAssertEqual(value, 1)
            case .starAndUnstar:
                XCTAssertEqual(value, 2)
            case .archive:
                XCTAssertEqual(value, 3)
            case .readAndUnread:
                XCTAssertEqual(value, 4)
            default:
                XCTFail("Action \(action) cannot be assigned to a swipe gesture")
            }
        }
    }

    func testInit_withNotAllowedAction() {
        let actions = SwipeActionSettingType.allCases
            .filter { !allowedActions.contains($0) }
        for action in actions {
            XCTAssertNil(SwipeLeftRequest(action: action))
        }
    }
}

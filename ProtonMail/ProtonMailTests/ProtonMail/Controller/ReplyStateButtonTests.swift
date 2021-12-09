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

@available(iOS 13.0, *)
final class ReplyStateButtonTests: XCTestCase {
    func testInitializingFromMoreThanOneContactFalseShouldReturnTheReplyCase() {
        let state = HeaderContainerView.ReplyState.from(moreThanOneContact: false)
        XCTAssertEqual(state, .reply)
    }

    func testInitializingFromMoreThanOneContactTrueShouldReturnTheReplyAllCase() {
        let state = HeaderContainerView.ReplyState.from(moreThanOneContact: true)
        XCTAssertEqual(state, .replyAll)
    }

    func testReplyCaseShouldReturnProperImageView() {
        let state: HeaderContainerView.ReplyState = .reply
        let expectedImage = UIImage(named: "reply_button_icon", in: Bundle(for: HeaderContainerView.self), with: nil)
        XCTAssertEqual(state.imageView.image, expectedImage)
    }

    func testReplyAllCaseShouldReturnProperImageView() {
        let state: HeaderContainerView.ReplyState = .replyAll
        let expectedImage = UIImage(named: "reply_all_button_icon", in: Bundle(for: HeaderContainerView.self), with: nil)
        XCTAssertEqual(state.imageView.image, expectedImage)
    }
}

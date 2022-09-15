// Copyright (c) 2021 Proton AG
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
import ProtonCore_UIFoundations
@testable import ProtonMail

@available(iOS 13.0, *)
final class ReplyStateButtonTests: XCTestCase {
    func testInitializingFromMoreThanOneContactFalseShouldReturnTheReplyCase() {
        let state = HeaderContainerView.ReplyState.from(moreThanOneContact: false, isScheduled: false)
        XCTAssertEqual(state, .reply)
    }

    func testInitializingFromMoreThanOneContactTrueShouldReturnTheReplyAllCase() {
        let state = HeaderContainerView.ReplyState.from(moreThanOneContact: true, isScheduled: false)
        XCTAssertEqual(state, .replyAll)
    }

    func testInitializingFromMoreThanOneContactFalseIsScheduledTrue_returnNone() {
        let state = HeaderContainerView.ReplyState.from(moreThanOneContact: false, isScheduled: true)
        XCTAssertEqual(state, .none)
    }

    func testInitializingFromMoreThanOneContactTrueIsScheduledTrue_returnNone() {
        let state = HeaderContainerView.ReplyState.from(moreThanOneContact: true, isScheduled: true)
        XCTAssertEqual(state, .none)
    }

    func testNoneCaseShouldReturnNilImageView() {
        let state: HeaderContainerView.ReplyState = .none
        XCTAssertNil(state.imageView)
    }

    func testReplyState_buttonAccessibilityLabel() {
        XCTAssertEqual(HeaderContainerView.ReplyState.reply.buttonAccessibilityLabel,
                       LocalString._general_reply_button)
        XCTAssertEqual(HeaderContainerView.ReplyState.replyAll.buttonAccessibilityLabel,
                       LocalString._general_replyall_button)
        XCTAssertNil(HeaderContainerView.ReplyState.none.buttonAccessibilityLabel)
    }
}

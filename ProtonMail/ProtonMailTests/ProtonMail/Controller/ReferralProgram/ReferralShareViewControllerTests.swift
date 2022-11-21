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

final class ReferralShareViewControllerTests: XCTestCase {

    let referralLink = "https://pr.tn/ref/XXXXXXX"
    var sut: ReferralShareViewController!

    override func setUp() {
        super.setUp()
        sut = ReferralShareViewController(referralLink: referralLink)
        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testInit_hasTheRightReferralLinkShownInView() {
        XCTAssertEqual(sut.customView.linkTextField.text, referralLink)
    }

    func testClickTrackRewardButton_rightNotificationIsSent() {
        let notificationCenter = NotificationCenter()
        let sut = ReferralShareViewController(referralLink: referralLink, notificationCenter: notificationCenter)
        sut.loadViewIfNeeded()
        let e = XCTNSNotificationExpectation(name: .switchView,
                                             object: nil ,
                                             notificationCenter: notificationCenter)

        // simulate click
        sut.customView.trackRewardButton.sendActions(for: .touchUpInside)

        wait(for: [e], timeout: 1)
    }

    func testClickTermsAndConditionButton_rightNotificationIsSent() {
        let notificationCenter = NotificationCenter()
        let sut = ReferralShareViewController(referralLink: referralLink, notificationCenter: notificationCenter)
        sut.loadViewIfNeeded()
        let e = XCTNSNotificationExpectation(name: .switchView,
                                             object: nil ,
                                             notificationCenter: notificationCenter)

        // simulate click
        sut.customView.termsAndConditionButton.sendActions(for: .touchUpInside)

        wait(for: [e], timeout: 1)
    }
}

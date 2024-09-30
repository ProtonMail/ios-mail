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

import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest

@testable import ProtonMail

final class UpsellButtonStateProviderTests: XCTestCase {
    private var sut: UpsellButtonStateProvider!
    private var testContainer: TestContainer!
    private var featureFlagProvider: MockFeatureFlagProvider!
    private var user: UserManager!
    private var alwaysShowUpsellButton: Bool!
    private var stubbedDate: Date!

    private let testDate: (start: Date, shortlyAfter: Date, longAfter: Date) = (
        .fixture("2021-02-15 12:00:00"),
        .fixture("2021-02-24 12:00:00"),
        .fixture("2021-02-25 12:00:00")
    )

    override func setUpWithError() throws {
        try super.setUpWithError()

        testContainer = .init()
        featureFlagProvider = .init()

        user = UserManager(
            api: APIServiceMock(),
            role: .owner,
            userID: UUID().uuidString, 
            subscribed: [],
            globalContainer: testContainer
        )

        user.container.featureFlagProviderFactory.register { self.featureFlagProvider }

        sut = .init(dependencies: user.container) { [unowned self] in self.stubbedDate }

        alwaysShowUpsellButton = false
        stubbedDate = testDate.start

        featureFlagProvider.isEnabledStub.bodyIs { [unowned self] _, flag in
            switch flag {
            case .alwaysShowUpsellButton:
                return self.alwaysShowUpsellButton
            default:
                return true
            }
        }
    }

    override func tearDownWithError() throws {
        sut = nil
        testContainer = nil
        featureFlagProvider = nil
        user = nil
        alwaysShowUpsellButton = nil
        stubbedDate = nil

        try super.tearDownWithError()
    }

    func testDoesntShowButtonForPaidUsersOfAnyPlan() {
        for subscription in [User.Subscribed.mail, .drive, .vpn] {
            user.userInfo.subscribed = subscription
            XCTAssertFalse(sut.shouldShowUpsellButton)
        }
    }

    func testShowsButtonIfItHasNeverBeenShownBefore() {
        XCTAssert(sut.shouldShowUpsellButton)
    }

    func testDoesntShowButtonShortlyAfterShowingItLastTime() {
        sut.upsellButtonWasTapped()

        stubbedDate = testDate.shortlyAfter

        XCTAssertFalse(sut.shouldShowUpsellButton)
    }

    func testShowsButtonEarlierIfAlwaysShowFeatureFlagIsEnabled() {
        sut.upsellButtonWasTapped()

        alwaysShowUpsellButton = true
        stubbedDate = testDate.shortlyAfter

        XCTAssert(sut.shouldShowUpsellButton)
    }

    func testShowsButtonIfEnoughTimeHasPassedSinceShowingItBefore() {
        sut.upsellButtonWasTapped()

        stubbedDate = testDate.longAfter

        XCTAssert(sut.shouldShowUpsellButton)
    }

    func testStoresDatesSeparatelyForDifferentUsers() {
        let anotherUser = UserManager(
            api: APIServiceMock(),
            role: .owner,
            userID: UUID().uuidString,
            subscribed: [],
            globalContainer: testContainer
        )

        let anotherInstance = UpsellButtonStateProvider(dependencies: anotherUser.container) { [unowned self] in
            self.stubbedDate
        }

        sut.upsellButtonWasTapped()

        stubbedDate = testDate.shortlyAfter

        XCTAssert(anotherInstance.shouldShowUpsellButton)
    }
}

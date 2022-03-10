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
import ProtonCore_TestingToolkit

class MenuViewModelTests: XCTestCase {
    var sut: MenuViewModel!
    var usersManagerMock: UsersManager!
    var userStatusInQueueProviderMock: UserStatusInQueueProviderMock!
    var coreDataContextProviderMock: MockCoreDataContextProvider!
    var dohMock: DohMock!
    var testUser: UserManager!
    var apiMock: APIServiceMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        userStatusInQueueProviderMock = UserStatusInQueueProviderMock()
        coreDataContextProviderMock = MockCoreDataContextProvider()
        dohMock = DohMock()
        usersManagerMock = UsersManager(doh: dohMock, delegate: nil)
        apiMock = APIServiceMock()
        testUser = UserManager(api: apiMock, role: .none)
        usersManagerMock.add(newUser: testUser)
        sut = MenuViewModel(usersManager: usersManagerMock,
                            userStatusInQueueProvider: userStatusInQueueProviderMock,
                            coreDataContextProvider: coreDataContextProviderMock)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        usersManagerMock = nil
        userStatusInQueueProviderMock = nil
        coreDataContextProviderMock = nil
        testUser = nil
        dohMock = nil
        apiMock = nil
    }

    func testInit_withInAppFeedbackDisable() {
        XCTAssertEqual(sut.sections, [.inboxes, .folders, .labels, .more])
        XCTAssertTrue(sut.moreItems.contains(where: { $0.location == .provideFeedback }))
    }

    func testInit_withInAppFeedbackEnable() {
        testUser.inAppFeedbackStateService.handleNewFeatureFlags([FeatureFlagKey.inAppFeedback.rawValue: 1])
        sut = MenuViewModel(usersManager: usersManagerMock,
                            userStatusInQueueProvider: userStatusInQueueProviderMock,
                            coreDataContextProvider: coreDataContextProviderMock)
        XCTAssertEqual(sut.sections, [.inboxes, .folders, .labels, .more])

        XCTAssertTrue(sut.moreItems.contains(where: { $0.location == .provideFeedback }))
    }

    func testInboxItemsAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .inbox),
                             MenuLabel(location: .draft),
                             MenuLabel(location: .sent),
                             MenuLabel(location: .starred),
                             MenuLabel(location: .archive),
                             MenuLabel(location: .spam),
                             MenuLabel(location: .trash),
                             MenuLabel(location: .allmail)]
        XCTAssert(MenuViewModel.inboxItems().map(\.location) == expectedItems.map(\.location))
    }

    func testDefaultMoreItemsAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .provideFeedback),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let baseInfo = MenuViewModel.MoreItemsInfo(userIsMember: nil,
                                                   subscriptionAvailable: true,
                                                   isPinCodeEnabled: true,
                                                   isTouchIDEnabled: true)
        XCTAssert(MenuViewModel.moreItems(for: baseInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsForMemberUserAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .provideFeedback),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: true,
                                                   subscriptionAvailable: true,
                                                   isPinCodeEnabled: true,
                                                   isTouchIDEnabled: true)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsForNonMemberUserAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .subscription),
                             MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .provideFeedback),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: false,
                                                   subscriptionAvailable: true,
                                                   isPinCodeEnabled: true,
                                                   isTouchIDEnabled: true)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsForNonMemberWithUnavailableSubscriptionAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .provideFeedback),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: false,
                                                   subscriptionAvailable: false,
                                                   isPinCodeEnabled: true,
                                                   isTouchIDEnabled: true)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsWithDisabledPINCodeAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .provideFeedback),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: false,
                                                   subscriptionAvailable: false,
                                                   isPinCodeEnabled: false,
                                                   isTouchIDEnabled: true)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsWithDisabledTouchIDAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .provideFeedback),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: false,
                                                   subscriptionAvailable: false,
                                                   isPinCodeEnabled: true,
                                                   isTouchIDEnabled: false)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsWithDisabledPINCodeAndTouchIDAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .provideFeedback),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: false,
                                                   subscriptionAvailable: false,
                                                   isPinCodeEnabled: false,
                                                   isTouchIDEnabled: false)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }
}

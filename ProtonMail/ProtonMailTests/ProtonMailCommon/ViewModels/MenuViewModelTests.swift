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
@testable import ProtonMail
import ProtonCore_TestingToolkit
import ProtonCore_UIFoundations

class MenuViewModelTests: XCTestCase {
    var sut: MenuViewModel!
    var usersManagerMock: UsersManager!
    var userStatusInQueueProviderMock: UserStatusInQueueProviderMock!
    var coreDataContextProviderMock: MockCoreDataContextProvider!
    var dohMock: DohMock!
    var testUser: UserManager!
    var apiMock: APIServiceMock!
    var enableColorStub = false
    var usingParentFolderColorStub = false

    override func setUpWithError() throws {
        try super.setUpWithError()
        userStatusInQueueProviderMock = UserStatusInQueueProviderMock()
        coreDataContextProviderMock = MockCoreDataContextProvider()
        dohMock = DohMock()
        usersManagerMock = UsersManager(doh: dohMock, delegate: nil)
        apiMock = APIServiceMock()
        testUser = UserManager(api: apiMock, role: .none)
        usersManagerMock.add(newUser: testUser)
        sut = MenuViewModel(
            usersManager: usersManagerMock,
            userStatusInQueueProvider: userStatusInQueueProviderMock,
            coreDataContextProvider: coreDataContextProviderMock)
        sut.setUserEnableColorClosure {
            return self.enableColorStub
        }
        sut.setParentFolderColorClosure {
            return self.usingParentFolderColorStub
        }
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

    func testGetIconColor_fromLabelWithoutCustomIconColor_getDefaultColor() {
        let label = MenuLabel(id: "",
                              name: "",
                              parentID: nil,
                              path: "",
                              textColor: nil,
                              iconColor: nil,
                              type: 1,
                              order: 0,
                              notify: false)
        XCTAssertEqual(sut.getIconColor(of: label), ColorProvider.SidebarIconWeak)
    }

    @available(iOS 13.0, *)
    func testGetIconColor_fromLabelWithoutCustomIconColor_withLabelSelected_getSelectedDefaultColor() {
        let label = MenuLabel(id: "",
                              name: "",
                              parentID: nil,
                              path: "",
                              textColor: nil,
                              iconColor: nil,
                              type: 1,
                              order: 0,
                              notify: false)
        label.isSelected = true
        XCTAssertEqual(sut.getIconColor(of: label),
                       ColorProvider.SidebarIconWeak
            .resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)))
    }

    func testGetIconColor_fromLabelWithCustomIconColor_getCustomColor() {
        let color = "#303239"
        let label = MenuLabel(id: "",
                              name: "",
                              parentID: nil,
                              path: "",
                              textColor: nil,
                              iconColor: color,
                              type: 1,
                              order: 0,
                              notify: false)
        XCTAssertEqual(sut.getIconColor(of: label), UIColor(hexColorCode: color))
    }

    @available(iOS 13.0, *)
    func testGetIconColor_fromLabelWithCustomIconColor_withLabelSelected_getCustomColor() {
        let color = "#303239"
        let label = MenuLabel(id: "",
                              name: "",
                              parentID: nil,
                              path: "",
                              textColor: nil,
                              iconColor: color,
                              type: 1,
                              order: 0,
                              notify: false)
        label.isSelected = true
        XCTAssertEqual(sut.getIconColor(of: label), UIColor(hexColorCode: color))
    }

    func testGetIconColor_fromFolder_userDisableColor_getDefaultColor() {
        self.enableColorStub = false
        let folder = MenuLabel(id: "",
                               name: "",
                               parentID: nil,
                               path: "",
                               textColor: nil,
                               iconColor: nil,
                               type: 3,
                               order: 0,
                               notify: false)
        XCTAssertEqual(sut.getIconColor(of: folder), ColorProvider.SidebarIconWeak)
    }

    func testGetIconColor_fromFolderWithCustomColor_userDisableColor_getDefaultColor() {
        self.enableColorStub = false
        let folder = MenuLabel(id: "",
                               name: "",
                               parentID: nil,
                               path: "",
                               textColor: nil,
                               iconColor: "#303239",
                               type: 3,
                               order: 0,
                               notify: false)
        XCTAssertEqual(sut.getIconColor(of: folder), ColorProvider.SidebarIconWeak)
    }

    func testGetIconColor_fromFolder_userEnableColor_notUsingParentFolderColor_getDefaultColor() {
        self.enableColorStub = true
        self.usingParentFolderColorStub = false
        let folder = MenuLabel(id: "",
                               name: "",
                               parentID: nil,
                               path: "",
                               textColor: nil,
                               iconColor: nil,
                               type: 3,
                               order: 0,
                               notify: false)
        XCTAssertEqual(sut.getIconColor(of: folder), ColorProvider.SidebarIconWeak)
    }

    func testGetIconColor_fromFolderWithCustomColor_userEnableColor_notUsingParentFolderColor_getDefaultColor() {
        self.enableColorStub = true
        self.usingParentFolderColorStub = false
        let folder = MenuLabel(id: "",
                               name: "",
                               parentID: nil,
                               path: "",
                               textColor: nil,
                               iconColor: "#303239",
                               type: 3,
                               order: 0,
                               notify: false)
        XCTAssertEqual(sut.getIconColor(of: folder), UIColor(hexColorCode: "#303239"))
    }

    func testGetIconColor_fromFolderWithoutParent_userEnableColorAndParentFolderColor_getDefaultColor() {
        self.enableColorStub = true
        self.usingParentFolderColorStub = true
        let folder = MenuLabel(id: "",
                               name: "",
                               parentID: nil,
                               path: "",
                               textColor: nil,
                               iconColor: nil,
                               type: 3,
                               order: 0,
                               notify: false)
        XCTAssertEqual(sut.getIconColor(of: folder), ColorProvider.SidebarIconWeak)
    }

    func testGetIconColor_fromFolderWithParent_userEnableColorAndParentFolderColor_getParentColor() {
        self.enableColorStub = true
        self.usingParentFolderColorStub = true
        let parent = MenuLabel(id: "1",
                               name: "",
                               parentID: nil,
                               path: "",
                               textColor: nil,
                               iconColor: "#303239",
                               type: 3,
                               order: 0,
                               notify: false)
        let folder = MenuLabel(id: "2",
                               name: "",
                               parentID: "1",
                               path: "",
                               textColor: nil,
                               iconColor: nil,
                               type: 3,
                               order: 0,
                               notify: false)
        parent.subLabels = [folder]
        sut.setFolderItem([parent])

        XCTAssertEqual(sut.getIconColor(of: folder), UIColor(hexColorCode: "#303239"))
    }

    func testGetIconColor_fromFolderWithParentWithoutCustomColor_userEnableColorAndParentFolderColor_getDefaultColor() {
        self.enableColorStub = true
        self.usingParentFolderColorStub = true
        let parent = MenuLabel(id: "1",
                               name: "",
                               parentID: nil,
                               path: "",
                               textColor: nil,
                               iconColor: nil,
                               type: 3,
                               order: 0,
                               notify: false)
        let folder = MenuLabel(id: "2",
                               name: "",
                               parentID: "1",
                               path: "",
                               textColor: nil,
                               iconColor: nil,
                               type: 3,
                               order: 0,
                               notify: false)
        parent.subLabels = [folder]
        sut.setFolderItem([parent])

        XCTAssertEqual(sut.getIconColor(of: folder), ColorProvider.SidebarIconWeak)
    }
}

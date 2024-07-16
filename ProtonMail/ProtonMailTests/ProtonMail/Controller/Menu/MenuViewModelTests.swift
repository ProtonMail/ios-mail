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
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonCoreUIFoundations

class MenuViewModelTests: XCTestCase {
    var sut: MenuViewModel!
    var testUser: UserManager!
    var enableColorStub = false
    var usingParentFolderColorStub = false
    var coordinatorMock: MockMenuCoordinatorProtocol!
    var delegate: MenuUIProtocol!

    override func setUpWithError() throws {
        try super.setUpWithError()
        coordinatorMock = .init()
        let apiMock = APIServiceMock()
        testUser = UserManager(api: apiMock)
        let globalContainer = GlobalContainer()
        globalContainer.usersManager.add(newUser: testUser)
        sut = MenuViewModel(dependencies: globalContainer)
        sut.setUserEnableColorClosure {
            return self.enableColorStub
        }
        sut.setParentFolderColorClosure {
            return self.usingParentFolderColorStub
        }
        sut.coordinator = coordinatorMock
        delegate = TestViewController()
        sut.set(delegate: delegate)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        testUser = nil
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
        XCTAssertEqual(
            MenuViewModel.inboxItems(almostAllMailIsOn: false)
                .map(\.location),
            expectedItems.map(\.location)
        )
    }

    func testDefaultMoreItemsAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let baseInfo = MenuViewModel.MoreItemsInfo(userIsMember: nil,
                                                   isPinCodeEnabled: true,
                                                   isTouchIDEnabled: true,
                                                   isReferralEligible: false)
        XCTAssert(MenuViewModel.moreItems(for: baseInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsForMemberUserAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: true,
                                                   isPinCodeEnabled: true,
                                                   isTouchIDEnabled: true,
                                                   isReferralEligible: false)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsForNonMemberUserAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .subscription),
                             MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: false,
                                                   isPinCodeEnabled: true,
                                                   isTouchIDEnabled: true,
                                                   isReferralEligible: false)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsWithDisabledPINCodeAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .subscription),
                             MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: false,
                                                   isPinCodeEnabled: false,
                                                   isTouchIDEnabled: true,
                                                   isReferralEligible: false)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsWithDisabledTouchIDAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .subscription),
                             MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .lockapp),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: false,
                                                   isPinCodeEnabled: true,
                                                   isTouchIDEnabled: false,
                                                   isReferralEligible: false)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItemsWithDisabledPINCodeAndTouchIDAreTheExpectedOnes() {
        let expectedItems = [MenuLabel(location: .subscription),
                             MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: false,
                                                   isPinCodeEnabled: false,
                                                   isTouchIDEnabled: false,
                                                   isReferralEligible: false)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testMoreItems_withReferralEligibleTrue_containsReferAFriend() {
        let expectedItems = [MenuLabel(location: .subscription),
                             MenuLabel(location: .settings),
                             MenuLabel(location: .contacts),
                             MenuLabel(location: .bugs),
                             MenuLabel(location: .referAFriend),
                             MenuLabel(location: .signout)]
        let moreInfo = MenuViewModel.MoreItemsInfo(userIsMember: false,
                                                   isPinCodeEnabled: false,
                                                   isTouchIDEnabled: false,
                                                   isReferralEligible: true)
        XCTAssert(MenuViewModel.moreItems(for: moreInfo).map(\.location) == expectedItems.map(\.location))
    }

    func testUpdateInboxItem_oneScheduledMsg_scheduleLocationInInboxItems() {
        let expectation1 = expectation(description: "Closure is called")
        sut.reloadClosure = {
            expectation1.fulfill()
        }
        sut.updateInboxItems(hasScheduledMessage: true)
        XCTAssertTrue(sut.inboxItems.contains(where: { $0.location == .scheduled }))
        waitForExpectations(timeout: 1, handler: nil)

        let expected = [
            MenuLabel(location: .inbox),
            MenuLabel(location: .draft),
            MenuLabel(location: .scheduled),
            MenuLabel(location: .sent),
            MenuLabel(location: .starred),
            MenuLabel(location: .archive),
            MenuLabel(location: .spam),
            MenuLabel(location: .trash),
            MenuLabel(location: .allmail)
        ].map { $0.location }
        XCTAssertEqual(sut.inboxItems.map { $0.location }, expected)
    }

    func testUpdateInboxItem_0ScheduledMsg_inboxItemsDoNotHaveScheduledLocation() {
        XCTAssertFalse(sut.inboxItems.contains(where: { $0.location == .scheduled }))

        let expected = [
            MenuLabel(location: .inbox),
            MenuLabel(location: .draft),
            MenuLabel(location: .sent),
            MenuLabel(location: .starred),
            MenuLabel(location: .archive),
            MenuLabel(location: .spam),
            MenuLabel(location: .trash),
            MenuLabel(location: .allmail)
        ].map { $0.location }
        XCTAssertEqual(sut.inboxItems.map { $0.location }, expected)
    }

    func testUpdateInboxItem_almostAllMailIsFalse_inboxItemHasAllMailLocation() {
        testUser.mailSettings.update(key: .almostAllMail, to: false)
        sut.updateInboxItems(hasScheduledMessage: false)

        let expected = [
            MenuLabel(location: .inbox),
            MenuLabel(location: .draft),
            MenuLabel(location: .sent),
            MenuLabel(location: .starred),
            MenuLabel(location: .archive),
            MenuLabel(location: .spam),
            MenuLabel(location: .trash),
            MenuLabel(location: .allmail)
        ].map { $0.location }
        XCTAssertEqual(sut.inboxItems.map { $0.location }, expected)
    }

    func testUpdateInboxItem_almostAllMailIsTrue_inboxItemHasAlmostAllMailLocation() {
        testUser.mailSettings.update(key: .almostAllMail, to: true)
        sut.updateInboxItems(isAlmostAllMailOn: true)

        let expected = [
            MenuLabel(location: .inbox),
            MenuLabel(location: .draft),
            MenuLabel(location: .sent),
            MenuLabel(location: .starred),
            MenuLabel(location: .archive),
            MenuLabel(location: .spam),
            MenuLabel(location: .trash),
            MenuLabel(location: .almostAllMail)
        ].map { $0.location }
        XCTAssertEqual(sut.inboxItems.map { $0.location }, expected)
    }

    func testUpdateInboxItem_almostAllMailSettingUpdated_inboxItemWillBeUpdated() {
        testUser.mailSettings.update(key: .almostAllMail, to: false)
        sut.userDataInit()

        let expected = [
            MenuLabel(location: .inbox),
            MenuLabel(location: .draft),
            MenuLabel(location: .sent),
            MenuLabel(location: .starred),
            MenuLabel(location: .archive),
            MenuLabel(location: .spam),
            MenuLabel(location: .trash),
            MenuLabel(location: .allmail)
        ].map { $0.location }
        XCTAssertEqual(sut.inboxItems.map { $0.location }, expected)

        var newSettings = testUser.mailSettings
        newSettings.update(key: .almostAllMail, to: true)
        testUser.mailSettings = newSettings

        wait(self.sut.inboxItems.contains(where: { $0.location == .almostAllMail }))
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

    func testGo_selectSameLocation_shouldNotCallGoFunctionOfCoordinator() {
        sut.activateUser(id: testUser.userID)
        // select inbox location
        sut.highlight(label: .init(location: .inbox))

        sut.go(to: .init(location: .inbox))

        XCTAssertTrue(coordinatorMock.closeMenuStub.wasCalledExactlyOnce)
        XCTAssertTrue(coordinatorMock.goStub.wasNotCalled)
    }

    func testGo_selectDifferentLocation_shouldCallGoFunctionOfCoordinator() throws {
        // select inbox location
        sut.highlight(label: .init(location: .inbox))

        sut.go(to: .init(location: .archive))

        XCTAssertTrue(coordinatorMock.closeMenuStub.wasNotCalled)
        XCTAssertTrue(coordinatorMock.goStub.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(
            coordinatorMock.goStub.lastArguments?.a1
        )
        XCTAssertEqual(argument.location, .archive)
    }

    func testGo_currentUserIDIsDifferentFromCurrentUser_shouldCallGoFunctionOfCoordinator() throws {
        let userID = UserID(String.randomString(20))
        // set currentUserID
        sut.activateUser(id: userID)

        sut.go(to: .init(location: .archive))

        XCTAssertTrue(coordinatorMock.goStub.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(
            coordinatorMock.goStub.lastArguments?.a1
        )
        XCTAssertEqual(argument.location, .archive)
    }

    func testIsStorageAlertVisible_whenStorage80orLess_andFreeUser_itShouldBeFalse() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 80
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.subscribed = .init(rawValue: 0)

            XCTAssertEqual(sut.storageAlertVisibility, .hidden)
        }
    }

    func testIsStorageAlertVisible_whenMailStorageAbove80_andFreeUser_itShouldBeTrue() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 100
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.usedDriveSpace = 0
            testUser.userInfo.maxDriveSpace = 100
            testUser.userInfo.subscribed = .init(rawValue: 0)

            XCTAssertEqual(sut.storageAlertVisibility, .mail(1))
        }
    }

    func testIsStorageAlertVisible_whenDriveStorageAbove80_andFreeUser_itShouldBeTrue() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 0
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.usedDriveSpace = 100
            testUser.userInfo.maxDriveSpace = 100
            testUser.userInfo.subscribed = .init(rawValue: 0)

            XCTAssertEqual(sut.storageAlertVisibility, .drive(1))
        }
    }

    func testIsStorageAlertVisible_whenBothStorageAbove80_andFreeUser_itShouldBeTrue() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 100
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.usedDriveSpace = 100
            testUser.userInfo.maxDriveSpace = 100
            testUser.userInfo.subscribed = .init(rawValue: 0)

            XCTAssertEqual(sut.storageAlertVisibility, .mail(1))
        }
    }

    func testIsStorageAlertVisible_whenStorage80orLess_andPayingUser_itShouldBeFalse() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 80
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.usedDriveSpace = 80
            testUser.userInfo.maxDriveSpace = 100
            testUser.userInfo.subscribed = .mail

            XCTAssertEqual(sut.storageAlertVisibility, .hidden)
        }
    }

    func testIsStorageAlertVisible_whenStorageAbove80_andPayingUser_itShouldBeFalse() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 100
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.subscribed = .mail

            XCTAssertEqual(sut.storageAlertVisibility, .hidden)
        }
    }
}

class TestViewController: UIViewController, MenuUIProtocol {
    func update(email: String) {}

    func update(displayName: String) {}

    func update(avatar: String) {}

    func showToast(message: String) {}

    func updateMenu(section: Int?) {}

    func update(rows: [IndexPath], insertRows: [IndexPath], deleteRows: [IndexPath]) {}

    func navigateTo(label: ProtonMail.MenuLabel) {}
}

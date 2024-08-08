// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class MenuViewControllerTests: XCTestCase {
    private var testContainer: TestContainer!
    private var sut: MenuViewController!
    private var viewModel: MenuViewModel!
    private var testUser: UserManager!
    private var apiMock: APIServiceMock!

    override func setUpWithError() throws {
        try super.setUpWithError()

        testContainer = .init()
        try setupUser()
        viewModel = .init(dependencies: testContainer)
        sut = .init(viewModel: viewModel)
        viewModel.set(delegate: sut)
        viewModel.set(menuWidth: 300)
        sut.loadViewIfNeeded()
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        viewModel = nil
        testContainer = nil
    }

    func testInit_hasNoMessageInSnoozeAndScheduleSend_noSnoozeAndScheduleSendLocationInMenu() throws {
        viewModel.userDataInit()

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [MenuItemTableViewCell])
        XCTAssertFalse(cells.isEmpty)
        let labelIDs = cells.map(\.labelID.rawValue)
        XCTAssertFalse(labelIDs.contains(Message.Location.snooze.rawValue))
        XCTAssertFalse(labelIDs.contains(Message.Location.scheduled.rawValue))
    }

    func testInit_hasSnoozedMessage_snoozeLocationIsShownInMenu() throws {
        try testContainer.contextProvider.write { context in
            let label = Label(context: context)
            label.labelID = Message.Location.snooze.rawValue
            let messageInSnoozed = Message(context: context)
            messageInSnoozed.userID = self.testUser.userID.rawValue
            messageInSnoozed.messageStatus = .init(value: 1)
            messageInSnoozed.add(labelID: Message.Location.snooze.rawValue)
            messageInSnoozed.isSoftDeleted = false
        }

        viewModel.userDataInit()

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [MenuItemTableViewCell])
        XCTAssertFalse(cells.isEmpty)
        let labelIDs = cells.map(\.labelID.rawValue)
        XCTAssertTrue(labelIDs.contains(Message.Location.snooze.rawValue))
    }

    func testInit_hasSnoozedConversationCount_snoozeLocationIsShownInMenu() throws {
        try testContainer.contextProvider.write { context in
            let count = ConversationCount(context: context)
            count.userID = self.testUser.userID.rawValue
            count.labelID = Message.Location.snooze.rawValue
            count.total = Int32(1)
        }

        viewModel.userDataInit()

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [MenuItemTableViewCell])
        XCTAssertFalse(cells.isEmpty)
        let labelIDs = cells.map(\.labelID.rawValue)
        XCTAssertTrue(labelIDs.contains(Message.Location.snooze.rawValue))
    }

    func testInit_hasSnoozedMessageCount_snoozeLocationIsShownInMenu() throws {
        try testContainer.contextProvider.write { context in
            let count = LabelUpdate(context: context)
            count.userID = self.testUser.userID.rawValue
            count.labelID = Message.Location.snooze.rawValue
            count.total = Int32(1)
        }

        viewModel.userDataInit()

        let labelIDs = try XCTUnwrap(
            sut.tableView.visibleCells as? [MenuItemTableViewCell]
        ).map(\.labelID.rawValue)
        XCTAssertTrue(labelIDs.contains(Message.Location.snooze.rawValue))
    }

    func testObservation_receiveSnoozeMessageAfterInit_snoozeLocationWillBeShown() throws {
        viewModel.userDataInit()

        let labelIDs = try XCTUnwrap(
            sut.tableView.visibleCells as? [MenuItemTableViewCell]
        ).map(\.labelID.rawValue)
        XCTAssertFalse(labelIDs.contains(Message.Location.snooze.rawValue))

        // Simulate receiving new snoozed message
        try testContainer.contextProvider.write { context in
            let count = LabelUpdate(context: context)
            count.userID = self.testUser.userID.rawValue
            count.labelID = Message.Location.snooze.rawValue
            count.total = Int32(1)
        }

        wait(
            ((self.sut.tableView.visibleCells as? [MenuItemTableViewCell]) ?? [])
                .map(\.labelID.rawValue)
                .contains(Message.Location.snooze.rawValue) == true
        )
    }

    func testInit_hasScheduledSendMessage_scheduledSendLocationIsShownInMenu() throws {
        try testContainer.contextProvider.write { context in
            let label = Label(context: context)
            label.labelID = Message.Location.scheduled.rawValue
            let messageInSnoozed = Message(context: context)
            messageInSnoozed.userID = self.testUser.userID.rawValue
            messageInSnoozed.messageStatus = .init(value: 1)
            messageInSnoozed.add(labelID: Message.Location.scheduled.rawValue)
            messageInSnoozed.isSoftDeleted = false
        }

        viewModel.userDataInit()

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [MenuItemTableViewCell])
        XCTAssertFalse(cells.isEmpty)
        let labelIDs = cells.map(\.labelID.rawValue)
        XCTAssertTrue(labelIDs.contains(Message.Location.scheduled.rawValue))
    }

    func testInit_hasScheduleSendConversationCount_scheduleSendLocationIsShownInMenu() throws {
        try testContainer.contextProvider.write { context in
            let count = ConversationCount(context: context)
            count.userID = self.testUser.userID.rawValue
            count.labelID = Message.Location.scheduled.rawValue
            count.total = Int32(1)
        }

        viewModel.userDataInit()

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [MenuItemTableViewCell])
        XCTAssertFalse(cells.isEmpty)
        let labelIDs = cells.map(\.labelID.rawValue)
        XCTAssertTrue(labelIDs.contains(Message.Location.scheduled.rawValue))
    }

    func testInit_hasScheduledSendMessageCount_scheduleSendLocationIsShownInMenu() throws {
        try testContainer.contextProvider.write { context in
            let count = LabelUpdate(context: context)
            count.userID = self.testUser.userID.rawValue
            count.labelID = Message.Location.scheduled.rawValue
            count.total = Int32(1)
        }

        viewModel.userDataInit()

        let labelIDs = try XCTUnwrap(
            sut.tableView.visibleCells as? [MenuItemTableViewCell]
        ).map(\.labelID.rawValue)
        XCTAssertTrue(labelIDs.contains(Message.Location.scheduled.rawValue))
    }

    func testObservation_receiveScheduleSendMessageAfterInit_scheduleSendLocationWillBeShown() throws {
        viewModel.userDataInit()

        let labelIDs = try XCTUnwrap(
            sut.tableView.visibleCells as? [MenuItemTableViewCell]
        ).map(\.labelID.rawValue)
        XCTAssertFalse(labelIDs.contains(Message.Location.scheduled.rawValue))

        // Simulate receiving new snoozed message
        try testContainer.contextProvider.write { context in
            let count = LabelUpdate(context: context)
            count.userID = self.testUser.userID.rawValue
            count.labelID = Message.Location.scheduled.rawValue
            count.total = Int32(1)
        }

        wait(
            ((self.sut.tableView.visibleCells as? [MenuItemTableViewCell]) ?? [])
                .map(\.labelID.rawValue)
                .contains(Message.Location.scheduled.rawValue) == true
        )
    }

    func testMenuBadgeIsVisible_whenStorage80orLess_andFreeUser_itShouldBeFalse() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 80
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.usedDriveSpace = 80
            testUser.userInfo.maxDriveSpace = 100
            testUser.userInfo.subscribed = .init(rawValue: 0)

            XCTAssertFalse(sut.isMenuBadgeVisible(userInfo: testUser.userInfo))
        }
    }

    func testMenuBadgeIsVisible_whenMailStorageAbove80_andFreeUser_itShouldBeTrue() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 100
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.usedDriveSpace = 0
            testUser.userInfo.maxDriveSpace = 100
            testUser.userInfo.subscribed = .vpn

            XCTAssertTrue(sut.isMenuBadgeVisible(userInfo: testUser.userInfo))
        }
    }

    func testMenuBadgeIsVisible_whenDriveStorageAbove80_andFreeUser_itShouldBeTrue() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 0
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.usedDriveSpace = 100
            testUser.userInfo.maxDriveSpace = 100
            testUser.userInfo.subscribed = .init(rawValue: 0)

            XCTAssertTrue(sut.isMenuBadgeVisible(userInfo: testUser.userInfo))
        }
    }

    func testMenuBadgeIsVisible_whenMailStorage80orLess_andPayingUser_itShouldBeFalse() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 80
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.usedDriveSpace = 80
            testUser.userInfo.maxDriveSpace = 100
            testUser.userInfo.subscribed = .mail

            XCTAssertFalse(sut.isMenuBadgeVisible(userInfo: testUser.userInfo))
        }
    }

    func testMenuBadgeIsVisible_whenMailStorageAbove80_andPayingUser_itShouldBeFalse() {
        withFeatureFlags([.splitStorage]) {
            testUser.userInfo.usedBaseSpace = 100
            testUser.userInfo.maxBaseSpace = 100
            testUser.userInfo.usedDriveSpace = 100
            testUser.userInfo.maxDriveSpace = 100
            testUser.userInfo.subscribed = .mail

            XCTAssertFalse(sut.isMenuBadgeVisible(userInfo: testUser.userInfo))
        }
    }
}

extension MenuViewControllerTests {
    private func setupUser() throws {
        apiMock = .init()
        testUser = try UserManager.prepareUser(apiMock: apiMock, globalContainer: testContainer)
        testContainer.usersManager.add(newUser: testUser)
    }
}

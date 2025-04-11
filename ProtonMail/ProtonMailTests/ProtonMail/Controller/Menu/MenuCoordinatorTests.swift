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

import ProtonCoreTestingToolkitUnitTestsServices
@testable import ProtonMail
import XCTest

final class MenuCoordinatorTests: XCTestCase {
    var testContainer: TestContainer!
    var user: UserManager!
    var apiMock: APIServiceMock!
    var sut: MenuCoordinator!

    override func setUpWithError() throws {
        try super.setUpWithError()
        testContainer = .init()
        apiMock = .init()
        user = try UserManager.prepareUser(apiMock: apiMock, globalContainer: testContainer)
        user.userInfo.groupingMode = 0
        testContainer.usersManager.add(newUser: user)
        sut = .init(
            dependencies: testContainer,
            sideMenu: PMSideMenuController(),
            menuWidth: 300
        )
        apiMock.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success([:]))
        }
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        user = nil
        apiMock = nil
        testContainer = nil
    }

    func testFollow_notificationDeepLink_folderIsSwitchedCorrectly() throws {
        let msgID = MessageID(String.randomString(20))
        let targetLabelID = LabelID("Vg_DqN6s-xg488vZQBkiNGz0U-62GKN6jMYRnloXY-isM9s5ZR-rWCs_w8k9Dtcc-sVC-qnf8w301Q-1sA6dyw==")
        try prepareTestData(msgID: msgID, targetLabelID: targetLabelID)
        sut.go(to: .init(location: .inbox))
        sut.mailboxCoordinator?.viewController?.loadViewIfNeeded()
        let mailboxVC = try getMailboxVC(from: sut)
        // simulate unread filter is on
        mailboxVC.unreadMessageFilterButtonTapped()
        XCTAssertTrue(mailboxVC.unreadFilterButton.isSelected)

        // Create test deeplink
        let link = DeepLink(MenuCoordinator.Setup.switchUserFromNotification.rawValue, sender: user.authCredential.sessionID)
        link.append(.init(name: MenuCoordinator.Setup.switchFolderFromNotification.rawValue, value: msgID.rawValue))
        link.append(.init(name: MailboxCoordinator.Destination.details.rawValue, value: msgID.rawValue))

        // simulate opening notification
        sut.follow(link)

        wait(self.sut.currentLocation?.location.labelID.rawValue == targetLabelID.rawValue)
        let mailboxVC2 = try getMailboxVC(from: sut)
        mailboxVC2.loadViewIfNeeded()
        wait(mailboxVC2.unreadFilterButton.isSelected == false)
        XCTAssertEqual(mailboxVC2.viewModel.labelID, targetLabelID)
    }

    func testFollow_notificationDeepLink_inSameFolder_withUnreadFilterOn_unreadFilterWillBeDeselected() throws {
        let msgID = MessageID(String.randomString(20))
        let targetLabelID = LabelID("0")
        try prepareTestData(msgID: msgID, targetLabelID: targetLabelID)
        sut.go(to: .init(location: .inbox))
        sut.mailboxCoordinator?.viewController?.loadViewIfNeeded()
        let mailboxVC = try getMailboxVC(from: sut)
        // simulate unread filter is on
        mailboxVC.unreadMessageFilterButtonTapped()
        XCTAssertTrue(mailboxVC.unreadFilterButton.isSelected)

        // Create test deeplink
        let link = DeepLink(MenuCoordinator.Setup.switchUserFromNotification.rawValue, sender: user.authCredential.sessionID)
        link.append(.init(name: MenuCoordinator.Setup.switchFolderFromNotification.rawValue, value: msgID.rawValue))

        // simulate opening notification
        sut.follow(link)

        wait(self.sut.currentLocation?.location.labelID.rawValue == targetLabelID.rawValue)
        let mailboxVC2 = try getMailboxVC(from: sut)
        wait(mailboxVC2.unreadFilterButton.isSelected == false)
    }

    func testFollow_shortCutStarDeepLink_folderIsSwitchedCorrectly() throws {
        let deepLink = SpringboardShortcutsService.QuickActions.favorites.deeplink
        _ = deepLink.popFirst
        sut.follow(deepLink)

        wait(self.sut.currentLocation?.location.labelID == Message.Location.starred.labelID)
    }

    private func getMailboxVC(from sut: MenuCoordinator) throws -> MailboxViewController {
        sut.mailboxCoordinator?.viewController?.shouldAnimateSkeletonLoading = false
        return try XCTUnwrap(sut.mailboxCoordinator?.viewController)
    }

    private func prepareTestData(msgID: MessageID, targetLabelID: LabelID) throws {
        _ = try testContainer.contextProvider.write { context in
            TestDataCreator.mockMessage(
                messageID: msgID,
                conversationID: nil,
                in: [
                    .init(targetLabelID.rawValue)
                ],
                labelIDType: .folder,
                userID: self.user.userID,
                context: context
            )
        }
        let messageData = Data(
            MessageTestData.messageMetaData(
                sender: "foo",
                recipient: "bar",
                messageID: msgID.rawValue,
                folderLabelID: "Vg_DqN6s-xg488vZQBkiNGz0U-62GKN6jMYRnloXY-isM9s5ZR-rWCs_w8k9Dtcc-sVC-qnf8w301Q-1sA6dyw=="
            ).utf8
        )
        let messageJSON = try JSONSerialization.jsonObject(with: messageData)
        apiMock.requestJSONStub.bodyIs { _, _, _, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success(["Message": messageJSON]))
        }
    }
}

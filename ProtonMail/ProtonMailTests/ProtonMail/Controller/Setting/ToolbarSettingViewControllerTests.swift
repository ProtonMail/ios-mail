// Copyright (c) 2022 Proton AG
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
@testable import ProtonMail
import XCTest
import ProtonCoreTestingToolkitUnitTestsServices

final class ToolbarSettingViewControllerTests: XCTestCase {
    var sut: ToolbarSettingViewController!
    var mockUser: UserManager!

    override func setUp() {
        super.setUp()
        let mockApiService = APIServiceMock()
        mockUser = UserManager(api: mockApiService)
        makeSUT()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockUser = nil
    }

    func testInit_hasTwoSegment_firstOneIsSelected() {
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.customView.segmentControl.numberOfSegments, 2)
        XCTAssertEqual(sut.customView.segmentControl.selectedSegmentIndex, 0)
    }

    func testSwitchSegmentControl() throws {
        sut.loadViewIfNeeded()

        let label = try XCTUnwrap(sut.customView.infoBubbleView
            .subviews.compactMap { $0 as? UILabel }.first)
        XCTAssertEqual(label.attributedText?.string, LocalString._toolbar_setting_info_title_message)

        // Switch segment control
        sut.customView.segmentControl.selectedSegmentIndex = 1
        sut.customView.segmentControl.sendActions(for: .valueChanged)

        let inboxLabel = try XCTUnwrap(
            sut.customView.infoBubbleView.subviews.compactMap { $0 as? UILabel }.first
        )
        XCTAssertEqual(inboxLabel.attributedText?.string, LocalString._toolbar_setting_info_title_inbox)
    }

    func testContainerView_itemIsLoaded() throws {
        let actions: [MessageViewActionSheetAction] = [.markUnread, .trash, .moveTo, .labelAs]
        mockUser.messageToolbarActions = actions
        let listActions: [MessageViewActionSheetAction] = [.moveTo, .labelAs]
        mockUser.listViewToolbarActions = listActions
        makeSUT()
        sut.loadViewIfNeeded()

        var tableView = try XCTUnwrap(
            sut.customView.containerView.subviews.first(where: { $0 == sut.currentViewController?.customView }) as? ToolbarCustomizeView
        ).tableView
        XCTAssertEqual(
            tableView.numberOfRows(inSection: 0),
            actions.count
        )

        // Switch segment control
        sut.customView.segmentControl.selectedSegmentIndex = 1
        sut.customView.segmentControl.sendActions(for: .valueChanged)

        tableView = try XCTUnwrap(
            sut.customView.containerView.subviews.first(where: { $0 == sut.currentViewController?.customView }) as? ToolbarCustomizeView
        ).tableView
        XCTAssertEqual(
            tableView.numberOfRows(inSection: 0),
            listActions.count
        )
    }

    func testContainerView_itemIsLoaded_inConversation() throws {
        let actions: [MessageViewActionSheetAction] = [.markUnread, .trash, .moveTo, .labelAs]
        let listActions: [MessageViewActionSheetAction] = [.moveTo, .labelAs]
        mockUser.listViewToolbarActions = listActions
        mockUser.messageToolbarActions = actions
        makeSUT()
        sut.loadViewIfNeeded()

        var tableView = try XCTUnwrap(
            sut.customView.containerView.subviews.first(where: { $0 == sut.currentViewController?.customView }) as? ToolbarCustomizeView
        ).tableView
        XCTAssertEqual(
            tableView.numberOfRows(inSection: 0),
            actions.count
        )

        // Switch segment control
        sut.customView.segmentControl.selectedSegmentIndex = 1
        sut.customView.segmentControl.sendActions(for: .valueChanged)

        tableView = try XCTUnwrap(
            sut.customView.containerView.subviews.first(where: { $0 == sut.currentViewController?.customView }) as? ToolbarCustomizeView
        ).tableView
        XCTAssertEqual(
            tableView.numberOfRows(inSection: 0),
            listActions.count
        )
    }

    private func makeSUT() {
        let globalContainer = GlobalContainer()
        let userContainer = UserContainer(userManager: mockUser, globalContainer: globalContainer)
        sut = userContainer.toolbarSettingViewFactory.makeSettingView()
    }
}

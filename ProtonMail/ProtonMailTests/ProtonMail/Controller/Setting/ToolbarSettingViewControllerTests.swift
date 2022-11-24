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

import ProtonCore_DataModel
@testable import ProtonMail
import XCTest
import ProtonCore_TestingToolkit

final class ToolbarSettingViewControllerTests: XCTestCase {
    var sut: ToolbarSettingViewController!
    var viewModel: ToolbarSettingViewModel!
    var infoBubbleViewStatusStub: MockToolbarCustomizationInfoBubbleViewStatusProvider!
    var mockApiService: APIServiceMock!
    var mockUser: UserManager!
    var mockSaveToolbarActionSettings: MockSaveToolbarActionSettingsForUsersUseCase!

    override func setUp() {
        super.setUp()
        mockApiService = APIServiceMock()
        mockUser = UserManager(api: mockApiService, role: .none)
        infoBubbleViewStatusStub = MockToolbarCustomizationInfoBubbleViewStatusProvider()
        mockSaveToolbarActionSettings = MockSaveToolbarActionSettingsForUsersUseCase()
        makeSUT(viewMode: .singleMessage)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        viewModel = nil
        infoBubbleViewStatusStub = nil
        mockSaveToolbarActionSettings = nil
        mockUser = nil
        mockApiService = nil
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
        makeSUT(viewMode: .singleMessage)
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
        mockUser.conversationToolbarActions = actions
        let listActions: [MessageViewActionSheetAction] = [.moveTo, .labelAs]
        mockUser.listViewToolbarActions = listActions
        makeSUT(viewMode: .conversation)
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

    private func makeSUT(viewMode: ViewMode) {
        viewModel = ToolbarSettingViewModel(
            viewMode: viewMode,
            infoBubbleViewStatusProvider: infoBubbleViewStatusStub,
            toolbarActionProvider: mockUser,
            saveToolbarActionUseCase: mockSaveToolbarActionSettings
        )
        sut = ToolbarSettingViewController(viewModel: viewModel)
    }
}

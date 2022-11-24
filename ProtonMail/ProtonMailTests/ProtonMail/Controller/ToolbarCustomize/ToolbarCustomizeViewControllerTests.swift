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

@testable import ProtonMail
import XCTest

final class ToolbarCustomizeViewControllerTests: XCTestCase {
    var sut: ToolbarCustomizeViewController<MessageViewActionSheetAction>!
    var viewModel: ToolbarCustomizeViewModel<MessageViewActionSheetAction>!
    var toolbarCustomizationInfoBubbleViewStatusProviderMock: MockToolbarCustomizationInfoBubbleViewStatusProvider!

    override func setUp() {
        super.setUp()
        toolbarCustomizationInfoBubbleViewStatusProviderMock = MockToolbarCustomizationInfoBubbleViewStatusProvider()
        viewModel = ToolbarCustomizeViewModel<MessageViewActionSheetAction>(
            currentActions: [],
            allActions: [],
            actionsNotAddableToToolbar: MessageViewActionSheetAction.actionsNotAddableToToolbar,
            defaultActions: [],
            infoBubbleViewStatusProvider: toolbarCustomizationInfoBubbleViewStatusProviderMock
        )
        sut = ToolbarCustomizeViewController<MessageViewActionSheetAction>(viewModel: viewModel)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testInit_viewIsToolbarCustomizeView() {
        XCTAssertTrue(sut.view is ToolbarCustomizeView)
    }

    func testTapCloseButtonInInfoBubbleView_infoViewIsDismissed() throws {
        sut.loadViewIfNeeded()

        XCTAssertFalse(sut.customView.infoContainerView.subviews.isEmpty)

        let button = try XCTUnwrap(sut.customView.infoBubbleView.subviews.compactMap { $0 as? UIButton }.first)
        button.sendActions(for: .touchUpInside)

        XCTAssertTrue(sut.customView.infoContainerView.subviews.isEmpty)
    }
}

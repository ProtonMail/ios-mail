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

final class ToolbarCustomizeViewModelTests: XCTestCase {
    var sut: ToolbarCustomizeViewModel<MessageViewActionSheetAction>!
    var toolbarCustomizationInfoBubbleViewStatusProviderMock: MockToolbarCustomizationInfoBubbleViewStatusProvider!

    override func setUp() {
        super.setUp()
        toolbarCustomizationInfoBubbleViewStatusProviderMock = MockToolbarCustomizationInfoBubbleViewStatusProvider()
        sut = ToolbarCustomizeViewModel<MessageViewActionSheetAction>(
            currentActions: [],
            allActions: MessageViewActionSheetAction.allCases,
            actionsNotAddableToToolbar: MessageViewActionSheetAction.actionsNotAddableToToolbar,
            defaultActions: MessageViewActionSheetAction.defaultActions,
            infoBubbleViewStatusProvider: toolbarCustomizationInfoBubbleViewStatusProviderMock
        )
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        toolbarCustomizationInfoBubbleViewStatusProviderMock = nil
    }

    func testFetchNumberOfSections_return2() {
        XCTAssertEqual(sut.numberOfSections, 2)
    }

    func testNumberOfRowsInSection_section0_returnCountOfCurrentActions() {
        sut.setActions(actions: [.delete, .star])

        XCTAssertEqual(sut.numberOfRowsInSection(section: 0), sut.currentActions.count)
    }

    func testNumberOfRowsInSection_section1_returnCountOfAvailableActions() {
        sut.setActions(actions: [.delete, .star])
        XCTAssertEqual(sut.numberOfRowsInSection(section: 1), sut.availableActions.count)
    }

    func testNumberOfRowsInSection_sectionNot0Or1_return0() {
        XCTAssertEqual(sut.numberOfRowsInSection(section: Int.random(in: 2...Int.max)), 0)
    }

    func testAvailableActions_notContainsNonToolbarActions() {
        sut.setActions(actions: [])

        for action in MessageViewActionSheetAction.actionsNotAddableToToolbar {
            XCTAssertFalse(sut.availableActions.contains(action))
        }
    }

    func testToolbarAction_section0_getCorrectAction() throws {
        let actions: [MessageViewActionSheetAction] = [.star, .labelAs, .markRead]
        sut.setActions(actions: actions)

        for (index, action) in actions.enumerated() {
            let result = try XCTUnwrap(sut.toolbarAction(at: IndexPath(row: index, section: 0)))
            XCTAssertEqual(result, action)
        }

        for i in actions.count...MessageViewActionSheetAction.allCases.count {
            XCTAssertNil(sut.toolbarAction(at: IndexPath(row: i, section: 0)))
        }
    }

    func testToolbarAction_section1_getCorrectAction() throws {
        let actions: [MessageViewActionSheetAction] = [.star, .labelAs, .markRead]
        sut.setActions(actions: actions)

        let expectedActions = sut.availableActions

        for (index, action) in expectedActions.enumerated() {
            let result = try XCTUnwrap(sut.toolbarAction(at: IndexPath(row: index, section: 1)))
            XCTAssertEqual(result, action)
        }

        for i in expectedActions.count...MessageViewActionSheetAction.allCases.count {
            XCTAssertNil(sut.toolbarAction(at: IndexPath(row: i, section: 1)))
        }
    }

    func testToolbarAction_sectionNot0And1_getNil() {
        XCTAssertNil(sut.toolbarAction(at: IndexPath(row: Int.random(in: 0...Int.max), section: Int.random(in: 2...Int.max))))
    }

    func testCellIsEnable_currentActionsLessThen5_returnTrue() {
        sut.setActions(actions: [.moveTo, .markRead, .labelAs])

        XCTAssertTrue(sut.cellIsEnable(at: IndexPath(row: Int.random(in: 0...Int.max),
                                                     section: Int.random(in: 0...Int.max))))
    }

    func testCellIsEnable_currentActionsEquals5_section0_returnTrue() {
        sut.setActions(actions: [.labelAs, .markRead, .moveTo, .star, .trash])

        XCTAssertTrue(sut.cellIsEnable(at: IndexPath(row: Int.random(in: 0...Int.max),
                                                     section: 0)))
    }

    func testCellIsEnable_currentActionsEquals5_sectionMoreThen0_returnFalse() {
        sut.setActions(actions: [.labelAs, .markRead, .moveTo, .star, .trash])

        XCTAssertFalse(sut.cellIsEnable(at: IndexPath(row: Int.random(in: 0...Int.max),
                                                      section: Int.random(in: 1...Int.max))))
    }

    func testIsAnSelectedAction() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead, .moveTo, .star, .trash]
        sut.setActions(actions: actions)

        for action in actions {
            XCTAssertTrue(sut.isAnSelectedAction(of: action))
        }

        for action in sut.availableActions {
            XCTAssertFalse(sut.isAnSelectedAction(of: action))
        }
    }

    func testHandleCellAction_sectionNot0And1_currentActionNotUpdated() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead]
        sut.setActions(actions: actions)

        sut.handleCellAction(action: .remove, indexPath: IndexPath(row: Int.max, section: Int.random(in: 2...Int.max)))

        XCTAssertEqual(sut.currentActions, actions)

        sut.handleCellAction(action: .insert, indexPath: IndexPath(row: Int.max, section: Int.random(in: 2...Int.max)))

        XCTAssertEqual(sut.currentActions, actions)
    }

    func testHandleCellAction_section0_rowIsMoreThanActions_currentActionNotUpdated() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead]
        sut.setActions(actions: actions)

        sut.handleCellAction(action: .remove,
                             indexPath: IndexPath(row: Int.random(in: actions.count...Int.max),
                                                  section: 0))

        XCTAssertEqual(sut.currentActions, actions)
    }

    func testHandleCellAction_section1_rowIsMoreThanActions_currentActionNotUpdated() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead]
        sut.setActions(actions: actions)

        sut.handleCellAction(action: .remove,
                             indexPath: IndexPath(row: Int.random(in: sut.availableActions.count...Int.max),
                                                  section: 1))

        XCTAssertEqual(sut.currentActions, actions)
    }

    func testHandleCellAction_section1_withCurrentActionsCountIs5_currentActionNotUpdated() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead, .moveTo, .star, .delete]
        sut.setActions(actions: actions)

        sut.handleCellAction(action: .insert,
                             indexPath: IndexPath(row: 1,
                                                  section: 1))

        XCTAssertEqual(sut.currentActions, actions)
    }

    func testHandleCellAction_section1_currentActionIsUpdated() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead, .moveTo]
        sut.setActions(actions: actions)
        let actionToInsert = sut.availableActions[1]
        let expectation1 = expectation(description: "Closure is called")
        sut.reloadTableView = {
            expectation1.fulfill()
        }

        sut.handleCellAction(action: .insert,
                             indexPath: IndexPath(row: 1,
                                                  section: 1))

        XCTAssertEqual(sut.currentActions,
                       [
                           .labelAs,
                           .markRead,
                           .moveTo,
                           actionToInsert
                       ])
        XCTAssertFalse(sut.availableActions.contains(actionToInsert))
        waitForExpectations(timeout: 1)
    }

    func testHandleCellAction_section0_currentActionsIsUpdated() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead, .moveTo]
        sut.setActions(actions: actions)
        let expectation1 = expectation(description: "Closure is called")
        sut.reloadTableView = {
            expectation1.fulfill()
        }

        sut.handleCellAction(action: .remove,
                             indexPath: IndexPath(row: 0,
                                                  section: 0))

        XCTAssertEqual(sut.currentActions,
                       [
                           .markRead,
                           .moveTo
                       ])
        XCTAssertTrue(sut.availableActions.contains(.labelAs))
        waitForExpectations(timeout: 1)
    }

    func testAvailableActions_areInTheSameOrder() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead, .moveTo]
        sut.setActions(actions: actions)
        let expected = MessageViewActionSheetAction.allCases
            .filter { !actions.contains($0) && !MessageViewActionSheetAction.actionsNotAddableToToolbar.contains($0) }

        XCTAssertEqual(sut.availableActions, expected)
    }

    func testHideInfoBubbleView() {
        toolbarCustomizationInfoBubbleViewStatusProviderMock.shouldShowViewStub.fixture = false
        XCTAssertTrue(sut.shouldShowInfoBubbleView)

        sut.hideInfoBubbleView()

        XCTAssertTrue(toolbarCustomizationInfoBubbleViewStatusProviderMock.shouldShowViewStub.getWasCalled)
    }

    func testMoveAction_toInvalidSection_noChangeIsApplied() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead, .moveTo]
        sut.setActions(actions: actions)

        sut.moveAction(from: IndexPath(row: 0, section: 0), to: IndexPath(row: 0, section: 1))

        XCTAssertEqual(sut.currentActions, actions)
    }

    func testMoveAction_toInvalidRow_noChangeIsApplied() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead, .moveTo]
        sut.setActions(actions: actions)

        sut.moveAction(from: IndexPath(row: 0, section: 0), to: IndexPath(row: 100, section: 0))

        XCTAssertEqual(sut.currentActions, actions)
    }

    func testMoveAction_fromInvalidRow_noChangeIsApplied() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead, .moveTo]
        sut.setActions(actions: actions)

        sut.moveAction(from: IndexPath(row: 100, section: 0), to: IndexPath(row: 1, section: 0))

        XCTAssertEqual(sut.currentActions, actions)
    }

    func testMoveAction_changeIsExpected() {
        let actions: [MessageViewActionSheetAction] = [.labelAs, .markRead, .moveTo]
        sut.setActions(actions: actions)

        sut.moveAction(from: IndexPath(row: 0, section: 0),
                       to: IndexPath(row: 1, section: 0))

        XCTAssertEqual(sut.currentActions, [.markRead, .labelAs, .moveTo])
    }

    func testResetActionsToDefault() {
        XCTAssertTrue(sut.currentActions.isEmpty)
        let e = expectation(description: "Closure is called")
        sut.reloadTableView = {
            e.fulfill()
        }

        sut.resetActionsToDefault()
        XCTAssertEqual(sut.currentActions, MessageViewActionSheetAction.defaultActions)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetAlertTitle() {
        XCTAssertEqual(sut.alertTitle, LocalString._toolbar_customize_reset_alert_title)
    }

    func testGetAlertContent() {
        XCTAssertEqual(sut.alertContent, LocalString._toolbar_customize_reset_alert_content)
    }
}

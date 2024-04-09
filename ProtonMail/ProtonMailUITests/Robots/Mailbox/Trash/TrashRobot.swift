//
//  TrashRobot.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/25.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion
import XCTest

fileprivate struct id {
    static let mailboxMoreButtonIdentifier = "MailboxViewController.ellipsisMenuBarItem"
    static let emptyTrashButtonText = LocalString._empty_trash
    static let mailBoxTableView = "MailboxViewController.tableView"
    static let confirmDeleteButtonText = LocalString._general_delete_action
}

class TrashRobot: MailboxRobotInterface {
    
    var verify = Verify()
    
    func clearTrashFolder() -> TrashRobot {
        moreOptions()
            .emptyFolder()
            .confirmEmptyTrashFolderAction()
    }
    
    override func confirmMessageDeletion() -> TrashRobot {
        super.confirmMessageDeletion()
        return TrashRobot()
    }
    
    private func moreOptions() -> TrashRobot {
        button(id.mailboxMoreButtonIdentifier).tap()
        return TrashRobot()
    }

    private func emptyFolder() -> TrashDialogRobot {
        button(id.emptyTrashButtonText).tap()
        return TrashDialogRobot()
    }
    
    override func longClickMessageBySubject(_ subject: String) -> TrashSelectionStateRobot {
        super.longClickMessageBySubject(subject)
        return TrashSelectionStateRobot()
    }
    
    override func selectMultipleMessages(_ positions: [Int]) -> TrashSelectionStateRobot {
        super.selectMultipleMessages(positions)
        return TrashSelectionStateRobot()
    }
    
    class TrashDialogRobot: CoreElements {
        func confirmEmptyTrashFolderAction() -> TrashRobot {
            button(id.confirmDeleteButtonText).tap()
            return TrashRobot()
        }
    }
    
    /**
     * Contains all the validations that can be performed by [Trash].
     */
    class Verify : MailboxRobotVerifyInterface {

        func numberOfMessageExists(_ number: Int) {
            table(id.mailBoxTableView).waitUntilExists()
            XCTAssertEqual(number, table(id.mailBoxTableView).childrenCountByType(XCUIElement.ElementType.cell), "Number of expected messages doesnt match")
        }
    }
}

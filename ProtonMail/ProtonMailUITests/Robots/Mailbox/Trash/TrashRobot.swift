//
//  TrashRobot.swift
//  Proton MailUITests
//
//  Created by mirage chung on 2020/12/25.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let mailboxMoreButtonIdentifier = "MailboxViewController.moreBarButtonItem"
    static let emptyFolderButtonIdentifier = "Empty folder"
}

class TrashRobot: MailboxRobotInterface {
    
    var verify = Verify()
    
    func clearTrashFolder() -> TrashRobot {
        moreOptions()
            .emptyFolder()
            .confirmEmptyTrashFolderAction()
    }
    
    private func moreOptions() -> TrashRobot {
        button(id.mailboxMoreButtonIdentifier).tap()
        return TrashRobot()
    }

    private func emptyFolder() -> TrashDialogRobot {
        button(id.emptyFolderButtonIdentifier).tap()
        return TrashDialogRobot()
    }
    
    class TrashDialogRobot: CoreElements {
        func confirmEmptyTrashFolderAction() -> TrashRobot {
            button(id.emptyFolderButtonIdentifier).tap()
            return TrashRobot()
        }
    }
    
    /**
     * Contains all the validations that can be performed by [Trash].
     */
    class Verify : MailboxRobotVerifyInterface {
        
        func messageWithSubjectExists(_ subject: String) {
            staticText(subject).wait().checkExists()
        }
    }
}

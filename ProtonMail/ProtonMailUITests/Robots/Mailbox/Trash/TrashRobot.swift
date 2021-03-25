//
//  TrashRobot.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/25.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let mailboxMoreButtonIdentifier = "MailboxViewController.moreBarButtonItem"
fileprivate let emptyFolderButtonIdentifier = "Empty folder"


class TrashRobot: MailboxRobotInterface {
    
    var verify: Verify! = nil
    override init() {
        super.init()
        verify = Verify(parent: self)
    }
    
    func clearTrashFolder() -> TrashRobot {
        moreOptions()
            .emptyFolder()
            .confirmEmptyTrashFolderAction()
    }
    
    private func moreOptions() -> TrashRobot {
        Element.wait.forButtonWithIdentifier(mailboxMoreButtonIdentifier, file: #file, line: #line).tap()
        return TrashRobot()
    }

    private func emptyFolder() -> TrashDialogRobot {
        Element.wait.forButtonWithIdentifier(emptyFolderButtonIdentifier, file: #file, line: #line).tap()
        return TrashDialogRobot()
    }
    
    class TrashDialogRobot {
        func confirmEmptyTrashFolderAction() -> TrashRobot {
            Element.wait.forButtonWithIdentifier(emptyFolderButtonIdentifier, file: #file, line: #line).tap()
            return TrashRobot()
        }
    }
    
    /**
     * Contains all the validations that can be performed by [Trash].
     */
    class Verify : MailboxRobotVerifyInterface {
        unowned let trashRobot: TrashRobot
        init(parent: TrashRobot) { trashRobot = parent }
        
        func messageWithSubjectExists(_ subject: String) {
            Element.wait.forStaticTextFieldWithIdentifier(subject)
        }
    }
}

//
//  SelectionStateRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion

/**
 Parent class for selection state of Mailbox Robot classes like Inbox, Sent, Trash, etc.
 */


fileprivate struct id {
    static let readButtonIdentifier = "PMToolBarView.readButton"
    static let trashButtonIdentifier = "PMToolBarView.trashButton"
    static let spamButtonIdentifier = "PMToolBarView.spamButton"
    static let moveToButtonIdentifier = "PMToolBarView.moveToButton"
    static let labelAsButtonIdentifier = "PMToolBarView.labelAsButton"
    static let moreButtonIdentifier = "PMToolBarView.moreButton"
    static let deleteButtonIdentifier = "PMToolBarView.deleteButton"
}

class SelectionStateRobotInterface: CoreElements {
    
    func read() -> SelectionStateRobotInterface {
        // TODO: Add implementation for read
        return self
    }

    func moveToTrash() -> MailboxRobotInterface {
        button(id.trashButtonIdentifier).waitForHittable().tap()
        return MailboxRobotInterface()
    }

    func moveTo() -> MoveToFolderRobotInterface {
        button(id.moveToButtonIdentifier).waitForHittable().tap()
        return MoveToFolderRobotInterface()
    }

    func labelAs() -> SelectionStateRobotInterface {
        // TODO: Add implementation for labelAs
        return self
    }

    func more() -> SelectionStateRobotInterface {
        // TODO: Add implementation for more
        return self
    }
    
    func delete() -> MailboxRobotInterface {
        button(id.deleteButtonIdentifier).waitForHittable().tap()
        return MailboxRobotInterface()
    }
}

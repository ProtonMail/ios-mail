//
//  MailboxRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 22.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

fileprivate let menuButton = "Menu"
let composeButtonLabel = "Compose"
fileprivate let mailboxTableViewIdentifier = "MailboxViewController.tableView"

/**
 Parent class for all the Mailbox Robot classes like Inbox, Sent, Trash, etc.
 */
class MailboxRobotInterface {
    
    init() {
        Element.wait.forTableViewWithIdentifier(mailboxTableViewIdentifier, file: #file, line: #line)
    }
    
    @discardableResult
    func swipeLeftMessageAtPosition(_ position: Int) -> MailboxRobotInterface {
        return self
    }

    func longClickMessageOnPosition(_ position: Int) -> MailboxRobotInterface {
        return self
    }

    func deleteMessageWithSwipe(_ position: Int) -> MailboxRobotInterface {
        return self
    }

    func searchBar() -> MailboxRobotInterface {
        return self
    }

    func compose() -> ComposerRobot {
        Element.wait.forButtonWithIdentifier(composeButtonLabel, file: #file, line: #line).tap()
        return ComposerRobot()
    }

    func menuDrawer() -> MenuRobot {
        Element.wait.forHittableButton(menuButton).tap()
        return MenuRobot()
    }

    func selectMessage(position: Int) -> MailboxRobotInterface {
       return self
    }
}

/**
 Contains all the validations that can be performed by Mailbox Robots.
*/
class MailboxRobotVerifyInterface {
    
    func messageMoved(messageSubject: String) {
        
    }

    func draftWithAttachmentSaved(draftSubject: String) {
        
    }

    func mailboxLayoutShown(){
        
    }
}

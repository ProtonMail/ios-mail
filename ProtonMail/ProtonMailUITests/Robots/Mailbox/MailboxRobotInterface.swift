//
//  MailboxRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 22.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest
import XCTest

fileprivate struct id {
    static let menuButtonIdentifier = "MailboxViewController.menuBarButtonItem"
    static let composeButtonLabelIdentifier = "MailboxViewController.composeBarButtonItem"
    static let mailboxTableViewIdentifier = "MailboxViewController.tableView"
    static let searchNavBarButtonIdentifier = "MailboxViewController.searchBarButtonItem"
    static let mailboxNoResultIdentifier = "MailboxViewController.noResultLabel"
    static func mailboxMessageCellIdentifier(_ subject: String) -> String { return "NewMailboxMessageCell.\(subject)" }
    static let mailboxMessageTitleIdentifier = "mailboxMessageCell.titleLabel"
    static let trashButtonIdentifier = LocalString._menu_trash_title
    static let skipOnboardingButtonLabel = LocalString._skip_btn_title
    static let allowContacsAccessOkButtonLabel = LocalString._general_ok_action
}

var subjects = [String]()

/**
 Parent class for all the Mailbox Robot classes like Inbox, Sent, Trash, etc.
 */
class MailboxRobotInterface: CoreElements {
    
    required init() {
        super.init()
        if XCUIApplication().exists {
            table(id.mailboxTableViewIdentifier).firstMatch().wait(time: 15)
        }
    }
    
    @discardableResult
    func clickMessageBySubject(_ subject: String) -> MessageRobot {
        cell(id.mailboxMessageCellIdentifier(subject)).onChild(staticText(subject)).firstMatch().forceTap()
        return MessageRobot()
    }
    
    @discardableResult
    func clickMessageByIndex(_ index: Int) -> MessageRobot {
        cell().byIndex(index).onChild(staticText().byIndex(1)).forceTap()
        return MessageRobot()
    }
    
    @discardableResult
    func spamMessageBySubject(_ subject: String) -> MailboxRobotInterface {
        cell(id.mailboxMessageCellIdentifier(subject)).firstMatch().tapThenSwipeLeft(0.5, .slow)
        return self
    }

    func searchBar() -> SearchRobot {
        button(id.searchNavBarButtonIdentifier).firstMatch().waitForHittable().tap()
        return SearchRobot()
    }

    @discardableResult
    func compose() -> ComposerRobot {
        button(id.composeButtonLabelIdentifier).firstMatch().tap()
        return ComposerRobot()
    }

    func menuDrawer() -> MenuRobot {
        button(id.menuButtonIdentifier).firstMatch().waitForHittable().tap()
        return MenuRobot()
    }
    
    @discardableResult
    func selectMessage(position: Int) -> MailboxRobotInterface {
        cell().byIndex(position).forceTap()
        return self
    }
    
    @discardableResult
    func refreshMailbox() -> MailboxRobotInterface {
        table(id.mailboxTableViewIdentifier).tapThenSwipeDown(0.3, .slow)
        return self
    }
    
    @discardableResult
    func refreshGentlyMailbox() -> MailboxRobotInterface {
        table(id.mailboxTableViewIdentifier).swipeDown().wait(time: 3)
        return self
    }
    
    @discardableResult
    func trash() -> MailboxRobotInterface {
        button(id.trashButtonIdentifier).tap()
        return MailboxRobotInterface()
    }
    
    @discardableResult
    func longClickMessageBySubject(_ subject: String) -> SelectionStateRobotInterface {
        staticText(subject).firstMatch().longPress()
        return SelectionStateRobotInterface()
    }
    
    @discardableResult
    func longClickMessageOnPosition(_ position: Int) -> SelectionStateRobotInterface {
        cell().byIndex(position).longPress()
        return SelectionStateRobotInterface()
    }
}

/**
 Contains all the validations that can be performed by Mailbox Robots.
*/
class MailboxRobotVerifyInterface: CoreElements {
    
    func messageExists(_ subject: String) {
        cell(id.mailboxMessageCellIdentifier(subject)).onChild(staticText(subject)).firstMatch().checkExists()
    }
    
    func messageIsEmpty() {
        staticText(id.mailboxNoResultIdentifier).checkHasLabel("No Messages")
    }
    
    func draftWithAttachmentSaved(draftSubject: String) {
        ///TODO: add implementation
    }

    func mailboxLayoutShown(){
        ///TODO: add implementation
    }
}

//
//  MailboxRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 22.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let menuButton = "Menu"
let composeButtonLabel = "Compose"
fileprivate let mailboxTableViewIdentifier = "MailboxViewController.tableView"
fileprivate let searchNavBarButtonIdentifier = "MailboxViewController.searchBarButtonItem"
fileprivate let mailboxNoResultIdentifier = "MailboxViewController.noResultLabel"
fileprivate func messageCellIdentifier(_ subject: String) -> String { return "MailboxMessageCell.\(subject)" }

/**
 Parent class for all the Mailbox Robot classes like Inbox, Sent, Trash, etc.
 */
class MailboxRobotInterface {
    
    init() {
        Element.wait.forTableViewWithIdentifier(mailboxTableViewIdentifier, file: #file, line: #line, timeout: 15)
    }
    
    @discardableResult
    func clickMessageBySubject(_ subject: String) -> MessageRobot {
        Element.wait.forCellWithIdentifier(messageCellIdentifier(subject.replacingOccurrences(of: " ", with: "_"))).tap()
        return MessageRobot()
    }
    
    @discardableResult
    func clickMessageByIndex(_ index: Int) -> MessageRobot {
        Element.wait.forCellByIndex(index).tap()
        return MessageRobot()
    }
    
    @discardableResult
    func swipeLeftMessageAtPosition(_ position: Int) -> MailboxRobotInterface {
        return self
    }
    
    @discardableResult
    func spamMessageBySubject(_ subject: String) -> MailboxRobotInterface {
        Element.staticText.swipeLeftByIdentifier(subject)
        return self
    }
    
    @discardableResult
    func longClickMessageOnPosition(_ position: Int) -> MailboxRobotInterface {
        return self
    }

    func deleteMessageWithSwipe(_ position: Int) -> MailboxRobotInterface {
        return self
    }

    func searchBar() -> SearchRobot {
        Element.wait.forHittableButton(searchNavBarButtonIdentifier).tap()
        return SearchRobot()
    }

    @discardableResult
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
    
    @discardableResult
    func refreshMailbox() -> MailboxRobotInterface {
        Element.tableView.swipeDownByIdentifier(mailboxTableViewIdentifier)
        return self
    }
}

/**
 Contains all the validations that can be performed by Mailbox Robots.
*/
class MailboxRobotVerifyInterface {
    
    func messageExists(_ subject: String) {
        Element.wait.forCellWithIdentifier(messageCellIdentifier(subject.replacingOccurrences(of: " ", with: "_")))
    }
    
    func messageIsEmpty() {
        Element.wait.forStaticTextFieldWithIdentifier(mailboxNoResultIdentifier).assertWithLabel("No Messages")
    }

    func draftWithAttachmentSaved(draftSubject: String) {
        
    }

    func mailboxLayoutShown(){
        
    }
}

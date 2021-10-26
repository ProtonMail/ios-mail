//
//  MailboxRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 22.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let menuButtonIdentifier = "MailboxViewController.menuBarButtonItem"
    static let composeButtonLabelIdentifier = "MailboxViewController.composeBarButtonItem"
    static let mailboxTableViewIdentifier = "MailboxViewController.tableView"
    static let searchNavBarButtonIdentifier = "MailboxViewController.searchBarButtonItem"
    static let mailboxNoResultIdentifier = "MailboxViewController.noResultLabel"
    static let mailboxMessageCellIdentifier = "NewMailboxMessageCell.mailboxMessageCell"
    static func messageCellIdentifier(_ subject: String) -> String { return "MailboxMessageCell.\(subject)" }
    static let trashButtonIdentifier = LocalString._menu_trash_title
    static let skipOnboardingButtonLabel = LocalString._skip_btn_title
}

var subjects = [String]()

/**
 Parent class for all the Mailbox Robot classes like Inbox, Sent, Trash, etc.
 */
class MailboxRobotInterface: CoreElements {
    
    required init() {
        super.init()
        closeTourIfShown()
        table(id.mailboxTableViewIdentifier).wait(time: 20)
    }
    
    @discardableResult
    func clickMessageBySubject(_ subject: String) -> MessageRobot {
        cell(id.messageCellIdentifier(subject.replacingOccurrences(of: " ", with: "_"))).tap()
        return MessageRobot()
    }
    
    @discardableResult
    func clickMessageByIndex(_ index: Int) -> MessageRobot {
        cell(id.mailboxMessageCellIdentifier).byIndex(index).tap()
        return MessageRobot()
    }
    
    @discardableResult
    func spamMessageBySubject(_ subject: String) -> MailboxRobotInterface {
        cell(id.mailboxMessageCellIdentifier).containing(.staticText, subject).tapThenSwipeLeft(0.5, .slow)
        return self
    }

    func searchBar() -> SearchRobot {
        button(id.searchNavBarButtonIdentifier).waitForHittable().tap()
        return SearchRobot()
    }

    @discardableResult
    func compose() -> ComposerRobot {
        button(id.composeButtonLabelIdentifier).tap()
        return ComposerRobot()
    }

    func menuDrawer() -> MenuRobot {
        button(id.menuButtonIdentifier).waitForHittable().tap()
        return MenuRobot()
    }
    
    @discardableResult
    func selectMessage(position: Int) -> MailboxRobotInterface {
        cell().byIndex(position).tap()
        return self
    }
    
    @discardableResult
    func refreshMailbox() -> MailboxRobotInterface {
        table(id.mailboxTableViewIdentifier).tapThenSwipeDown(0.3, .slow)
        return self
    }
    
    func deleteMessageWithLongClick(_ subject: String) -> MailboxRobotInterface {
        longClickMessageBySubject(subject)
            .trash()
        return self
    }
    
    func deleteMultipleMessages(_ positions: [Int]) -> MailboxRobotInterface {
        multiSelectionMessagesOnPositions(positions)
            .trash()
    }
    
    @discardableResult
    func trash() -> MailboxRobotInterface {
        button(id.trashButtonIdentifier).tap()
        return MailboxRobotInterface()
    }
    
    @discardableResult
    func longClickMessageBySubject(_ subject: String) -> MailboxRobotInterface {
        staticText(subject).longPress()
        return MailboxRobotInterface()
    }
    
    @discardableResult
    func longClickMessageOnPositions(_ position: Int) -> MailboxRobotInterface {
        cell().byIndex(position).longPress()
        subjects.append(Element.cell.getNameByIndex(position).replacingOccurrences(of: "_", with: " "))
        return MailboxRobotInterface()
    }
    
    func multiSelectionMessagesOnPositions(_ positions: [Int]) -> MailboxRobotInterface {
        longClickMessageOnPositions(positions[0])
        for position in positions.dropFirst() {
            selectMessage(position: position)
        }
        return MailboxRobotInterface()
    }
    
    private func closeTourIfShown() {
        let elem = app.buttons[id.skipOnboardingButtonLabel].firstMatch
        if !wasTourClosed && elem.exists {
            elem.tap()
            wasTourClosed = true
        }
    }
}

/**
 Contains all the validations that can be performed by Mailbox Robots.
*/
class MailboxRobotVerifyInterface: CoreElements {
    
    func messageExists(_ subject: String) {
        cell(id.messageCellIdentifier(subject.replacingOccurrences(of: " ", with: "_"))).wait().checkExists()
    }
    
    func messageIsEmpty() {
        staticText(id.mailboxNoResultIdentifier).wait().checkHasLabel("No Messages")
    }

    func messageSubjectsExist() {
        for subject in subjects {
            staticText(subject).wait().checkExists()
        }
    }
    
    func draftWithAttachmentSaved(draftSubject: String) {
        ///TODO: add implementation
    }

    func mailboxLayoutShown(){
        ///TODO: add implementation
    }
}

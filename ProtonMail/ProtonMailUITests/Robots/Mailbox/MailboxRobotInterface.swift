//
//  MailboxRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 22.07.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion
import XCTest

fileprivate struct id {
    static let menuButtonIdentifier = "Menu"
    static let composeButtonLabelIdentifier = "MailboxViewController.composeBarButtonItem"
    static let mailboxTableViewIdentifier = "MailboxViewController.tableView"
    static let searchNavBarButtonIdentifier = "MailboxViewController.searchBarButtonItem"
    static let noResultImage = "MailboxViewController.noResultImage"
    static let noResultMainLabel = "MailboxViewController.noResultMainLabel"
    static let noResultSecondaryLabel = "MailboxViewController.noResultSecondaryLabel"
    static let primaryUserviewButtonIdentifier = "MenuViewController.primaryUserview"
    static func mailboxMessageCellIdentifier(_ subject: String) -> String { return "NewMailboxMessageCell.\(subject.replaceSpaces())" }
    static func mailboxMessageTitleIdentifier(_ subject: String) -> String { return "\(subject.replaceSpaces()).titleLabel" }
    static let trashButtonIdentifier = LocalString._menu_trash_title
    static let skipOnboardingButtonLabel = LocalString._skip_btn_title
    static let allowContacsAccessOkButtonLabel = LocalString._general_ok_action
    static let confirmDeleteButtonText = LocalString._general_delete_action

    // Referral prompt view elements identifiers
    static let referralContainerViewIdentifier = "ReferralPromptView.containerView"
    static let referralCloseButtonIdentifier = "ReferralPromptView.closeButton"
    static let referralLaterButtonIdentifier = "ReferralPromptView.laterButton"
}

enum MessageState: String {
    case read = "read"
    case unread = "unread"
}

var subjects = [String]()

/**
 Parent class for all the Mailbox Robot classes like Inbox, Sent, Trash, etc.
 */
class MailboxRobotInterface: CoreElements {
    
    required init() {
        super.init()
        if XCUIApplication().exists {
            table(id.mailboxTableViewIdentifier).firstMatch().waitUntilExists(time: 20)
            activityIndicator().waitUntilGone()

            // the spinner might still be visible (and blocking the UI) when a cell that we want to tap appears
            // is waitUntilGone broken?
            // TODO: find if there's a better way to wait until the cell can be tapped
            sleep(5)
        }
    }
    
    @discardableResult
    func clickMessageBySubject(_ subject: String) -> MessageRobot {
        activityIndicator().waitUntilGone()
        return clickMessageBySubject(subject, retriesLeft: 3)
    }

    private func clickMessageBySubject(_ subject: String, retriesLeft: Int) -> MessageRobot {
        if !cell(id.mailboxMessageCellIdentifier(subject)).exists(), retriesLeft > 0 {
            return refreshMailbox().clickMessageBySubject(subject, retriesLeft: retriesLeft - 1)
        } else {
            cell(id.mailboxMessageCellIdentifier(subject))
                .firstMatch()
                .waitForHittable(time: 30.0)
                .tapIfExists()
            return MessageRobot()
        }
    }
    
    @discardableResult
    func clickMessageByIndex(_ index: Int) -> MessageRobot {
        cell().byIndex(index).waitForHittable().tap()
        return MessageRobot()
    }
    
    @discardableResult
    func spamMessageBySubject(_ subject: String) -> MailboxRobotInterface {
        staticText(id.mailboxMessageTitleIdentifier(subject)).firstMatch().tapThenSwipeRight(0.5, .slow)
        return self
    }

    func searchBar() -> SearchRobot {
        button(id.searchNavBarButtonIdentifier).firstMatch().waitForHittable().tap()
        return SearchRobot()
    }

    @discardableResult
    func compose() -> ComposerRobot {
        button(id.composeButtonLabelIdentifier).firstMatch().waitForHittable().tap()
        return ComposerRobot()
    }

    func menuDrawer() -> MenuRobot {
        button(id.menuButtonIdentifier).firstMatch().waitForHittable(time: 30).tap()
        button(id.primaryUserviewButtonIdentifier).waitUntilExists().checkExists()
        return MenuRobot()
    }
    
    @discardableResult
    func selectMessage(position: Int) -> MailboxRobotInterface {
        cell().byIndex(position).waitForHittable().forceTap()
        return self
    }
    
    @discardableResult
    func refreshMailbox() -> MailboxRobotInterface {
        table(id.mailboxTableViewIdentifier).firstMatch().tapThenSwipeDown(0.3, .slow)
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

    func selectMultipleMessages(_ positions: [Int]) -> SelectionStateRobotInterface {
        if let firstPosition = positions.first {
            longClickMessageOnPosition(firstPosition)
        }
        
        if positions.count > 1 {
            let remainingPositions = Array(positions.dropFirst())
            for position in remainingPositions {
                cell().byIndex(position).tap()
            }
        }
        return SelectionStateRobotInterface()
    }

    
    func backgroundApp() -> PinRobot {
        XCUIDevice.shared.press(.home)
        sleep(3) 
        return PinRobot()
    }
    
    func confirmMessageDeletion() -> MailboxRobotInterface {
        button(id.confirmDeleteButtonText).tap()
        return MailboxRobotInterface()
    }

    class ReferralPromptViewRobotInterface: CoreElements {

        @discardableResult
        func dismissReferralByTapOutside() -> MailboxRobotInterface {
            /// We try to tap to the top of the screen, ideally in the container view outside of the prompt view
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
            return MailboxRobotInterface()
        }

        @discardableResult
        func dismissReferralWithCloseButton() -> MailboxRobotInterface {
            button(id.referralCloseButtonIdentifier).tap()
            return MailboxRobotInterface()
        }

        @discardableResult
        func dismissReferralWithLaterButton() -> MailboxRobotInterface {
            button(id.referralLaterButtonIdentifier).tap()
            return MailboxRobotInterface()
        }
    }
}

/**
 Contains all the validations that can be performed by Mailbox Robots.
*/
class MailboxRobotVerifyInterface: CoreElements {
    
    func messageExists(_ subject: String) {
        cell(id.mailboxMessageCellIdentifier(subject)).onChild(staticText(subject)).firstMatch().waitUntilExists().checkExists()
    }
    
    func nothingToSeeHere() {
        image(id.noResultImage).waitUntilExists().checkExists()
        staticText(id.noResultMainLabel).checkExists()
        staticText(id.noResultSecondaryLabel).checkExists()
    }
    
    func draftWithAttachmentSaved(draftSubject: String) {
        ///TODO: add implementation
    }

    func mailboxLayoutShown(){
        ///TODO: add implementation
    }

    func referralPromptIsNotShown() {
        button(id.referralCloseButtonIdentifier).checkDoesNotExist()
    }
    
    func messageWithSubjectIsRead(_ subject: String) -> InboxRobot {
        XCTAssertEqual(cell(id.mailboxMessageCellIdentifier(subject)).hasValue(MessageState.read.rawValue).waitUntilExists().value() as! String, MessageState.read.rawValue, "Expected message with subject: \"\(subject)\" to be READ but got UNREAD.")
        return InboxRobot()
    }
    
    @discardableResult
    func messageWithSubjectIsUnread(_ subject: String) -> InboxRobot {
        XCTAssertEqual(cell(id.mailboxMessageCellIdentifier(subject)).hasValue(MessageState.unread.rawValue).waitUntilExists().value() as! String, MessageState.unread.rawValue, "Expected message with subject: \"\(subject)\" to be UNREAD but got READ.")
        return InboxRobot()
    }
}

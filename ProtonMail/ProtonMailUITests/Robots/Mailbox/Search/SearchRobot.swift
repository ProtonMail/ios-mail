//
//  SearchRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 08.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import pmtest

fileprivate struct id {
    static let searchTextFieldIdentifier = "SearchViewController.textField"
    static let mailboxMessageCellIdentifier = "NewMailboxMessageCell.mailboxMessageCell"
    static let messageSenderLabelIdentifier = "mailboxMessageCell.senderLabel"
    static let messageTitleLabelIdentifier = "mailboxMessageCell.titleLabel"
    static let searchKeyboardButtonText = LocalString._general_search_placeholder
    static let cancelButttonIdentifier = LocalString._general_cancel_button
    static func draftCellIdentifier(_ subject: String) -> String { return "MailboxMessageCell.\(subject)".replacingOccurrences(of: " ", with: "_") }
    static func messageCellIdentifier(_ subject: String) -> String { return "MailboxMessageCell.\(subject)" }
}

/**
 SearchRobot class contains actions and verifications for Search functionality.
 */
class SearchRobot: CoreElements {

    var verify: Verify! = Verify()
    
    func searchMessageText(_ subject: String) -> SearchRobot {
        return typeTextToSearch(subject)
            .tapKeyboardSearchButton()
    }
    
    func clickSearchedMessageBySubject(_ subject: String) -> MessageRobot {
        staticText(id.messageTitleLabelIdentifier).containsLabel(subject).tap()
        return MessageRobot()
    }
    
    func clickSearchedDraftBySubject(_ subject: String) -> ComposerRobot {
        staticText(id.messageTitleLabelIdentifier).containsLabel(subject).tap()
        return ComposerRobot()
    }

    func goBackToInbox() -> InboxRobot {
        button(id.cancelButttonIdentifier).tap()
        return InboxRobot()
    }
    
    func goBackToDrafts() -> DraftsRobot {
        button(id.cancelButttonIdentifier).tap()
        return DraftsRobot()
    }
    
    private func typeTextToSearch(_ text: String) -> SearchRobot {
        textField(id.searchTextFieldIdentifier).typeText(text)
        return self
    }
    
    private func tapKeyboardSearchButton() -> SearchRobot {
        button(id.searchKeyboardButtonText).tap()
        return self
    }
    
    class Verify: CoreElements {
        
        @discardableResult
        func messageExists(_ subject: String) -> SearchRobot {
            staticText(id.messageTitleLabelIdentifier).containsLabel(subject).wait().checkExists()
            return SearchRobot()
        }
        
        @discardableResult
        func draftMessageExists(_ subject: String) -> SearchRobot {
            staticText(id.messageTitleLabelIdentifier).containsLabel(subject).wait().checkExists()
            return SearchRobot()
        }
        
        @discardableResult
        func addressExists(_ sender: String, _ position: Int) -> SearchRobot {
            staticText(id.messageSenderLabelIdentifier).byIndex(position).checkContainsLabel(sender)
            return SearchRobot()
        }
    }
}

//
//  SearchRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 08.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

fileprivate let searchTextFieldIdentifier = "SearchViewController.searchTextField"
fileprivate let searchKeyboardButtonText = LocalString._general_search_placeholder
fileprivate let cancelButttonIdentifier = LocalString._general_cancel_button
fileprivate func draftCellIdentifier(_ subject: String) -> String { return "MailboxMessageCell.\(subject)".replacingOccurrences(of: " ", with: "_") }
fileprivate func messageCellIdentifier(_ subject: String) -> String { return "MailboxMessageCell.\(subject)" }


/**
 SearchRobot class contains actions and verifications for Search functionality.
 */
class SearchRobot {

    var verify: Verify! = Verify()
    
    func searchMessageText(_ subject: String) -> SearchRobot {
        return typeTextToSearch(subject)
            .tapKeyboardSearchButton()
    }
    
    func clickSearchedMessageBySubject(_ subject: String) -> MessageRobot {
        Element.wait.forCellWithIdentifier(messageCellIdentifier(subject.replacingOccurrences(of: " ", with: "_"))).tap()
        return MessageRobot()
    }
    
    func clickSearchedDraftBySubject(_ subject: String) -> ComposerRobot {
        Element.wait.forCellWithIdentifier(draftCellIdentifier(subject)).tap()
        return ComposerRobot()
    }

    func goBackToInbox() -> InboxRobot {
        Element.wait.forButtonWithIdentifier(cancelButttonIdentifier).tap()
        return InboxRobot()
    }
    
    func goBackToDrafts() -> DraftsRobot {
        Element.wait.forButtonWithIdentifier(cancelButttonIdentifier).tap()
        return DraftsRobot()
    }
    
    private func typeTextToSearch(_ text: String) -> SearchRobot {
        Element.wait.forTextFieldWithIdentifier(searchTextFieldIdentifier).typeText(text)
        return self
    }
    
    private func tapKeyboardSearchButton() -> SearchRobot {
        Element.wait.forButtonWithIdentifier(searchKeyboardButtonText).tap()
        return self
    }
    
    class Verify {
        
        @discardableResult
        func messageExists(_ subject: String) -> SearchRobot {
           Element.wait.forCellWithIdentifier(messageCellIdentifier(subject.replacingOccurrences(of: " ", with: "_")))
            return SearchRobot()
        }
        
        @discardableResult
        func draftMessageExists(_ subject: String) -> SearchRobot {
            Element.wait.forCellWithIdentifier(draftCellIdentifier(subject.replacingOccurrences(of: " ", with: "_")))
            return SearchRobot()
        }
        
        @discardableResult
        func addressExists(_ sender: String, _ position: Int) -> SearchRobot {
            let name: String = Element.cell.getAddressByIndex(position).replacingOccurrences(of: "\n", with: "")
            XCTAssertEqual(name,sender)
            return SearchRobot()
        }
    }
}

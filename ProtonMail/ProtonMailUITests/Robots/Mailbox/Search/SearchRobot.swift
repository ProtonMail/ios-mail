//
//  SearchRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 08.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let searchTextFieldIdentifier = "SearchViewController.searchTextField"
fileprivate let searchKeyboardButtonText = LocalString._general_search_placeholder
fileprivate func draftCellIdentifier(_ subject: String) -> String { return "MailboxMessageCell.\(subject)".replacingOccurrences(of: " ", with: "_") }

/**
 SearchRobot class contains actions and verifications for Search functionality.
 */
class SearchRobot {

    func searchMessageText(_ subject: String) -> SearchRobot {
        return typeTextToSearch(subject)
            .tapKeyboardSearchButton()
    }
    
    func clickSearchedDraftBySubject(_ subject: String) -> ComposerRobot {
        Element.wait.forCellWithIdentifier(draftCellIdentifier(subject)).tap()
        return ComposerRobot()
    }

    func goBackToInbox() -> InboxRobot {

        return InboxRobot()
    }
    
    private func typeTextToSearch(_ text: String) -> SearchRobot {
        Element.wait.forTextFieldWithIdentifier(searchTextFieldIdentifier).typeText(text)
        return self
    }
    private func tapKeyboardSearchButton() -> SearchRobot {
        Element.wait.forButtonWithIdentifier(searchKeyboardButtonText).tap()
        return self
    }
}

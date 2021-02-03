//
//  MenuRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 03.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

private let logoutCell = "MenuTableViewCell.\(LocalString._logout_title)"
private let logoutConfirmButton = NSLocalizedString("Log out", comment: "comment")
private let sentStaticText = "MenuTableViewCell.\(LocalString._menu_sent_title)"
private let contactsStaticText = "MenuTableViewCell.\(LocalString._menu_contacts_title)"
private let draftsStaticText = "MenuTableViewCell.\(LocalString._menu_drafts_title)"
private let inboxStaticText = "MenuTableViewCell.\(LocalString._menu_inbox_title)"
private let settingsStaticText = "MenuTableViewCell.\(LocalString._menu_settings_title)"
private let reportBugStaticText = "MenuTableViewCell.Report_Bugs"
private let spamStaticText = "MenuTableViewCell.\(LocalString._menu_spam_title)"
private let trashStaticText = "MenuTableViewCell.\(LocalString._menu_trash_title)"
private let sidebarHeaderViewOtherIdentifier = "MenuViewController.headerView"
private let manageAccountsStaticTextIdentifier = "MenuButtonViewCell.\(LocalString._menu_manage_accounts.replaceSpaces())"
private func userAccountCellIdentifier(_ email: String) -> String { return "MenuUserViewCell.\(email)" }
private func shortNameStaticTextdentifier(_ email: String) -> String { return "\(email).shortName" }
private func displayNameStaticTextdentifier(_ email: String) -> String { return "\(email).displayName" }
private func folderLabelCellIdentifier(_ name: String) -> String { return "MenuLabelViewCell.\(name)" }

/**
 Represents Menu view.
*/
class MenuRobot {
    
    func logoutUser() -> LoginRobot {
        return logout()
            .confirmLogout()
    }
    
    @discardableResult
    func sent() -> SentRobot {
        Element.wait.forCellWithIdentifier(sentStaticText, file: #file, line: #line).tap()
        return SentRobot()
    }
    
    @discardableResult
    func contacts() -> ContactsRobot {
        Element.wait.forCellWithIdentifier(contactsStaticText, file: #file, line: #line).tap()
        return ContactsRobot()
    }
    
    func drafts() -> DraftsRobot {
        Element.wait.forCellWithIdentifier(draftsStaticText, file: #file, line: #line).tap()
        return DraftsRobot()
    }
    
    func inbox() -> DraftsRobot {
        Element.wait.forCellWithIdentifier(inboxStaticText, file: #file, line: #line).tap()
        return DraftsRobot()
    }
    
    func spams() -> SpamRobot {
        Element.wait.forCellWithIdentifier(spamStaticText, file: #file, line: #line).tap()
        return SpamRobot()
    }
    
    func trash() -> TrashRobot {
        Element.wait.forCellWithIdentifier(trashStaticText, file: #file, line: #line).tap()
        return TrashRobot()
    }
    
    func accountsList() -> MenuAccountListRobot {
        Element.wait.forOtherFieldWithIdentifier(sidebarHeaderViewOtherIdentifier, file: #file, line: #line).tap()
        return MenuAccountListRobot()
    }
    
    func folderOrLabel(_ name: String) -> LabelFolderRobot {
        Element.wait.forCellWithIdentifier(folderLabelCellIdentifier(name.replacingOccurrences(of: " ", with: "_")), file: #file, line: #line).tap()
        return LabelFolderRobot()
    }
    
    @discardableResult
    func reports() -> ReportRobot {
        Element.wait.forCellWithIdentifier(reportBugStaticText, file: #file, line: #line).tap()
        return ReportRobot()
    }
    
    func settings() -> SettingsRobot {
        Element.wait.forCellWithIdentifier(settingsStaticText, file: #file, line: #line).tap()
        return SettingsRobot()
    }
    
    private func logout() -> MenuRobot {
        Element.wait.forCellWithIdentifier(logoutCell).tap()
        return self
    }
    
    private func confirmLogout() -> LoginRobot {
        Element.button.tapByIdentifier(logoutConfirmButton)
        return LoginRobot()
    }
    
    /**
     MenuAccountListRobot class contains actions and verifications for Account list functionality inside Menu drawer
     */
    class MenuAccountListRobot {
        
        var verify: Verify! = nil
        
        init() {
            verify = Verify()
        }

        func manageAccounts() -> AccountManagerRobot {
            Element.wait.forCellWithIdentifier(manageAccountsStaticTextIdentifier, file: #file, line: #line).tap()
            return AccountManagerRobot()
        }

        func switchToAccount(_ user: User) -> InboxRobot {
            Element.wait.forCellWithIdentifier(userAccountCellIdentifier(user.email), file: #file, line: #line).tap()
            return InboxRobot()
        }

        /**
         Contains all the validations that can be performed by [MenuAccountListRobot].
         */
        class Verify {

            func accountAdded(_ user: User) {
                Element.wait.forCellWithIdentifier(userAccountCellIdentifier(user.email), file: #file, line: #line)
                Element.wait.forStaticTextFieldWithIdentifier(displayNameStaticTextdentifier(user.email), file: #file, line: #line)
                Element.wait.forStaticTextFieldWithIdentifier(displayNameStaticTextdentifier(user.email), file: #file, line: #line)
            }
            
            func accountShortNameIsCorrect(_ user: User, _ shortName: String) {
                Element.wait.forStaticTextFieldWithIdentifier(shortNameStaticTextdentifier(user.email), file: #file, line: #line)
                    .assertWithLabel(shortName)
            }
        }
    }
}

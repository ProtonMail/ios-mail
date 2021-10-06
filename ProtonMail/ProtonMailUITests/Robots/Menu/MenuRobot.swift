//
//  MenuRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 03.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import ProtonCore_CoreTranslation
import ProtonCore_TestingToolkit
import pmtest

fileprivate struct id {
    static let logoutCell = "MenuItemTableViewCell.Sign_out"
    static let logoutConfirmButton = NSLocalizedString("Log out", comment: "comment")
    static let inboxStaticText = "MenuItemTableViewCell.\(LocalString._menu_inbox_title)"
    static let reportBugStaticText = "MenuItemTableViewCell.Report_Bugs"
    static let spamStaticText = "MenuItemTableViewCell.\(LocalString._menu_spam_title)"
    static let trashStaticText = "MenuItemTableViewCell.\(LocalString._menu_trash_title)"
    static let sentStaticText = "MenuItemTableViewCell.\(LocalString._menu_sent_title)"
    static let contactsStaticText = "MenuItemTableViewCell.\(LocalString._menu_contacts_title)"
    static let draftsStaticText = "MenuItemTableViewCell.\(LocalString._menu_drafts_title)"
    static let settingsStaticText = "MenuItemTableViewCell.\(LocalString._menu_settings_title)"
    static let subscriptionStaticText = "MenuItemTableViewCell.\(LocalString._menu_service_plan_title)"
    static let sidebarHeaderViewOtherIdentifier = "MenuViewController.primaryUserview"
    static let manageAccountsStaticTextIdentifier = "MenuButtonViewCell.\(LocalString._menu_manage_accounts.replaceSpaces())"
    static let primaryUserViewIdentifier = "MenuViewController.primaryUserview"
    static let iapErrorAlertTitle = LocalString._general_alert_title
    static let iapErrorAlertMessage = LocalString._iap_unavailable
    static let forceUpgrateAlertTitle = CoreString._fu_alert_title
    static let forceUpgrateAlertMessage = "Test error description"
    static let forceUpgrateLearnMoreButton = CoreString._fu_alert_learn_more_button
    static let forceUpgrateUpdateButton = CoreString._fu_alert_update_button
    static func userAccountCellIdentifier(_ email: String) -> String { return "MenuUserViewCell.\(email)" }
    static func shortNameStaticTextdentifier(_ email: String) -> String { return "\(email).shortName" }
    static func displayNameStaticTextdentifier(_ email: String) -> String { return "\(email).displayName" }
    static func folderLabelCellIdentifier(_ name: String) -> String { return "MenuLabelViewCell.\(name)" }
}

/**
 Represents Menu view.
*/
class MenuRobot: CoreElements {
    
    func logoutUser() -> LoginRobot {
        return logout()
            .confirmLogout()
    }
    
    @discardableResult
    func sent() -> SentRobot {
        cell(id.sentStaticText).tap()
        return SentRobot()
    }
    
    @discardableResult
    func contacts() -> ContactsRobot {
        cell(id.contactsStaticText).swipeUpUntilVisible().tap()
        return ContactsRobot()
    }
    
    @discardableResult
    func subscriptionAsHumanVerification() -> HumanVerificationRobot {
        // fake subscription item leads to human verification (by http mock)
        cell(id.subscriptionStaticText).tap()
        return HumanVerificationRobot()
    }
    
    func subscriptionAsForceUpgrade() -> MenuRobot{
        // fake subscription item leads to force upgrade (by http mock)
        cell(id.subscriptionStaticText).tap()
        return MenuRobot()
    }
    
    func drafts() -> DraftsRobot {
        cell(id.draftsStaticText).tap()
        return DraftsRobot()
    }
    
    func inbox() -> InboxRobot {
        cell(id.inboxStaticText).tap()
        return InboxRobot()
    }
    
    func spams() -> SpamRobot {
        cell(id.spamStaticText).tap()
        return SpamRobot()
    }
    
    func trash() -> TrashRobot {
        cell(id.trashStaticText).tap()
        return TrashRobot()
    }
    
    func accountsList() -> MenuAccountListRobot {
        button(id.sidebarHeaderViewOtherIdentifier).tap()
        return MenuAccountListRobot()
    }
    
    func folderOrLabel(_ name: String) -> LabelFolderRobot {
        cell(id.folderLabelCellIdentifier(name.replacingOccurrences(of: " ", with: "_"))).tap()
        return LabelFolderRobot()
    }
    
    @discardableResult
    func reports() -> ReportRobot {
        cell(id.reportBugStaticText).swipeUpUntilVisible().tap()
        return ReportRobot()
    }
    
    func settings() -> SettingsRobot {
        cell(id.settingsStaticText).swipeUpUntilVisible().tap()
        return SettingsRobot()
    }
    
    private func logout() -> MenuRobot {
        cell(id.logoutCell).swipeUpUntilVisible().tap()
        return self
    }
    
    private func confirmLogout() -> LoginRobot {
        button(id.logoutConfirmButton).tap()
        return LoginRobot()
    }
    
    /**
     MenuAccountListRobot class contains actions and verifications for Account list functionality inside Menu drawer
     */
    class MenuAccountListRobot: CoreElements {
        
        var verify = Verify()

        func manageAccounts() -> AccountManagerRobot {
            cell(id.manageAccountsStaticTextIdentifier).tap()
            return AccountManagerRobot()
        }

        func switchToAccount(_ user: User) -> InboxRobot {
            cell(id.userAccountCellIdentifier(user.email)).tap()
            return InboxRobot()
        }

        /**
         Contains all the validations that can be performed by [MenuAccountListRobot].
         */
        class Verify: CoreElements {

            func accountAdded(_ user: User) {
                cell(id.userAccountCellIdentifier(user.email)).wait().checkExists()
                staticText(id.displayNameStaticTextdentifier(user.email)).wait().checkExists()
                staticText(id.displayNameStaticTextdentifier(user.email)).wait().checkExists()
            }
            
            func accountShortNameIsCorrect(_ shortName: String) {
                staticText(shortName).wait().checkExists()
            }
        }
    }
    
    @discardableResult
    func paymentsErrorDialog() -> PaymentsErrorDialogRobot {
        return PaymentsErrorDialogRobot()
    }
    
    class PaymentsErrorDialogRobot {
        
        let verify = Verify()
        
        class Verify: CoreElements {
            func invalidCredentialDialogDisplay() {
                staticText(id.iapErrorAlertTitle).wait().checkExists()
                staticText(id.iapErrorAlertMessage).wait().checkExists()
            }
        }
    }
    
    @discardableResult
    func forceUpgradeDialog() -> ForceUpgradeDialogRobot {
        return ForceUpgradeDialogRobot()
    }
    
    class ForceUpgradeDialogRobot: CoreElements {
        
        let verify = Verify()
        
        class Verify: CoreElements {
            @discardableResult
            func checkDialog() -> ForceUpgradeDialogRobot {
                staticText(id.forceUpgrateAlertTitle).wait().checkExists()
                staticText(id.forceUpgrateAlertMessage).wait().checkExists()
                return ForceUpgradeDialogRobot()
            }
        }

        @discardableResult
        func learnMoreButtonTap() -> ForceUpgradeDialogRobot {
            button(id.forceUpgrateLearnMoreButton).tap()
            return ForceUpgradeDialogRobot()
        }

        @discardableResult
        func upgradeButtonTap() -> ForceUpgradeDialogRobot {
            button(id.forceUpgrateUpdateButton).tap()
            return ForceUpgradeDialogRobot()
        }

        func back() -> ForceUpgradeDialogRobot {
            XCUIApplication().activate()
            return ForceUpgradeDialogRobot()
        }
    }
}

//
//  AccountManagerRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 25.08.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest
import ProtonCore_TestingToolkit

fileprivate struct id {
    static let addAccountCellIdentifier = "addAccountLabel"
    static let removeAllButtonIdentifier = "UINavigationItem.rightBarButtonItem"
    static let swipeUserCellLogoutButtonIdentifier = "Log out"
    static let swipeUserCellDeleteButtonIdentifier = "Delete"
    static let removeAllLabel = "Remove All"
    static func userAccountCellIdentifier(_ email: String) -> String { return "AccountManagerUserCell.\(email)" }
    static func loggedOutUserAccountCellIdentifier(_ email: String) -> String { return "AccountManagerUserCell.\(email)_(logged_out)" }
}

/**
 Represents Account Manager view.
*/
class AccountManagerRobot: CoreElements {
    
    var verify = Verify()
    
    func addAccount() -> ConnectAccountRobot {
        staticText(id.addAccountCellIdentifier).tap()
        return ConnectAccountRobot()
    }

    func logoutAccount(_ email: String) -> AccountManagerRobot {
        return swipeLeft(email)
            .logout()
            .confirmLogout()
    }
    
    func deleteAccount(_ email: String) -> AccountManagerRobot {
        return swipeLeftToDelete(email)
            .remove()
            .confirmRemove()
    }
    
    func removeAllAccounts() -> LoginRobot {
        return removeAll()
            .confirmRemoveAll()
    }
    
    private func removeAll() -> RemoveAllAlertRobot {
        button(id.removeAllLabel).tap()
        return RemoveAllAlertRobot()
    }
    
    private func swipeLeft(_ email: String) -> AccountManagerRobot {
        cell(id.userAccountCellIdentifier(email)).swipeLeft()
        return AccountManagerRobot()
    }
    
    private func swipeLeftToDelete(_ email: String) -> AccountManagerRobot {
        cell(id.loggedOutUserAccountCellIdentifier(email)).swipeLeft()
        return AccountManagerRobot()
    }

    private func logout() -> LogoutAccountAlertRobot {
        button(id.swipeUserCellLogoutButtonIdentifier).tap()
        return LogoutAccountAlertRobot()
    }

    private func remove() -> RemoveAccountAlertRobot {
        button(id.swipeUserCellDeleteButtonIdentifier).tap()
        return RemoveAccountAlertRobot()
    }
    
    /**
     RemoveAllAlertRobot class contains actions for Remove all accounts alert.
     */
    class RemoveAllAlertRobot {
        
        func confirmRemoveAll() -> LoginRobot {
            app.alerts.buttons.element(boundBy: 1).tap()
            return LoginRobot()
        }
    }
    
    /**
     RemoveAllAlertRobot class contains actions for Remove all accounts alert.
     */
    class RemoveAccountAlertRobot {
        
        func confirmRemove() -> AccountManagerRobot {
            app.alerts.buttons.element(boundBy: 1).tap()
            return AccountManagerRobot()
        }
    }
    
    /**
     RemoveAllAlertRobot class contains actions for Remove all accounts alert.
     */
    class LogoutAccountAlertRobot: CoreElements {
        
        func confirmLogout() -> AccountManagerRobot {
            app.alerts.buttons.element(boundBy: 1).tap()
            return AccountManagerRobot()
        }
        
        func confirmLogoutWithMultipleAccounts() -> AccountManagerRobot {
            app.alerts.buttons.element(boundBy: 1).tap()
            return AccountManagerRobot()
        }
    }

    /**
    * Contains all the validations that can be performed by [AccountManagerRobot].
    */
    class Verify: CoreElements {
        
        func accountLoggedOut(_ email: String) {
            cell(id.loggedOutUserAccountCellIdentifier(email)).wait().checkExists()
        }
        
        func accountRemoved(_ email: String) {
            cell(id.loggedOutUserAccountCellIdentifier(email)).waitUntilGone()
        }
        
        func switchedToAccount(_ account: String) {
            ///TODO: add implementation
        }
    }
}

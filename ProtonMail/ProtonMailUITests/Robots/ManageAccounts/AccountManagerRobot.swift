//
//  AccountManagerRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 25.08.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

fileprivate let addAccountCellIdentifier = "addAccount"
fileprivate let removeAllButtonIdentifier = "removeAllButton"
fileprivate let swipeUserCellTrailingButtonIdentifier = "trailing0"

/**
 Represents Account Manager view.
*/
class AccountManagerRobot {
    
    var verify: Verify! = nil
    
    init() {
        verify = Verify()
    }
    
    func addAccount() -> ConnectAccountRobot {
        Element.cell.tapByIdentifier(addAccountCellIdentifier)
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
        Element.wait.forButtonWithIdentifier(removeAllButtonIdentifier).tap()
        return RemoveAllAlertRobot()
    }
    
    private func swipeLeft(_ email: String) -> AccountManagerRobot {
        Element.cell.swipeLeftByIdentifier("\(email)_UserCell")
        return AccountManagerRobot()
    }
    
    private func swipeLeftToDelete(_ email: String) -> AccountManagerRobot {
        Element.wait.forCellWithIdentifier("\(email)_UserCell_LoggedOut").swipeLeft()
        return AccountManagerRobot()
    }

    private func logout() -> LogoutAccountAlertRobot {
        Element.wait.forButtonWithIdentifier(swipeUserCellTrailingButtonIdentifier).tap()
        return LogoutAccountAlertRobot()
    }

    private func remove() -> RemoveAccountAlertRobot {
        Element.button.tapByIdentifier(swipeUserCellTrailingButtonIdentifier)
        return RemoveAccountAlertRobot()
    }

    private func confirmLastAccountLogout() -> LoginRobot {
     
        return LoginRobot()
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
    class LogoutAccountAlertRobot {
        
        func confirmLogout() -> AccountManagerRobot {
            app.alerts.buttons.element(boundBy: 1).tap()
            return AccountManagerRobot()
        }
        
        func confirmLogoutWithMultipleAccounts() -> AccountManagerRobot {
            app.alerts.buttons.element(boundBy: 1).tap()
            return AccountManagerRobot()
        }
        
        func confirmLastAccountLogout() -> LoginRobot {
            
            return LoginRobot()
        }
    }

    /**
    * Contains all the validations that can be performed by [AccountManagerRobot].
    */
    class Verify {

        func manageAccountsOpened() {
        }

        func switchedToAccount(_ username: String) {
            
        }
        
        func accountLoggedOut(_ email: String) {
            Element.wait.forCellWithIdentifier("\(email)_UserCell_LoggedOut", file: #file, line: #line)
        }
        
        func accountRemoved(_ email: String) {
            Element.wait.forCellWithIdentifierToDisappear("\(email)_UserCell_LoggedOut", file: #file, line: #line)
        }
    }
}

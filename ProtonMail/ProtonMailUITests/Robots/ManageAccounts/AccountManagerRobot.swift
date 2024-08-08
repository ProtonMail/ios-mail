//
//  AccountManagerRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 25.08.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion
import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUITestsLogin

fileprivate struct id {
    static let addAccountButtonIdentifier = "UINavigationItem.rightBarButtonItem"
    static let removeAllButtonIdentifier = "UINavigationItem.rightBarButtonItem"
    static let closeManageAccountsButtonIdentifier = "UINavigationItem.leftBarButtonItem"
    static let swipeUserCellLogoutButtonIdentifier = "Log out"
    static let swipeUserCellDeleteButtonIdentifier = "Delete"
    static let removeAllLabel = "Remove All"
    static let signOutButtonLabel = LocalString._menu_signout_title
    static let confirmSignOutButtonLabel = LocalString._menu_signout_title
    static let removeAccountButtonLabel = "Remove account from this device"
    static let confirmRemoveButtonLabel = LocalString._general_remove_button
    static let closeManageAccountsButtonLabel = "Dismiss account switcher"
    static func userAccountMoreBtnIdentifier(_ mail: String) -> String {
        return "\(mail).moreBtn"
    }
    static func loggedOutUserAccountCellIdentifier(_ mail: String) -> String { return "AccountmanagerUserCell.\(mail)" }
}

/**
 Represents Account Manager view.
*/
class AccountManagerRobot: CoreElements {
    
    var verify = Verify()
    
    func addAccount() -> ConnectAccountRobot {
        button(id.addAccountButtonIdentifier).firstMatch().tap()
        return ConnectAccountRobot()
    }

    func logoutPrimaryAccount(_ user: User) -> InboxRobot {
        return tapMore(user.name)
            .signOut()
            .confirmSignOutPrimary()
    }
    
    func logoutSecondaryAccount(_ user: User) -> AccountManagerRobot {
        return tapMore(user.name)
            .signOut()
            .confirmSignOut()
    }
    
    func deleteAccount(_ user: User) -> AccountManagerRobot {
        return tapMore(user.name)
            .removeAccount()
            .confirmRemove()
    }
    
    func removeAllAccounts() -> LoginRobot {
        return removeAll()
            .confirmRemoveAll()
    }
    
    func closeManageAccounts() -> InboxRobot {
        button(id.closeManageAccountsButtonIdentifier).firstMatch().tap()
        return InboxRobot()
    }
    
    private func removeAll() -> AccountManagerRemoveAllAlertRobot {
        button(id.removeAllLabel).firstMatch().tap()
        return AccountManagerRemoveAllAlertRobot()
    }
    
    private func swipeLeftToDelete(_ email: String) -> AccountManagerRobot {
        cell(id.loggedOutUserAccountCellIdentifier(email)).firstMatch().swipeLeft()
        return AccountManagerRobot()
    }
    
    private func tapMore(_ email: String) -> AccountManagerRobot {
        button(id.userAccountMoreBtnIdentifier(email)).firstMatch().tap()
        return AccountManagerRobot()
    }
    
    private func signOut() -> AccountManagerRobot {
        button(id.signOutButtonLabel).firstMatch().tap()
        return AccountManagerRobot()
    }
    
    private func confirmSignOutPrimary() -> InboxRobot {
        button(id.confirmSignOutButtonLabel).firstMatch().tap()
        return InboxRobot()
    }
    
    private func confirmSignOut() -> AccountManagerRobot {
        button(id.confirmSignOutButtonLabel).firstMatch().tap()
        return AccountManagerRobot()
    }
    
    private func removeAccount() -> AccountManagerRobot {
        button(id.removeAccountButtonLabel).firstMatch().tap()
        return AccountManagerRobot()
    }
    
    private func confirmRemove() -> AccountManagerRobot {
        button(id.confirmRemoveButtonLabel).firstMatch().tap()
        return AccountManagerRobot()
    }

    /**
    * Contains all the validations that can be performed by [AccountManagerRobot].
    */
    class Verify: CoreElements {
        
        func accountLoggedOut(_ email: String) {
            cell(id.loggedOutUserAccountCellIdentifier(email)).waitUntilExists().checkExists()
        }
        
        func accountRemoved(_ user: User) {
            cell(id.loggedOutUserAccountCellIdentifier(user.name)).waitUntilGone(time: 15)
        }
    }
}

/**
 RemoveAllAlertRobot class contains actions for Remove all accounts alert.
 */
class AccountManagerRemoveAllAlertRobot: CoreElements {

    func confirmRemoveAll() -> LoginRobot {
        app.alerts.buttons.element(boundBy: 1).tap()
        return LoginRobot()
    }
}

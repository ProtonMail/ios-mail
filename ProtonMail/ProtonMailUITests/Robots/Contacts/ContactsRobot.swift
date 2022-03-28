//
//  ContactsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 05.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let addContactAlertButtonText = LocalString._contacts_new_contact
    static let addGroupAlertButtonText = LocalString._contact_groups_new
    static let deleteContactAlertButtonText = LocalString._delete_contact
    static let deleteGroupAlertButtonText = LocalString._contact_groups_delete
    static let deleteButtonText = LocalString._general_delete_action
    static let contactsTabBarButtonIdentifier = "UITabBar.\(LocalString._contacts_title)"
    static let groupsTabBarButtonIdentifier = "UITabBar.\(LocalString._menu_contact_group_title)"
    static func contactCellIdentifier(_ name: String) -> String { return "ContactsTableViewCell.\(name)" }
    static func groupCellIdentifier(_ name: String) -> String { return "ContactGroupsViewCell.\(name)" }
    static func groupCellSendImailButtonIdentifier(_ name: String) -> String { return "\(name).sendButton" }
    static let menuButtonIdentifier = "UINavigationItem.openMenu"
    static let addContactNavBarButtonText = LocalString._general_create_action
    static let importContactNavBarButtonIdentifier = "UINavigationItem.importButton"
    static let contactsTableViewIdentifier = "ContactsViewController.tableView"
}

/**
 ContactsRobot class contains actions and verifications for Contacts functionality.
 */
class ContactsRobot: CoreElements {
    
    var verify = Verify()

    func addContact() -> AddContactRobot {
        return add().contact()
    }

    func addGroup() -> AddContactGroupRobot {
        return add().group()
    }

    func groupsView() -> ContactsGroupView {
        button(id.groupsTabBarButtonIdentifier).tap()
        return ContactsGroupView()
    }

    func contactsView() -> ContactsView {
        button(id.contactsTabBarButtonIdentifier).tap()
        return ContactsView()
    }

    func menuDrawer() -> MenuRobot {
        button(id.menuButtonIdentifier).tap()
        return MenuRobot()
    }
    
    private func add() -> ContactsRobot {
        button(id.addContactNavBarButtonText).tap()
        return ContactsRobot()
    }
    
    private func contact() -> AddContactRobot {
        staticText(id.addContactAlertButtonText).tap()
        return AddContactRobot()
    }
    
    private func group() -> AddContactGroupRobot {
        staticText(id.addGroupAlertButtonText).tap()
        return AddContactGroupRobot()
    }

    class ContactsView: CoreElements {
        
        var verify = Verify()
        
        func deleteContact(_ name: String) -> ContactsView {
            return swipeLeftToDelete(name)
                .clickDeleteButton()
                .confirmDeletion()
        }

        func clickContact(_ name: String) -> ContactDetailsRobot {
            cell(id.contactCellIdentifier(name)).swipeUpUntilVisible().waitForHittable().tap()
            return ContactDetailsRobot()
        }
        
        private func swipeLeftToDelete(_ name: String) -> ContactsView {
            cell(id.contactCellIdentifier(name)).swipeUpUntilVisible().swipeLeft()
            return ContactsView()
        }
        
        private func clickDeleteButton() -> ContactsView {
            button(id.deleteButtonText).tap()
            return ContactsView()
        }
        
        private func confirmDeletion() -> ContactsView {
            button(id.deleteContactAlertButtonText).tap()
            return self
        }
        
        class Verify: CoreElements {

            func contactExists(_ name: String) {
                cell(id.contactCellIdentifier(name)).wait().checkExists()
            }

            func contactDoesNotExists(_ name: String) {
                cell(id.contactCellIdentifier(name)).waitUntilGone()
            }
        }
    }

    class ContactsGroupView: CoreElements {
        
        var verify = Verify()

        func clickGroup(_ withName: String) -> GroupDetailsRobot {
            cell(id.groupCellIdentifier(withName)).swipeUpUntilVisible().tap()
            return GroupDetailsRobot()
        }

        func deleteGroup(_ withName: String) -> ContactsGroupView {
            return swipeLeftToDelete(withName)
                .clickDeleteButton()
                .confirmDeletion()
        }
        
        func sendGroupEmail(_ name: String) -> ComposerRobot {
            button(id.groupCellSendImailButtonIdentifier(name)).swipeDownUntilVisible().tap()
            return ComposerRobot()
        }
        
        private func swipeLeftToDelete(_ withName: String) -> ContactsGroupView {
            cell(id.groupCellIdentifier(withName)).swipeUpUntilVisible().swipeLeft()
            return self
        }
        
        private func clickDeleteButton() -> ContactsGroupView {
            button(id.deleteButtonText).tap()
            return self
        }
        
        private func confirmDeletion() -> ContactsGroupView {
            button(id.deleteGroupAlertButtonText).tap()
            return self
        }

        class Verify: CoreElements {

            func groupDoesNotExists(_ name: String) {
                cell(id.groupCellIdentifier(name)).waitUntilGone()
            }
        }
    }

    /**
     * Contains all the validations that can be performed by [ContactsRobot].
     */
    class Verify: CoreElements {

        func contactsOpened() {
            table(id.contactsTableViewIdentifier).wait().checkExists()
        }
    }
}

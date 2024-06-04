//
//  ContactsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 05.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion
import XCTest

fileprivate struct id {
    static let addContactAlertButtonText = "New contact"
    static let addGroupAlertButtonText = "New group"
    static let deleteContactAlertButtonText = "Delete contact"
    static let deleteGroupAlertButtonText = "Delete contact group"
    static let deleteButtonText = "Delete"
    static let contactsTabBarButtonIdentifier = "UITabBar.Contacts"
    static let groupsTabBarButtonIdentifier = "UITabBar.Groups"
    static func contactCellIdentifier(_ name: String) -> String { return "ContactsTableViewCell.\(name)" }
    static func groupCellIdentifier(_ name: String) -> String { return "ContactGroupsViewCell.\(name)" }
    static func groupStaticTextIdentifier(_ name: String) -> String { return "\(name).nameLabel" }
    static func groupCellSendImailButtonIdentifier(_ name: String) -> String { return "\(name).sendButton" }
    static let menuButtonIdentifier = "Menu"
    static let addContactNavBarButtonText = "Create"
    static let importContactNavBarButtonIdentifier = "UINavigationItem.importButton"
    static let contactsTableViewIdentifier = "ContactsViewController.tableView"
}

/**
 ContactsRobot class contains actions and verifications for Contacts functionality.
 */
class ContactsRobot: CoreElements {

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
            cell(id.contactCellIdentifier(name)).inTable(table(id.contactsTableViewIdentifier)).swipeUpUntilVisible(maxAttempts: 20).waitForHittable().tap()
            return ContactDetailsRobot()
        }
        
        private func swipeLeftToDelete(_ name: String) -> ContactsView {
            var eventCount = 0
            while eventCount <= 3, !button(id.deleteButtonText).hittable() {
                cell(id.contactCellIdentifier(name)).inTable(table(id.contactsTableViewIdentifier)).firstMatch().swipeLeft()
                eventCount += 1
            }
            return ContactsView()
        }
        
        private func clickDeleteButton() -> ContactsView {
            button(id.deleteButtonText).waitForHittable().tap()
            return ContactsView()
        }
        
        private func confirmDeletion() -> ContactsView {
            button(id.deleteContactAlertButtonText).tap()
            return self
        }
        
        class Verify: CoreElements {

            func contactExists(_ name: String) {
                cell(id.contactCellIdentifier(name)).firstMatch().swipeUpUntilVisible().checkExists()
                cell(id.contactCellIdentifier(name)).firstMatch().checkIsHittable()
            }

            func contactDoesNotExists(_ name: String) {
                cell(id.contactCellIdentifier(name)).waitForNotHittable()
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
            button(id.groupCellSendImailButtonIdentifier(name)).swipeUpUntilVisible().tap()
            return ComposerRobot()
        }
        
        private func swipeLeftToDelete(_ withName: String) -> ContactsGroupView {
            scrollToTop()

            var eventCount = 0
            while eventCount <= 3, !button(id.deleteButtonText).hittable() {
                cell(id.groupCellIdentifier(withName))
                    .onChild(staticText(id.groupStaticTextIdentifier(withName)))
                    .waitForHittable()
                    .swipeLeft()

                eventCount += 1
            }

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

        private func scrollToTop() {
            let systemaApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            systemaApp.statusBars.allElementsBoundByIndex.first(where: { $0.isHittable })?.tap()
        }

        class Verify: CoreElements {

            func groupDoesNotExists(_ name: String) {
                XCTAssertFalse(cell(id.groupCellIdentifier(name)).hittable())
            }
        }
    }

    /**
     * Contains all the validations that can be performed by [ContactsRobot].
     */
    class Verify: CoreElements {

        func contactsOpened() {
            table(id.contactsTableViewIdentifier).waitUntilExists().checkExists()
        }
    }
}

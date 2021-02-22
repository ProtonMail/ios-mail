//
//  GroupDetailsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 05.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let editNavBarButtonText = LocalString._general_edit_action
fileprivate let backToContactsNavBarButtonText = LocalString._menu_contact_group_title

/**
 GroupDetailsRobot class contains actions and verifications for Contacts functionality.
 */
class GroupDetailsRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify() }

    func editGroup() -> AddContactGroupRobot {
        Element.wait.forButtonWithIdentifier(editNavBarButtonText, file: #file, line: #line).tap()
        return AddContactGroupRobot()
    }

    func goBackToContacts() -> ContactsRobot {
        Element.wait.forButtonWithIdentifier(backToContactsNavBarButtonText, file: #file, line: #line).tap()
        return ContactsRobot()
    }

    /**
     Contains all the validations that can be performed by GroupDetailsRobot.
     */
    class Verify {}
}


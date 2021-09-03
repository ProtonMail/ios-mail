//
//  GroupDetailsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 05.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let editNavBarButtonText = LocalString._general_edit_action
    static let backToContactsNavBarButtonText = LocalString._menu_contact_group_title
}

/**
 GroupDetailsRobot class contains actions and verifications for Contacts functionality.
 */
class GroupDetailsRobot: CoreElements {

    func editGroup() -> AddContactGroupRobot {
        button(id.editNavBarButtonText).tap()
        return AddContactGroupRobot()
    }

    func goBackToContacts() -> ContactsRobot {
        button(id.backToContactsNavBarButtonText).tap()
        return ContactsRobot()
    }
}


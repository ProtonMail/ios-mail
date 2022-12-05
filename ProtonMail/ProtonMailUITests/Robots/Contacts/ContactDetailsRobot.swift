//
//  ContactDetailsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 05.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let editContactNavBarButtonIdentifier = "UINavigationItem.rightBarButtonItem"
    static let backToContactsNavBarButtonIdentifier = LocalString._contacts_title
    static let emailContactStaticTextIdentifier = "ContactDetailViewController.emailContactLabel"
}

/**
 ContactDetailsRobot class contains actions and verifications for Contacts functionality.
 */
class ContactDetailsRobot: CoreElements {

    func editContact() -> AddContactRobot {
        button(id.editContactNavBarButtonIdentifier).tap()
        return AddContactRobot()
    }

    func goBackToContacts() -> ContactsRobot {
        button(id.backToContactsNavBarButtonIdentifier).tap()
        return ContactsRobot()
    }
    
    func emailContact() -> ComposerRobot {
        staticText(id.emailContactStaticTextIdentifier).tap()
        return ComposerRobot()
    }
}

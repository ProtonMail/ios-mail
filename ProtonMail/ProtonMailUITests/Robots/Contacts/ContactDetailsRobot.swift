//
//  ContactDetailsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 05.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let editContactNavBarButtonIdentifier = "UINavigationItem.didTapEditButtonWithSender"
fileprivate let backToContactsNavBarButtonIdentifier = LocalString._contacts_title
fileprivate let emailContactStaticTextIdentifier = "ContactDetailViewController.emailContactLabel"
/**
 ContactDetailsRobot class contains actions and verifications for Contacts functionality.
 */
class ContactDetailsRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify() }

    func editContact() -> AddContactRobot {
        Element.wait.forButtonWithIdentifier(editContactNavBarButtonIdentifier, file: #file, line: #line).tap()
        return AddContactRobot()
    }

    func goBackToContacts() -> ContactsRobot {
        Element.wait.forButtonWithIdentifier(backToContactsNavBarButtonIdentifier, file: #file, line: #line).tap()
        return ContactsRobot()
    }
    
    func emailContact() -> ComposerRobot {
        Element.wait.forStaticTextFieldWithIdentifier(emailContactStaticTextIdentifier, file: #file, line: #line).tap()
        return ComposerRobot()
    }

    /**
     Contains all the validations that can be performed by ContactDetailsRobot.
     */
    class Verify {}
}

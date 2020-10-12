//
//  AddContactRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let saveNavBarButtonIdentifier = "UINavigationItem.doneAction"
fileprivate let cancelNavBarButtonIdentifier = "UINavigationItem.cancelAction"
fileprivate let nameTextFieldIdentifier = "ContactEditViewController.displayNameField"
fileprivate let addNewEmailCellIdentifier = "ContactEditAddCell.Add_new_email"
fileprivate let emailTextFieldIdentifier = "Email_address.valueField"

/**
 AddContactRobot class contains actions and verifications for Add/Edit Contacts.
 */
class AddContactRobot {

    func setNameEmailAndSave(_ name: String, _ email: String) -> ContactsRobot {
        return displayName(name)
            .addNewEmail()
            .email(email)
            .save()
    }

    func editNameEmailAndSave(_ name: String, _ email: String) -> ContactDetailsRobot {
        editDisplayName(name)
            .editEmailmail(email)
            .save()
        return ContactDetailsRobot()
    }

    private func displayName(_ name: String) -> AddContactRobot {
        Element.wait.forTextFieldWithIdentifier(nameTextFieldIdentifier, file: #file, line: #line)
            .click()
            .typeText(name)
        return self
    }
    
    private func editDisplayName(_ name: String) -> AddContactRobot {
        Element.wait.forTextFieldWithIdentifier(nameTextFieldIdentifier, file: #file, line: #line)
            .click()
            .clear()
            .typeText(name)
        return self
    }
    
    private func addNewEmail() -> AddContactRobot {
        Element.wait.forCellWithIdentifier(addNewEmailCellIdentifier, file: #file, line: #line).tap()
        return self
    }

    private func email(_ email: String) -> AddContactRobot {
        Element.wait.forTextFieldWithIdentifier(emailTextFieldIdentifier, file: #file, line: #line).click().typeText(email)
        return self
    }
    
    private func editEmailmail(_ email: String) -> AddContactRobot {
        Element.wait.forTextFieldWithIdentifier(emailTextFieldIdentifier, file: #file, line: #line)
            .click()
            .clear()
            .typeText(email)
        return self
    }

    @discardableResult
    private func save() -> ContactsRobot {
        Element.wait.forButtonWithIdentifier(saveNavBarButtonIdentifier, file: #file, line: #line).tap()
        return ContactsRobot()
    }
}

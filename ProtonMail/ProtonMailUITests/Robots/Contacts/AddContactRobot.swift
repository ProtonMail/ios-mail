//
//  AddContactRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import pmtest
import ProtonMail

fileprivate struct id {
    static let saveNavBarButtonIdentifier = "ContactEditViewController.doneItem"
    static let cancelNavBarButtonIdentifier = "UINavigationItem.cancelAction"
    static let nameTextFieldIdentifier = "ContactEditViewController.displayNameField"
    static let addNewEmailCellIdentifier = "ContactEditAddCell.Add_new_email"
    static let emailTextFieldIdentifier = "Email_address.valueField"
}

/**
 AddContactRobot class contains actions and verifications for Add/Edit Contacts.
 */
class AddContactRobot: CoreElements {

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
        textField(id.nameTextFieldIdentifier).tap().typeText(name)
        return self
    }
    
    private func editDisplayName(_ name: String) -> AddContactRobot {
        textField(id.nameTextFieldIdentifier).tap().clearText().typeText(name)
        return self
    }
    
    private func addNewEmail() -> AddContactRobot {
        cell(id.addNewEmailCellIdentifier).tap()
        return self
    }

    private func email(_ email: String) -> AddContactRobot {
        textField(id.emailTextFieldIdentifier).tap().typeText(email)
        return self
    }
    
    private func editEmailmail(_ email: String) -> AddContactRobot {
        textField(id.emailTextFieldIdentifier).tap().clearText().typeText(email)
        return self
    }

    @discardableResult
    private func save() -> ContactsRobot {
        button(id.saveNavBarButtonIdentifier).tap()
        return ContactsRobot()
    }
}

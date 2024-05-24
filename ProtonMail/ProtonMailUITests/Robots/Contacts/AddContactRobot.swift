//
//  AddContactRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import fusion

fileprivate struct id {
    static let saveNavBarButtonIdentifier = "ContactEditViewController.doneButton"
    static let cancelNavBarButtonIdentifier = "ContactEditViewController.cancelButton'"
    static let nameTextFieldIdentifier = "ContactEditViewController.customView.displayNameField"
    static let addNewEmailCellIdentifier = "ContactEditAddCell.Add_new_email"
    static let emailTextFieldIdentifier = "Email_address.valueField"
    static let deleteCellIdentifier = "ContactEditAddCell.Delete_contact"
    static let deleteContactButtonText = "Delete contact"
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
    
    func clickDeleteButton() -> AddContactRobot {
        cell(id.deleteCellIdentifier).waitForHittable().tap()
        return self
    }

    func confirmContactDeletion() -> ContactsRobot.ContactsView {
        button(id.deleteContactButtonText).waitForHittable().tap()
        return ContactsRobot.ContactsView()
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

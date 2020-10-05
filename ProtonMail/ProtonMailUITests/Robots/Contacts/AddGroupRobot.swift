//
//  AddGroupRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let saveNavBarButtonIdentifier = "ContactGroupEditViewController.saveButton"
fileprivate let contactGroupNameTextFieldIdentifier = "ContactGroupEditViewController.contactGroupNameLabel"
fileprivate let manageAddressesStaticText = LocalString._contact_groups_manage_addresses
fileprivate let deleteGroupText = LocalString._contact_groups_delete

/**
 AddContactGroupRobot class contains actions and verifications for Add/Edit Contact Groups.
 */
class AddContactGroupRobot {

    func editNameAndSave(_ name: String) -> GroupDetailsRobot {
        editGroupName(name).save()
        return GroupDetailsRobot()
    }

    func groupName(_ name: String) -> AddContactGroupRobot {
        Element.wait.forTextFieldWithIdentifier(contactGroupNameTextFieldIdentifier).tap()
        Element.wait.forTextFieldWithIdentifier(contactGroupNameTextFieldIdentifier).typeText(name)
        return self
    }
    
    @discardableResult
    func save() -> ContactsRobot {
        Element.wait.forButtonWithIdentifier(saveNavBarButtonIdentifier, file: #file, line: #line).tap()
        return ContactsRobot()
    }
    
    func manageAddresses() -> ManageAddressesRobot {
        Element.staticText.tapByIdentifier(manageAddressesStaticText)
        return ManageAddressesRobot()
    }
    
    func delete() -> ContactsRobot {
        Element.staticText.tapByIdentifier(deleteGroupText)
        return ContactsRobot()
    }

    private func confirmDeletion() -> ContactsRobot {
        return ContactsRobot()
    }
    
    private func editGroupName(_ name: String) -> AddContactGroupRobot {
        Element.wait.forTextFieldWithIdentifier(contactGroupNameTextFieldIdentifier).clear().typeText(name)
        return self
    }
}

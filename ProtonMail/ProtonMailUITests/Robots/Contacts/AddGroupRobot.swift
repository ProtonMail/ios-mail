//
//  AddGroupRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let saveNavBarButtonIdentifier = "ContactGroupEditViewController.saveButton"
    static let contactGroupNameTextFieldIdentifier = "ContactGroupEditViewController.contactGroupNameLabel"
    static let manageAddressesStaticText = LocalString._contact_groups_manage_addresses
    static let deleteGroupText = LocalString._contact_groups_delete
}

/**
 AddContactGroupRobot class contains actions and verifications for Add/Edit Contact Groups.
 */
class AddContactGroupRobot: CoreElements {

    func editNameAndSave(_ name: String) -> GroupDetailsRobot {
        editGroupName(name).saveContactSelection()
        return GroupDetailsRobot()
    }

    func typeGroupName(_ name: String) -> AddContactGroupRobot {
        textField(id.contactGroupNameTextFieldIdentifier).tap().typeText(name)
        return self
    }
    
    @discardableResult
    func saveContactSelection() -> ContactsRobot {
        button(id.saveNavBarButtonIdentifier).tap()
        return ContactsRobot()
    }

    func tapManageAddresses() -> ManageAddressesRobot {
        staticText(id.manageAddressesStaticText).tap()
        return ManageAddressesRobot()
    }
    
    func delete() -> ContactsRobot {
        staticText(id.deleteGroupText).tap()
        return ContactsRobot()
    }

    private func confirmDeletion() -> ContactsRobot {
        /// TODO
        return ContactsRobot()
    }
    
    private func editGroupName(_ name: String) -> AddContactGroupRobot {
        textField(id.contactGroupNameTextFieldIdentifier).tap().clearText().typeText(name)
        return self
    }
}

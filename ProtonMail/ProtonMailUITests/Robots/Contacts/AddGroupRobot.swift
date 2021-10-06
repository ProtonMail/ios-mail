//
//  AddGroupRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let saveNavBarButtonText = LocalString._general_save_action
    static let contactGroupNameTextFieldIdentifier = "ContactGroupEditViewController.contactGroupNameLabel"
    static let manageAddressesStaticText = LocalString._contact_groups_manage_addresses
    static let deleteGroupText = LocalString._contact_groups_delete
    static let doneButtonIdentifier = LocalString._general_done_button
}

/**
 AddContactGroupRobot class contains actions and verifications for Add/Edit Contact Groups.
 */
class AddContactGroupRobot: CoreElements {

    func editNameAndSave(_ name: String) -> GroupDetailsRobot {
        editGroupName(name).doneEditingName()
        return GroupDetailsRobot()
    }

    func typeGroupName(_ name: String) -> AddContactGroupRobot {
        textField(id.contactGroupNameTextFieldIdentifier).tap().typeText(name)
        return self
    }
    
    @discardableResult
    func saveContactSelection() -> ContactsRobot {
        button(id.saveNavBarButtonText).tap()
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
    
    @discardableResult
    func doneEditingName() -> ContactsRobot {
        button(id.doneButtonIdentifier).tap()
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

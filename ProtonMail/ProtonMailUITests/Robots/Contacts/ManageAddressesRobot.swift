//
//  ManageAddressesRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate func contactCellIdentifier(_ email: String) -> String { return "ContactGroupEditViewCell.\(email)" }
fileprivate let backButtonIdentifier = LocalString._contact_groups_add

/**
 ManageAddressesRobot class contains actions and verifications for Adding a Contact to Group.
 */
class ManageAddressesRobot {

    func addContactToGroup(_ withEmail: String) -> AddContactGroupRobot {
        return clickContact(withEmail).back()
    }
    
    func clickContact(_ withEmail: String) -> ManageAddressesRobot {
        Element.wait.forCellWithIdentifier(contactCellIdentifier(withEmail), file: #file, line: #line).tap()
        return self
    }

    private func back() -> AddContactGroupRobot {
        Element.button.tapByIdentifier(backButtonIdentifier)
        return AddContactGroupRobot()
    }
}

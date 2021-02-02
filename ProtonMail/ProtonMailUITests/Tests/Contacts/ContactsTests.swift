//
//  ContactsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

class ContactsTests : BaseTestCase {

    private var contactsRobot = ContactsRobot()
    private let loginRobot = LoginRobot()

    override func setUp() {
        super.setUp()
        contactsRobot = loginRobot
            .loginUser(testData.onePassUser)
            .menuDrawer()
            .contacts()
    }

    func testCreateContact() {
        let name = testData.alphaNumericString
        let email = testData.newEmailAddress
        contactsRobot
            .addContact()
            .setNameEmailAndSave(name, email)
            .contactsView()
            .deleteContact(name)
            .verify.contactDoesNotExists(name)
    }

    func testEditContact() {
        let name = testData.alphaNumericString
        let email = testData.newEmailAddress
        let editedName = testData.alphaNumericString
        let editedEmail = testData.newEmailAddress
        contactsRobot
            .addContact()
            .setNameEmailAndSave(name, email)
            .contactsView()
            .clickContact(name)
            .editContact()
            .editNameEmailAndSave(editedName, editedEmail)
            .goBackToContacts()
            .contactsView()
            .deleteContact(editedName)
            .verify.contactDoesNotExists(editedName)
    }

    func testDeleteContact() {
        let name = testData.alphaNumericString
        let email = testData.newEmailAddress
        contactsRobot
            .addContact()
            .setNameEmailAndSave(name, email)
            .contactsView()
            .deleteContact(name)
            .verify.contactDoesNotExists(name)
    }

    func testCreateGroup() {
        let contactEmail = testData.internalEmailTrustedKeys
        let groupName = testData.alphaNumericString
        contactsRobot
            .addGroup()
            .typeGroupName(groupName)
            .tapManageAddresses()
            .addContactToGroup(contactEmail.email)
            .saveContactSelection()
            .groupsView()
            .deleteGroup(groupName)
            .verify.groupDoesNotExists(groupName)
    }

    func testEditGroup() {
        let contactEmail = testData.internalEmailTrustedKeys
        let groupName = testData.alphaNumericString
        let newGroupName = testData.alphaNumericString
        contactsRobot
            .addGroup()
            .typeGroupName(groupName)
            .tapManageAddresses()
            .addContactToGroup(contactEmail.email)
            .saveContactSelection()
            .groupsView()
            .clickGroup(groupName)
            .editGroup()
            .editNameAndSave(newGroupName)
            .goBackToContacts()
            .groupsView()
            .deleteGroup(newGroupName)
            .verify.groupDoesNotExists(newGroupName)
    }

    func testDeleteGroup() {
        let contactEmail = testData.internalEmailTrustedKeys.email
        let groupName = testData.alphaNumericString
        contactsRobot
            .addGroup()
            .typeGroupName(groupName)
            .tapManageAddresses()
            .addContactToGroup(contactEmail)
            .saveContactSelection()
            .groupsView()
            .deleteGroup(groupName)
            .verify.groupDoesNotExists(groupName)
    }

    func testContactDetailSendMessage() {
        let subject = testData.messageSubject
        let contactName = testData.internalEmailTrustedKeys.email
        contactsRobot
            .contactsView()
            .clickContact(contactName)
            .emailContact()
            .sendMessageToContact(subject)
            .goBackToContacts()
            .menuDrawer()
            .sent()
            .verify.messageWithSubjectExists(subject)
    }

    func testContactGroupSendMessage() {
        let subject = testData.messageSubject
        let groupName = "TestAutomation"
        contactsRobot
            .groupsView()
            .sendGroupEmail(groupName)
            .sendMessageToGroup(subject)
            .menuDrawer()
            .sent()
            .verify.messageWithSubjectExists(subject)
    }
}

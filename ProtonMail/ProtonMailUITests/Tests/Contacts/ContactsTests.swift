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
            .deleteContact(email)
            .verify.contactDoesNotExists(email)
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
            .clickContact(email)
            .editContact()
            .editNameEmailAndSave(editedName, editedEmail)
            .navigateUp()
            .contactsView()
            .deleteContact(editedEmail)
            .verify.contactDoesNotExists(editedEmail)
    }

    func testDeleteContact() {
        let name = testData.alphaNumericString
        let email = testData.newEmailAddress
        contactsRobot
            .addContact()
            .setNameEmailAndSave(name, email)
            .contactsView()
            .deleteContact(email)
            .verify.contactDoesNotExists(email)
    }

    func testCreateGroup() {
        let contactEmail = testData.internalEmailTrustedKeys
        let groupName = testData.alphaNumericString
        contactsRobot
            .addGroup()
            .groupName(groupName)
            .manageAddresses()
            .addContactToGroup(contactEmail.email)
            .save()
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
            .groupName(groupName)
            .manageAddresses()
            .addContactToGroup(contactEmail.email)
            .save()
            .groupsView()
            .clickGroup(groupName)
            .edit()
            .editNameAndSave(newGroupName)
            .navigateUp()
            .groupsView()
            .deleteGroup(newGroupName)
            .verify.groupDoesNotExists(newGroupName)
    }

    func testDeleteGroup() {
        let contactEmail = testData.internalEmailTrustedKeys.email
        let groupName = testData.alphaNumericString
        contactsRobot
            .addGroup()
            .groupName(groupName)
            .manageAddresses()
            .addContactToGroup(contactEmail)
            .save()
            .groupsView()
            .deleteGroup(groupName)
            .verify.groupDoesNotExists(groupName)
    }

    func testContactDetailSendMessage() {
        let subject = testData.messageSubject
        let contactEmail = testData.internalEmailTrustedKeys.email
        contactsRobot
            .contactsView()
            .clickContact(contactEmail)
            .emailContact()
            .sendMessageToContact(subject)
            .navigateUp()
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

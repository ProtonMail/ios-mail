//
//  ContactsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCore_TestingToolkit

class ContactsTests : CleanAuthenticatedTestCase {

    private var contactsRobot = ContactsRobot()

    override func setUp() {
        super.setUp()
        contactsRobot = InboxRobot()
            .menuDrawer()
            .contacts()
    }

    func testCreateAndDeleteContact() {
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
        let editedName = testData.alphaNumericStringStartingFromX
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

    func testCreateAndDeleteGroup() {
        let email = testData.newEmailAddress
        let groupName = testData.alphaNumericString
        contactsRobot
            .addContact()
            .setNameEmailAndSave(name, email)
            .addGroup()
            .typeGroupName(groupName)
            .tapManageAddresses()
            .addContactToGroup(email)
            .saveContactSelection()
            .groupsView()
            .deleteGroup(groupName)
            .verify.groupDoesNotExists(groupName)
    }

    func testEditGroup() {
        let email = testData.newEmailAddress
        let groupName = testData.alphaNumericString
        let newGroupName = testData.alphaNumericString
        contactsRobot
            .addContact()
            .setNameEmailAndSave(name, email)
            .addGroup()
            .typeGroupName(groupName)
            .tapManageAddresses()
            .addContactToGroup(email)
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
            .refreshMailbox()
            .verify.messageWithSubjectExists(subject)
    }
}

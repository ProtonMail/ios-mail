//
//  ContactsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 06.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCore_TestingToolkit

class ContactsTests : FixtureAuthenticatedTestCase {

    private var contactsRobot = ContactsRobot()

    override func setUp() {
        super.setUp()
        contactsRobot = InboxRobot()
            .menuDrawer()
            .contacts()
    }

    func testCreateAndDeleteContact() {
        contactsRobot
            .addContact()
            .setNameEmailAndSave(user!.name, user!.email)
            .contactsView()
            .deleteContact(user!.name)
            .verify.contactDoesNotExists(user!.name)
    }

    // enable and refactor to use quark commands back after the smoke set is finished
    func xtestEditContact() {
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

    func xtestEditGroup() {
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

    func xtestContactDetailSendMessage() {
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

    func xtestContactGroupSendMessage() {
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

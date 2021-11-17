//
//  LabelFolderTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 13.11.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import ProtonCore_TestingToolkit

class LabelsFoldersTests: BaseTestCase {
    
    private let accountSettingsRobot: AccountSettingsRobot = AccountSettingsRobot()
    private let loginRobot = LoginRobot()
    
    func testCreateAndDeleteCustomFolder() {
        let user = testData.onePassUser
        let folderName = StringUtils().randomAlphanumericString()
        
        loginRobot
            .loginUser(user)
            .menuDrawer()
            .inbox()
            .clickMessageByIndex(1)
            .createFolder(folderName)
            .selectFolder(folderName)
            .tapDoneSelectingFolderButton()
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .folders()
            .deleteFolderLabel(folderName)
            .verify.folderLabelDeleted(folderName)
    }
    
    func testCreateAndDeleteCustomLabel() {
        let user = testData.onePassUser
        let labelName = StringUtils().randomAlphanumericString()
        
        loginRobot
            .loginUser(user)
            .menuDrawer()
            .inbox()
            .clickMessageByIndex(1)
            .createLabel(labelName)
            .selectLabel(labelName)
            .tapDoneSelectingLabelButton()
            .navigateBackToInbox()
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .labels()
            .deleteFolderLabel(labelName)
            .verify.folderLabelDeleted(labelName)
    }
    
    func testAddMessageToCustomFolderFromInbox() {
        let user = testData.onePassUser
        let secondUser = testData.twoPassUser
        let to = secondUser.email
        let subject = testData.messageSubject
        let folderName = "TestAutomationFolder"
        
        loginRobot
            .loginUser(user)
            .compose()
            .sendMessage(to, subject)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(secondUser)
            .clickMessageBySubject(subject)
            .addMessageToFolder(folderName)
            .menuDrawer()
            .folderOrLabel(folderName)
            .verify.messageExists(subject)
    }
    
    func testAddMessageToCustomLabelFromInbox() {
        let user = testData.onePassUser
        let secondUser = testData.twoPassUser
        let to = secondUser.email
        let subject = testData.messageSubject
        let labelName = "TestAutomationLabel"
        
        loginRobot
            .loginUser(user)
            .compose()
            .sendMessage(to, subject)
            .menuDrawer()
            .accountsList()
            .manageAccounts()
            .addAccount()
            .connectTwoPassAccount(secondUser)
            .clickMessageBySubject(subject)
            .assignLabelToMessage(labelName)
            .navigateBackToInbox()
            .menuDrawer()
            .folderOrLabel(labelName)
            .verify.messageExists(subject)
    }
    
    func testEditCustomFolderNameAndColor() {
        let user = testData.onePassUser
        let folderName = StringUtils().randomAlphanumericString()
        let newFolderName = StringUtils().randomAlphanumericString()
        
        loginRobot
            .loginUser(user)
            .clickMessageByIndex(1)
            .createFolder(folderName)
            .tapDoneSelectingFolderButton()
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .folders()
            .selectFolderLabel(folderName)
            .editFolderLabelName(newFolderName)
            .save()
            .deleteFolderLabel(newFolderName)
            .verify.folderLabelDeleted(newFolderName)
    }
    
    func testEditCustomLabelNameAndColor() {
        let user = testData.onePassUser
        let folderName = StringUtils().randomAlphanumericString()
        let newFolderName = StringUtils().randomAlphanumericString()
        
        loginRobot
            .loginUser(user)
            .refreshMailbox()
            .clickMessageByIndex(1)
            .createLabel(folderName)
            .tapDoneSelectingLabelButton()
            .navigateBackToInbox()
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .labels()
            .editFolderLabel(folderName)
            .editFolderLabelName(newFolderName)
            .selectFolderColorByIndex(3)
            .save()
            .deleteFolderLabel(newFolderName)
            .verify.folderLabelDeleted(newFolderName)
    }
}

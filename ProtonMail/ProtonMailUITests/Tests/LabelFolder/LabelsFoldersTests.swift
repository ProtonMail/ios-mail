//
//  LabelFolderTests.swift
//  Proton MailUITests
//
//  Created by denys zelenchuk on 13.11.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCore_TestingToolkit

class LabelsFoldersTests: BaseTestCase {
    
    private let accountSettingsRobot: AccountSettingsRobot = AccountSettingsRobot()
    private let loginRobot = LoginRobot()
    
    // Disable because BE doesn't support v5 colors right now
//    func testCreateAndDeleteCustomFolder() {
//        let user = testData.onePassUser
//        let folderName = StringUtils().randomAlphanumericString()
//
//        loginRobot
//            .loginUser(user)
//            .refreshMailbox()
//            .clickMessageByIndex(1)
//            .createFolder(folderName)
//            .selectFolder(folderName)
//            .tapDoneSelectingFolderButton()
//            .menuDrawer()
//            .settings()
//            .selectAccount(user.email)
//            .folders()
//            .deleteFolderLabel(folderName)
//            .verify.folderLabelDeleted(folderName)
//    }
    
    // Disable because BE doesn't support v5 colors right now
//    func testCreateAndDeleteCustomLabel() {
//        let user = testData.onePassUser
//        let labelName = StringUtils().randomAlphanumericString()
//
//        loginRobot
//            .loginUser(user)
//            .refreshMailbox()
//            .clickMessageByIndex(1)
//            .createLabel(labelName)
//            .selectLabel(labelName)
//            .tapDoneSelectingLabelButton()
//            .navigateBackToInbox()
//            .menuDrawer()
//            .settings()
//            .selectAccount(user.email)
//            .labels()
//            .deleteFolderLabel(labelName)
//            .verify.folderLabelDeleted(labelName)
//    }
    
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
            .refreshMailbox()
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
            .refreshMailbox()
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
            .refreshMailbox()
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

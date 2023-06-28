//
//  LabelFolderTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 13.11.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCore_TestingToolkit

class LabelsFoldersTests: FixtureAuthenticatedTestCase {
    private let accountSettingsRobot: AccountSettingsRobot = AccountSettingsRobot()
    private let loginRobot = LoginRobot()

    func testCreateAndDeleteFolder() {
        let folderName = "test"

        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .clickMessageBySubject(scenario.subject)
                .createFolder(folderName)
                .selectFolder(folderName)
                .tapDone()
            InboxRobot()
                .menuDrawer()
                .folderOrLabel(folderName)
                .verify.messageExists(scenario.subject)
            MailboxRobotInterface()
                .menuDrawer()
                .settings()
                .selectAccount(user!.email)
                .folders()
                .deleteFolderLabel(folderName)
                .verify.folderLabelDeleted(folderName)
        }
    }
    
    func testCreateAndDeleteLabel() {
        let labelName = "test"

        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .clickMessageBySubject(scenario.subject)
                .createLabel(labelName)
                .selectLabel(labelName)
                .tapDone()
                .navigateBackToInbox()
                .menuDrawer()
                .folderOrLabel(labelName)
                .verify.messageExists(scenario.subject)
            MailboxRobotInterface()
                .menuDrawer()
                .settings()
                .selectAccount(user!.email)
                .labels()
                .deleteFolderLabel(labelName)
                .verify.folderLabelDeleted(labelName)
        }
    }
    
    func xtestEditCustomFolderNameAndColor() {
        let user = testData.onePassUser
        let folderName = StringUtils().randomAlphanumericString()
        let newFolderName = StringUtils().randomAlphanumericString()
        
        loginRobot
            .loginUser(user)
            .refreshMailbox()
            .clickMessageByIndex(1)
            .createFolder(folderName)
            .tapDone()
            .navigateBackToInbox()
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
            .clickMessageByIndex(2)
            .createLabel(folderName)
            .tapDone()
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
    
    func xtestCreateSubFolder() {
        let user = testData.onePassUser
        let folderName = StringUtils().randomAlphanumericString()
        
        loginRobot
            .loginUser(user)
            .menuDrawer()
            .settings()
            .selectAccount(user.email)
            .folders()
            .addFolder()
            .selectParentFolderOption()
            .selectParentFolder("sss")
            .tapDoneButton()
            .createFolderLabel(folderName)
            .selectFolderLabel(folderName)
            .delete()
            .confirmDelete()
            .verify.folderLabelDeleted(folderName)
    }
}

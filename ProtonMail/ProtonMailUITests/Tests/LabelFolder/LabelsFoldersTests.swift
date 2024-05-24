//
//  LabelFolderTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 13.11.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCoreTestingToolkitUITestsLogin

class LabelsFoldersTests: FixtureAuthenticatedTestCase {
    private let loginRobot = LoginRobot()

    func testCreateAndDeleteFolder() {
        let folderName = "test"

        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .clickMessageBySubject(scenario.subject)
                .createFolder(folderName)
                .selectFolder(folderName)
            InboxRobot()
                .menuDrawer()
                .folderOrLabel(folderName)
                .verify.messageExists(scenario.subject)
            MailboxRobotInterface()
                .menuDrawer()
                .settings()
                .selectAccount(user.dynamicDomainEmail)
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
                .selectAccount(user.dynamicDomainEmail)
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
            .selectAccount(user.dynamicDomainEmail)
            .folders()
            .selectFolderLabel(folderName)
            .editFolderLabelName(newFolderName)
            .save()
            .deleteFolderLabel(newFolderName)
            .verify.folderLabelDeleted(newFolderName)
    }

    // TODO: enable back after fixing the test
    func xtestEditCustomLabelNameAndColor() {
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
            .selectAccount(user.dynamicDomainEmail)
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
            .selectAccount(user.dynamicDomainEmail)
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

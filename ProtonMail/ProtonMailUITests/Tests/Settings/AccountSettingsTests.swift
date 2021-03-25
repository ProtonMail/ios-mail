//
//  AccountSettingsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 26.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

class AccountSettingsTests : BaseTestCase {

    private let accountSettingsRobot: AccountSettingsRobot = AccountSettingsRobot()
    private let loginRobot = LoginRobot()

    override func setUp() {
        super.setUp()
        loginRobot
            .loginUser(testData.onePassUser)
            .menuDrawer()
            .settings()
            .selectAccount(testData.onePassUser.email)
    }

    func testChangeSignlePassword() {
        accountSettingsRobot
            .singlePassword()
            .changePassword(user: testData.onePassUser)
            .verify.settingsOpened()
    }

    func xtestChangeRecoveryEmail() {
        accountSettingsRobot
            .recoveryEmail()
            .changeRecoveryEmail(testData.twoPassUser)
            .verify.recoveryEmailChangedTo(testData.onePassUser.email)
    }

    func testNavigateToDefaultEmailAddress() {
        accountSettingsRobot
            .defaultEmailAddress()
            .verify.changeDefaultAddressViewShown("2\(testData.onePassUser.email)")
    }

    func testChangeDisplayName() {
        let newDisplayName = "\(testData.onePassUser.name)-\(StringUtils().randomAlphanumericString())"
        accountSettingsRobot
            .displayName()
            .setDisplayNameTextTo(newDisplayName)
            .save()
            .verify.displayNameShownWithText(newDisplayName)
    }

    func testSwitchSignatureToggleOn() {
        let signature = "\(StringUtils().randomAlphanumericString())</br>\(StringUtils().randomAlphanumericString())"
        accountSettingsRobot
            .signature()
            .enableSignature()
            .setSignatureText(signature)
            .save()
            .verify.signatureIsEnabled()
    }

    func testSwitchSignatureToggleOff() {
        accountSettingsRobot
            .signature()
            .disableSignature()
            .save()
            .verify.signatureIsDisabled()
    }

    func testSwitchMobileSignatureToggleOn() {
        let signature = "\(StringUtils().randomAlphanumericString())</br>\(StringUtils().randomAlphanumericString())"
        accountSettingsRobot
            .mobileSignature()
            .enableSignature()
            .setSignatureText(signature)
            .save()
            .verify.mobileSignatureIsEnabled()
    }
    
    func testSwitchMobileSignatureToggleOff() {
        let signature = "\(StringUtils().randomAlphanumericString())</br>\(StringUtils().randomAlphanumericString())"
        accountSettingsRobot
            .mobileSignature()
            .setSignatureText(signature)
            .disableSignature()
            .save()
            .verify.mobileSignatureIsDisabled()
    }

    func testCreateAndDeleteLabelFromAccountSettings() {
        let labelName = StringUtils().randomAlphanumericString()
        accountSettingsRobot
            .foldersAndLabels()
            .addLabel()
            .createFolderLabel(labelName)
            .deleteFolderLabel(labelName)
            .foldersAndLabels()
            .verify.folderLabelDeleted(labelName)
    }

    func testCreateAndDeleteFolderFromAccountSettings() {
        let folderName = StringUtils().randomAlphanumericString()
        accountSettingsRobot
            .foldersAndLabels()
            .addFolder()
            .createFolderLabel(folderName)
            .deleteFolderLabel(folderName)
            .foldersAndLabels()
            .verify.folderLabelDeleted(folderName)
    }
    
    func testDisablePrivacyAutoShowImages() {
        accountSettingsRobot
            .privacy()
            .disableAutoShowImages()
            .verify.autoShowImagesSwitchIsDisabled()
    }
}

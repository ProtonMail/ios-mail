//
//  AccountSettingsTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 26.10.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//


class AccountSettingsTests: FixtureAuthenticatedTestCase {

    private let accountSettingsRobot: AccountSettingsRobot = AccountSettingsRobot()

    override func setUp() {
        super.setUp()

        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
                .settings()
                .selectAccount(user.email)
        }
    }

    func xtestChangeSignlePassword() {
        accountSettingsRobot
            .singlePassword()
            .changePassword(user: user)
            .verify.settingsOpened()
    }

    func xtestChangeRecoveryEmail() {
        accountSettingsRobot
            .recoveryEmail()
            .changeRecoveryEmail(testData.twoPassUser)
            .verify.recoveryEmailChangedTo(user.email)
    }

    // TODO: This test case requires account with many aliases in order to navigate to Default email address selection.
    func xtestNavigateToDefaultEmailAddress() {
        accountSettingsRobot
            .defaultEmailAddress()
            .verify.changeDefaultAddressViewShown(user.email)
    }

    func testChangeDisplayName() {
        let newDisplayName = "\(user.name)-\(StringUtils().randomAlphanumericString())"
        accountSettingsRobot
            .displayName()
            .setDisplayNameTextTo(newDisplayName)
            .save()
            .verify.displayNameShownWithText(newDisplayName)

        accountSettingsRobot
            .displayName()
            .setDisplayNameTextTo(user.name)
            .save()
            .verify.displayNameShownWithText(user.name)
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

    /// When we are setting Signature toggle to its default "OFF" state then Save button is disabled.
    func testSwitchSignatureToggleOff() {
        accountSettingsRobot
            .signature()
            .disableSignature()
            .navigateBackToAccountSettings()
            .verify.signatureIsDisabled()
    }

    /// Default Signature toggle state is "OFF" so after switching it "ON" "Save" nav bar button will be enabled.
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
            .labels()
            .addLabel()
            .createFolderLabel(labelName)
            .deleteFolderLabel(labelName)
            .verify.folderLabelDeleted(labelName)
    }

    func testCreateAndDeleteFolderFromAccountSettings() {
        let folderName = StringUtils().randomAlphanumericString()
        accountSettingsRobot
            .folders()
            .addFolder()
            .createFolderLabel(folderName)
            .deleteFolderLabel(folderName)
            .verify.folderLabelDeleted(folderName)
    }
    
    func testDisablePrivacyAutoShowImages() {
        accountSettingsRobot
            .privacy()
            .disableAutoShowImages()
            .verify.autoShowImagesSwitchIsDisabled()
    }
}

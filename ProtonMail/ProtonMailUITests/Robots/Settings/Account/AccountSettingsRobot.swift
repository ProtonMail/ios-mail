//
//  AccountSettingsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

private let singlePasswordLabel = LocalString._single_password
private let recoveryEmailLabel = LocalString._recovery_email
private let displayNameLabel = "Display name"
private let defaultLabel = LocalString._general_default
private let signatureLabel = LocalString._settings_signature_title
private let mobileSignatureLabel = "Mobile signature"
private let privacyLabel = LocalString._privacy
private let labelsAndFoldersLabel = LocalString._label_and_folders
private let swipingGesturesLabel = LocalString._swiping_gestures
private let signatureStaticTextLabel = LocalString._settings_signature_title
private let signatureOnStaticTextLabel = LocalString._composer_on
private let signatureOffStaticTextLabel = "Off"
private let privacySignatureStaticTextLabel = LocalString._privacy
private let backNavBarButtonIdentifier = LocalString._menu_settings_title

/**
 AccountSettingsRobot class contains actions and verifications for Account settings functionality.
 */
class AccountSettingsRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify() }
    
    func foldersAndLabels() -> AccountSettingsLabelsAndFoldersRobot {
        Element.wait.forStaticTextFieldWithIdentifier(labelsAndFoldersLabel, file: #file, line: #line).tap()
        return AccountSettingsLabelsAndFoldersRobot()
    }
    
    func defaultEmailAddress() -> DefaultEmailAddressRobot {
        Element.wait.forStaticTextFieldWithIdentifier(defaultLabel, file: #file, line: #line).tap()
        return DefaultEmailAddressRobot()
    }
    
    func displayName() -> DisplayNameRobot {
        Element.wait.forStaticTextFieldWithIdentifier(displayNameLabel, file: #file, line: #line).tap()
        return DisplayNameRobot()
    }
    
    func mobileSignature() -> SignatureRobot {
        Element.wait.forStaticTextFieldWithIdentifier(mobileSignatureLabel, file: #file, line: #line).tap()
        return SignatureRobot()
    }
    
    func privacy() -> PrivacyRobot {
        Element.wait.forStaticTextFieldWithIdentifier(privacySignatureStaticTextLabel, file: #file, line: #line).tap()
        return PrivacyRobot()
    }
    
    func recoveryEmail() -> RecoveryEmailRobot {
        Element.wait.forStaticTextFieldWithIdentifier(recoveryEmailLabel, file: #file, line: #line).tap()
        return RecoveryEmailRobot()
    }
    
    func singlePassword() -> SinglePasswordRobot {
        Element.wait.forStaticTextFieldWithIdentifier(singlePasswordLabel, file: #file, line: #line).tap()
        return SinglePasswordRobot()
    }

    func signature() -> SignatureRobot {
        Element.wait.forStaticTextFieldWithIdentifier(signatureLabel, file: #file, line: #line).tap()
        return SignatureRobot()
    }
    
    func navigateBackToSettings() -> SettingsRobot {
        Element.wait.forButtonWithIdentifier(backNavBarButtonIdentifier, file: #file, line: #line).tap()
        return SettingsRobot()
    }
    
    /**
     DefaultEmailAddressRobot represents the modal where multiple emails are shown.
     */
    class DefaultEmailAddressRobot {
        
        var verify: Verify! = nil
        init() { verify = Verify() }
        
        class Verify {
            @discardableResult
            func changeDefaultAddressViewShown(_ email: String) -> DefaultEmailAddressRobot {
                Element.wait.forButtonWithIdentifier(email, file: #file, line: #line)
                return DefaultEmailAddressRobot()
            }
        }
    }

    /**
     Contains all the validations that can be performed by AccountSettingsRobot.
     */
    class Verify {
        
        func accountSettingsOpened() {}
        
        func signatureIsEnabled() {
            Element.wait.forCellByIndex(5).assertHasStaticTextChild(withText: signatureStaticTextLabel)
            Element.wait.forCellByIndex(5).assertHasStaticTextChild(withText: signatureOnStaticTextLabel)
        }
        
        func signatureIsDisabled() {
            Element.wait.forCellByIndex(5).assertHasStaticTextChild(withText: signatureStaticTextLabel)
            Element.wait.forCellByIndex(5).assertHasStaticTextChild(withText: signatureOffStaticTextLabel)
        }
        
        func mobileSignatureIsEnabled() {
            Element.wait.forCellByIndex(6).assertHasStaticTextChild(withText: mobileSignatureLabel)
            Element.wait.forCellByIndex(6).assertHasStaticTextChild(withText: signatureOnStaticTextLabel)
        }
        
        func mobileSignatureIsDisabled() {
            Element.wait.forCellByIndex(6).assertHasStaticTextChild(withText: mobileSignatureLabel)
            Element.wait.forCellByIndex(6).assertHasStaticTextChild(withText: signatureOffStaticTextLabel)
        }
        
        func displayNameShownWithText(_ name: String) {
            Element.wait.forStaticTextFieldWithIdentifier(name, file: #file, line: #line)
        }
    }
}

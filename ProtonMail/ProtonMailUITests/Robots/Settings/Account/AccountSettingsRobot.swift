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

/**
 AccountSettingsRobot class contains actions and verifications for Account settings functionality.
 */
class AccountSettingsRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify() }
    
    func foldersAndLabels() -> LabelsAndFoldersRobot {
        Element.wait.forStaticTextFieldWithIdentifier(labelsAndFoldersLabel).tap()
        return LabelsAndFoldersRobot()
    }
    
    func defaultEmailAddress() -> DefaultEmailAddressRobot {
        Element.wait.forStaticTextFieldWithIdentifier(defaultLabel).tap()
        return DefaultEmailAddressRobot()
    }
    
    func displayName() -> DisplayNameRobot {
        Element.wait.forStaticTextFieldWithIdentifier(displayNameLabel).tap()
        return DisplayNameRobot()
    }
    
    func mobileSignature() -> SignatureRobot {
        Element.wait.forStaticTextFieldWithIdentifier(mobileSignatureLabel).tap()
        return SignatureRobot()
    }
    
    func privacy() -> PrivacyRobot {
        Element.wait.forStaticTextFieldWithIdentifier(privacySignatureStaticTextLabel).tap()
        return PrivacyRobot()
    }
    
    func recoveryEmail() -> RecoveryEmailRobot {
        Element.wait.forStaticTextFieldWithIdentifier(recoveryEmailLabel).tap()
        return RecoveryEmailRobot()
    }
    
    func singlePassword() -> SinglePasswordRobot {
        Element.wait.forStaticTextFieldWithIdentifier(singlePasswordLabel).tap()
        return SinglePasswordRobot()
    }

    func signature() -> SignatureRobot {
        Element.wait.forStaticTextFieldWithIdentifier(signatureLabel).tap()
        return SignatureRobot()
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
                Element.wait.forButtonWithIdentifier(email)
                return DefaultEmailAddressRobot()
            }
        }
    }

    /**
     Contains all the validations that can be performed by AccountSettingsRobot.
     */
    class Verify {
        
        func accountSettingsOpened() {
            
        }
        
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
            Element.wait.forStaticTextFieldWithIdentifier(name)
        }
    }
}

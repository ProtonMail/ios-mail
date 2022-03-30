//
//  AccountSettingsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let singlePasswordLabel = LocalString._single_password
    static let recoveryEmailLabel = LocalString._recovery_email
    static let displayNameLabel = "Display name"
    static let defaultLabel = LocalString._general_default
    static let signatureLabel = LocalString._settings_signature_title
    static let mobileSignatureLabel = "Mobile signature"
    
    static let signatureRightStaticTextIdentifier = "Signature.rightText"
    static let mobileSignatureRightStaticTextIdentifier = "Mobile_signature.rightText"
    static let onStaticTextLabel = LocalString._settings_On_title
    static let offStaticTextLabel = LocalString._settings_Off_title

    static let privacyLabel = LocalString._privacy
    static let labelsIdentifier = "SettingsGeneralCell.Labels"
    static let foldersIdentifier = "SettingsGeneralCell.Folders"
    static let signatureStaticTextLabel = LocalString._settings_signature_title
    static let signatureOnStaticTextLabel = LocalString._springboard_shortcuts_composer
    static let privacySignatureStaticTextLabel = LocalString._privacy
    static let backNavBarButtonIdentifier = LocalString._menu_settings_title
}

/**
 AccountSettingsRobot class contains actions and verifications for Account settings functionality.
 */
class AccountSettingsRobot: CoreElements {
    
    var verify = Verify()
    
    func labels() -> AccountSettingsLabelsAndFoldersRobot {
        cell(id.labelsIdentifier).tap()
        return AccountSettingsLabelsAndFoldersRobot()
    }
    
    func folders() -> AccountSettingsLabelsAndFoldersRobot {
        cell(id.foldersIdentifier).tap()
        return AccountSettingsLabelsAndFoldersRobot()
    }
    
    func defaultEmailAddress() -> DefaultEmailAddressRobot {
        staticText(id.defaultLabel).tap()
        return DefaultEmailAddressRobot()
    }
    
    func displayName() -> DisplayNameRobot {
        staticText(id.displayNameLabel).tap()
        return DisplayNameRobot()
    }
    
    func mobileSignature() -> SignatureRobot {
        staticText(id.mobileSignatureLabel).tap()
        return SignatureRobot()
    }
    
    func privacy() -> PrivacyRobot {
        staticText(id.privacySignatureStaticTextLabel).tap()
        return PrivacyRobot()
    }
    
    func recoveryEmail() -> RecoveryEmailRobot {
        staticText(id.recoveryEmailLabel).tap()
        return RecoveryEmailRobot()
    }
    
    func singlePassword() -> SinglePasswordRobot {
        staticText(id.singlePasswordLabel).tap()
        return SinglePasswordRobot()
    }

    func signature() -> SignatureRobot {
        staticText(id.signatureLabel).tap()
        return SignatureRobot()
    }
    
    func navigateBackToSettings() -> SettingsRobot {
        button(id.backNavBarButtonIdentifier).tap()
        return SettingsRobot()
    }
    
    /**
     DefaultEmailAddressRobot represents the modal where multiple emails are shown.
     */
    class DefaultEmailAddressRobot {
        
        var verify = Verify()
        
        class Verify: CoreElements {
            @discardableResult
            func changeDefaultAddressViewShown(_ email: String) -> DefaultEmailAddressRobot {
                button(email).wait().checkExists()
                return DefaultEmailAddressRobot()
            }
        }
    }

    /**
     Contains all the validations that can be performed by AccountSettingsRobot.
     */
    class Verify: CoreElements {
        
        func accountSettingsOpened() {}
        
        func signatureIsEnabled() {
            staticText(id.signatureRightStaticTextIdentifier).hasLabel(id.onStaticTextLabel).checkExists()
        }
        
        func signatureIsDisabled() {
            staticText(id.signatureRightStaticTextIdentifier).hasLabel(id.offStaticTextLabel).checkExists()
        }
        
        func mobileSignatureIsEnabled() {
            staticText(id.mobileSignatureRightStaticTextIdentifier).hasLabel(id.onStaticTextLabel).checkExists()
        }
        
        func mobileSignatureIsDisabled() {
            staticText(id.mobileSignatureRightStaticTextIdentifier).hasLabel(id.offStaticTextLabel).checkExists()
        }
        
        func displayNameShownWithText(_ name: String) {
            staticText(name).wait().checkExists()
        }
    }
}

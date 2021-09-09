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
    static let privacyLabel = LocalString._privacy
    static let labelsIdentifier = "SettingsGeneralCell.Labels"
    static let foldersIdentifier = "SettingsGeneralCell.Folders"
    static let swipingGesturesLabel = LocalString._swiping_gestures
    static let signatureStaticTextLabel = LocalString._settings_signature_title
    static let signatureOnStaticTextLabel = LocalString._springboard_shortcuts_composer //<-- fix it
    static let signatureOffStaticTextLabel = "Off"
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
        staticText(id.foldersIdentifier).tap()
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
            cell().byIndex(5).onChild(staticText(id.signatureStaticTextLabel)).wait().checkExists()
            cell().byIndex(5).onChild(staticText(id.signatureOnStaticTextLabel)).wait().checkExists()
        }
        
        func signatureIsDisabled() {
            cell().byIndex(5).onChild(staticText(id.signatureStaticTextLabel)).wait().checkExists()
            cell().byIndex(5).onChild(staticText(id.signatureOffStaticTextLabel)).wait().checkExists()
        }
        
        func mobileSignatureIsEnabled() {
            cell().byIndex(6).onChild(staticText(id.mobileSignatureLabel)).wait().checkExists()
            cell().byIndex(6).onChild(staticText(id.signatureOnStaticTextLabel)).wait().checkExists()
        }
        
        func mobileSignatureIsDisabled() {
            cell().byIndex(6).onChild(staticText(id.mobileSignatureLabel)).wait().checkExists()
            cell().byIndex(6).onChild(staticText(id.signatureOffStaticTextLabel)).wait().checkExists()
        }
        
        func displayNameShownWithText(_ name: String) {
            staticText(name).wait().checkExists()
        }
    }
}

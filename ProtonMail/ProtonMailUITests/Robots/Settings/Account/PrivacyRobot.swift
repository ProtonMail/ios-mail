//
//  PrivacyRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 28.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

private let enableSignatureStaticTextLabel = LocalString._settings_enable_default_signature_title
private let enableMobileSignatureStaticTextLabel = LocalString._settings_enable_mobile_signature_title
private let saveNavBarButtonLabel = LocalString._general_save_action

/**
 Class represents Privacy Account Settings view.
 */
class PrivacyRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify() }
    
    func disableAutoShowImages() -> PrivacyRobot {
        if (Element.swittch.isEnabledByIndex(0)) {
            /// Turn switch OFF and then ON
            Element.swittch.tapByIndex(0)
        } else {
            /// Turn switch ON and then OFF
            Element.swittch.tapByIndex(0)
            Element.swittch.tapByIndex(0)
        }
        return self
    }
    
    func enableAutoShowImages() -> PrivacyRobot {
        if (Element.swittch.isEnabledByIndex(0)) {
            /// Turn switch OFF and then ON
            Element.swittch.tapByIndex(0)
            Element.swittch.tapByIndex(0)
        } else {
            /// Turn switch ON
            Element.swittch.tapByIndex(0)
        }
        return self
    }
    
    func navigateBackToAccountSettings(_ signature: String) -> AccountSettingsRobot {
        Element.button.tapByIndex(0)
        return AccountSettingsRobot()
    }
    
    /**
     * Contains all the validations that can be performed by PrivacyRobot.
     */
    class Verify {

        func autoShowImagesSwitchIsDisabled() {
            Element.assert.switchByIndexHasValue(0, 0)
        }
    }
}

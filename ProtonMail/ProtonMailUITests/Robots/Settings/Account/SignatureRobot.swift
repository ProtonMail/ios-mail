//
//  SignatureRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

private let enableSignatureStaticTextLabel = LocalString._settings_enable_default_signature_title
private let enableMobileSignatureStaticTextLabel = LocalString._settings_enable_mobile_signature_title
private let saveNavBarButtonLabel = LocalString._general_save_action

/**
 Class represents Signature and Mobile signature view.
 */
class SignatureRobot {
    
    func disableSignature() -> SignatureRobot {
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
    
    func enableSignature() -> SignatureRobot {
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
    
    func save() -> AccountSettingsRobot {
        Element.wait.forButtonWithIdentifier(saveNavBarButtonLabel).tap()
        return AccountSettingsRobot()
    }
    
    func setSignatureText(_ signature: String) -> SignatureRobot {
        Element.textView.tapByIndex(0).clear().typeText(signature)
        return self
    }
}

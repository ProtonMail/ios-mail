//
//  SignatureRobot.swift
//  Proton MailUITests
//
//  Created by denys zelenchuk on 11.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let enableSignatureStaticTextLabel = LocalString._settings_enable_default_signature_title
    static let enableMobileSignatureStaticTextLabel = LocalString._settings_enable_mobile_signature_title
    static let saveNavBarButtonLabel = LocalString._general_save_action
}

/**
 Class represents Signature and Mobile signature view.
 */
class SignatureRobot: CoreElements {
    
    func disableSignature() -> SignatureRobot {
        if (Element.swittch.isEnabledByIndex(0)) {
            /// Turn switch OFF and then ON
            swittch().byIndex(0).tap()
        } else {
            /// Turn switch ON and then OFF
            swittch().byIndex(0).tap()
            swittch().byIndex(0).tap()
        }
        return self
    }
    
    func enableSignature() -> SignatureRobot {
        if (Element.swittch.isEnabledByIndex(0)) {
            /// Turn switch OFF and then ON
            swittch().byIndex(0).tap()
            swittch().byIndex(0).tap()
        } else {
            /// Turn switch ON
            swittch().byIndex(0).tap()
        }
        return self
    }
    
    func save() -> AccountSettingsRobot {
        button(id.saveNavBarButtonLabel).tap()
        return AccountSettingsRobot()
    }
    
    func setSignatureText(_ signature: String) -> SignatureRobot {
        textView().byIndex(0).multiTap(3).typeText(signature)
        return self
    }
}

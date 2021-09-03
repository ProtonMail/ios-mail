//
//  PrivacyRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 28.10.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct ui {
    static let enableSignatureStaticTextLabel = LocalString._settings_enable_default_signature_title
    static let enableMobileSignatureStaticTextLabel = LocalString._settings_enable_mobile_signature_title
    static let saveNavBarButtonLabel = LocalString._general_save_action
}

/**
 Class represents Privacy Account Settings view.
 */
class PrivacyRobot: CoreElements {
    
    var verify = Verify()
    
    func disableAutoShowImages() -> PrivacyRobot {
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
    
    func enableAutoShowImages() -> PrivacyRobot {
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
    
    func navigateBackToAccountSettings(_ signature: String) -> AccountSettingsRobot {
        button().byIndex(0).tap()
        return AccountSettingsRobot()
    }
    
    /**
     * Contains all the validations that can be performed by PrivacyRobot.
     */
    class Verify: CoreElements {

        func autoShowImagesSwitchIsDisabled() {
            Element.assert.switchByIndexHasValue(0, 0)
        }
    }
}

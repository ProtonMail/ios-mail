//
//  SignatureAlertViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/23/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


class SignatureAlertViewModelImpl : UpgradeAlertViewModel {
    override var title2 : String {
        return LocalString._looking_to_secure_your_contacts_details
    }
    
    override var message : String {
        return LocalString._plus_visionary_enables_you_to_customize_mobile_signature
    }
}

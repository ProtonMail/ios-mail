//
//  SignatureAlertViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/23/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


class ContactAlertViewModelImpl : UpgradeAlertViewModel {
    override var title2 : String {
        return LocalString._looking_to_secure_your_contacts_details
    }
    
    override var message : String {
        return LocalString._protonmail_plus_enables_you_to_add_and_edit_contact_details_beyond_
    }
}

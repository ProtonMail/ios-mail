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
        return LocalString._a_paid_rotonMail_plan_is_required_to_use_this_feature
    }
    
    override var message : String {
        return LocalString._upgrade_to_get_all_paid_features
    }
}

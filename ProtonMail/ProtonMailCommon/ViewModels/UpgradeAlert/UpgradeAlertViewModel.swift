//
//  UpgradeAlertViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/23/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


class UpgradeAlertViewModel {
    /// | --- titel       --- |
    /// | --- title two   --- |
    /// | --- message     --- |
    /// | --- button      --- |
    //
    var title : String {
        return LocalString._premium_feature
    }
    
    var title2 : String {
        fatalError("This method must be overridden")
    }
    
    var message : String {
        fatalError("This method must be overridden")
    }

    var button1: String {
        return LocalString._learn_more
    }
    
    var button2: String {
        return LocalString._not_now
    }
    
    var button3: String {
        return LocalString._view_plans
    }
}

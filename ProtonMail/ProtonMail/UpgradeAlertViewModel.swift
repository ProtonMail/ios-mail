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
    /// | --- message two --- |
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
    
    var message2 : String {
        return LocalString._upgrading_is_not_possible_in_the_app
    }
    
    var button: String {
        return LocalString._got_it
    }
    
    
}

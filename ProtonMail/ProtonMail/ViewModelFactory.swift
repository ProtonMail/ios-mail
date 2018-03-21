//
//  File.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/19/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

//should split for different purpose
var shareViewModelFactoy: ViewModelFactory!

// need supprot dev factory live factory
class ViewModelFactory {
    func getChangeLoginPassword() -> ChangePWDViewModel {
        fatalError("This method must be overridden")
    }
    
    func getChangeMailboxPassword() -> ChangePWDViewModel {
        fatalError("This method must be overridden")
    }
    
    func getChangeSinglePassword() -> ChangePWDViewModel {
        fatalError("This method must be overridden")
    }
    
    func getChangeDisplayName() -> SettingDetailsViewModel {
        fatalError("This method must be overridden")
    }
    
    func getChangeNotificationEmail() -> SettingDetailsViewModel {
        fatalError("This method must be overridden")
    }
    
    func getChangeSignature() -> SettingDetailsViewModel {
        fatalError("This method must be overridden")
    }
    
    func getChangeMobileSignature() -> SettingDetailsViewModel {
        fatalError("This method must be overridden")
    }
}

class ViewModelFactoryTest : ViewModelFactory {
    override func getChangeLoginPassword() -> ChangePWDViewModel {
        return ChangePWDViewModelTest()
    }
    
    override func getChangeMailboxPassword() -> ChangePWDViewModel {
        return ChangePWDViewModelTest()
    }
}


class ViewModelFactoryProduction : ViewModelFactory {
    
    override init() {
        
    }
    
    override func getChangeLoginPassword() -> ChangePWDViewModel {
        return ChangeLoginPWDViewModel()
    }
    
    override func getChangeMailboxPassword() -> ChangePWDViewModel {
        return ChangeMailboxPWDViewModel()
    }
    
    override func getChangeSinglePassword() -> ChangePWDViewModel {
        return ChangeSinglePasswordViewModel()
    }
    
    override func getChangeDisplayName() -> SettingDetailsViewModel {
        return ChangeDisplayNameViewModel()
    }
    
    override func getChangeNotificationEmail() -> SettingDetailsViewModel {
        return ChangeNotificationEmailViewModel()
    }
    
    override func getChangeSignature() -> SettingDetailsViewModel {
        return ChangeSignatureViewModel()
    }
    
    override func getChangeMobileSignature() -> SettingDetailsViewModel {
        return ChangeMobileSignatureViewModel()
    }

}

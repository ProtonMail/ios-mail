//
//  File.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/19/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

public var shareViewModelFactoy: ViewModelFactory!

// need supprot dev factory live factory
public class ViewModelFactory {
    public func getChangeLoginPassword() -> ChangePWDViewModel {
        fatalError("This method must be overridden")
    }
    
    public func getChangeMailboxPassword() -> ChangePWDViewModel {
        fatalError("This method must be overridden")
    }
    
    public func getChangeSinglePassword() -> ChangePWDViewModel {
        fatalError("This method must be overridden")
    }
    
    public func getChangeDisplayName() -> SettingDetailsViewModel {
        fatalError("This method must be overridden")
    }
    
    public func getChangeNotificationEmail() -> SettingDetailsViewModel {
        fatalError("This method must be overridden")
    }
    
    public func getChangeSignature() -> SettingDetailsViewModel {
        fatalError("This method must be overridden")
    }
    
    public func getChangeMobileSignature() -> SettingDetailsViewModel {
        fatalError("This method must be overridden")
    }
}

public class ViewModelFactoryTest : ViewModelFactory {
    override public func getChangeLoginPassword() -> ChangePWDViewModel {
        return ChangePWDViewModelTest()
    }
    
    override public func getChangeMailboxPassword() -> ChangePWDViewModel {
        return ChangePWDViewModelTest()
    }
}


public class ViewModelFactoryProduction : ViewModelFactory {
    
    override public init() {
        
    }
    
    override public func getChangeLoginPassword() -> ChangePWDViewModel {
        return ChangeLoginPWDViewModel()
    }
    
    override public func getChangeMailboxPassword() -> ChangePWDViewModel {
        return ChangeMailboxPWDViewModel()
    }
    
    override public func getChangeSinglePassword() -> ChangePWDViewModel {
        return ChangeSinglePasswordViewModel()
    }
    
    override public func getChangeDisplayName() -> SettingDetailsViewModel {
        return ChangeDisplayNameViewModel()
    }
    
    override public func getChangeNotificationEmail() -> SettingDetailsViewModel {
        return ChangeNotificationEmailViewModel()
    }
    
    override public func getChangeSignature() -> SettingDetailsViewModel {
        return ChangeSignatureViewModel()
    }
    
    override public func getChangeMobileSignature() -> SettingDetailsViewModel {
        return ChangeMobileSignatureViewModel()
    }

}

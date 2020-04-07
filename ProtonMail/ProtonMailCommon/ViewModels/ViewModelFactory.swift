//
//  ViewModelFactory.swift
//  ProtonMail Created on 3/19/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
//TODO::fixme
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
    
//    override func getChangeLoginPassword() -> ChangePWDViewModel {
//        return ChangeLoginPWDViewModel()
//    }
    
//    override func getChangeMailboxPassword() -> ChangePWDViewModel {
//        return ChangeMailboxPWDViewModel()
//    }
    
//    override func getChangeDisplayName() -> SettingDetailsViewModel {
//        return ChangeDisplayNameViewModel()
//    }
//    override func getChangeSignature() -> SettingDetailsViewModel {
//        return ChangeSignatureViewModel()
//    }
    
//    override func getChangeMobileSignature() -> SettingDetailsViewModel {
//        return ChangeMobileSignatureViewModel()
//    }

}

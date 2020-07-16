//
//  UserInfo+Locked.swift
//  ProtonMail - Created on 28/10/2018.
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
import PMKeymaker

//extension Locked where T == [User] {
//    internal init(clearValue: T, with key: PMKeymaker.Key) throws {
//        let data = NSKeyedArchiver.archivedData(withRootObject: clearValue)
//        let locked = try Locked<Data>(clearValue: data, with: key)
//        self.init(encryptedValue: locked.encryptedValue)
//    }
//    
//    internal func unlock(with key: PMKeymaker.Key) throws -> T {
//        let locked = Locked<Data>(encryptedValue: self.encryptedValue)
//        let data = try locked.unlock(with: key, new: true)
//        
//        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ProtonMail.UserInfo")
//        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.UserInfo")
//        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "Share.UserInfo")
//        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ShareDev.UserInfo")
//        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PushService.UserInfo")
//        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PushServiceDev.UserInfo")
//        
//        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ProtonMail.Address")
//        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.Address")
//        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "Share.Address")
//        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ShareDev.Address")
//        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PushService.Address")
//        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PushServiceDev.Address")
//        
//        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ProtonMail.Key")
//        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.Key")
//        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "Share.Key")
//        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ShareDev.Key")
//        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PushService.Key")
//        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PushServiceDev.Key")
//        
//        //NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "ProtonMail.UpdateTime")
//        //NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.UpdateTime")
//        //NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "Share.UpdateTime")
//        //NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "ShareDev.UpdateTime")
//        //NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "PushService.UpdateTime")
//        //NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "PushServiceDev.UpdateTime")
//        
//        guard let value = NSKeyedUnarchiver.unarchiveObject(with: data) as? T else {
//            throw LockedErrors.keyDoesNotMatch
//        }
//        
//        return value
//    }
//}

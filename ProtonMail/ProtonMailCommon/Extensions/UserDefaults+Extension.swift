//
//  UserDefaults+Extension.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_DataModel

extension UserDefaults {

    func customObjectForKey(_ key: String) -> Any? {
        if let data = object(forKey: key) as? Data {
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ProtonMail.UserInfo")
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.UserInfo")
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "Share.UserInfo")
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ShareDev.UserInfo")
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PushService.UserInfo")
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PushServiceDev.UserInfo")
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PMCommon.UserInfo")

            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ProtonMail.Address")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.Address")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "Share.Address")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ShareDev.Address")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PushService.Address")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PushServiceDev.Address")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PMCommon.Address")

            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ProtonMail.Key")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.Key")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "Share.Key")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ShareDev.Key")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PushService.Key")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PushServiceDev.Key")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PMCommon.Key")

            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "UserInfo")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "Address")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "Key")

            return NSKeyedUnarchiver.unarchiveObject(with: data)
        }
        return nil
    }
}

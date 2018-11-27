//
//  UserInfo+Locked.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 28/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import Keymaker

extension Locked where T == UserInfo {
    internal init(clearValue: T, with key: Keymaker.Key) throws {
        let data = NSKeyedArchiver.archivedData(withRootObject: clearValue)
        let locked = try Locked<Data>(clearValue: data, with: key)
        self.init(encryptedValue: locked.encryptedValue)
    }
    
    internal func unlock(with key: Keymaker.Key) throws -> T {
        let locked = Locked<Data>(encryptedValue: self.encryptedValue)
        let data = try locked.unlock(with: key)
        
        // FIXME: do we actually need this crap?
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ProtonMail.UserInfo")
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.UserInfo")
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "Share.UserInfo")
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ShareDev.UserInfo")
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PushService.UserInfo")
        NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PushServiceDev.UserInfo")
        
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ProtonMail.Address")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.Address")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "Share.Address")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ShareDev.Address")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PushService.Address")
        NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PushServiceDev.Address")
        
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ProtonMail.Key")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.Key")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "Share.Key")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ShareDev.Key")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PushService.Key")
        NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PushServiceDev.Key")
        
        NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "ProtonMail.UpdateTime")
        NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.UpdateTime")
        NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "Share.UpdateTime")
        NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "ShareDev.UpdateTime")
        NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "PushService.UpdateTime")
        NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "PushServiceDev.UpdateTime")
        
        guard let value = NSKeyedUnarchiver.unarchiveObject(with: data) as? T else {
            fatalError()
        }
        
        return value
    }
}

//
//  UserInfo+Locked.swift
//  ProtonMail - Created on 28/10/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
            throw Locked.Errors.keyDoesNotMatch
        }
        
        return value
    }
}

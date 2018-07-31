//
//  NSUserDefaultsExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

extension UserDefaults {
    
    func customObjectForKey(_ key: String) -> Any? {
        if let data = object(forKey: key) as? Data {
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ProtonMail.UserInfo")
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "Share.UserInfo")
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "ShareDev.UserInfo")
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PushServic.UserInfo")
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedUnarchiver(), forClassName: "PushServiceDev.UserInfo")
            
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ProtonMail.Address")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "Share.Address")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "ShareDev.Address")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PushService.Address")
            NSKeyedUnarchiver.setClass(Address.classForKeyedUnarchiver(), forClassName: "PushServiceDev.Address")
            
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ProtonMail.Key")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "Share.Key")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "ShareDev.Key")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PushService.Key")
            NSKeyedUnarchiver.setClass(Key.classForKeyedUnarchiver(), forClassName: "PushServiceDev.Key")
            
            NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "ProtonMail.UpdateTime")
            NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "Share.UpdateTime")
            NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "ShareDev.UpdateTime")
            NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "PushService.UpdateTime")
            NSKeyedUnarchiver.setClass(UpdateTime.classForKeyedUnarchiver(), forClassName: "PushServiceDev.UpdateTime")
            
            return NSKeyedUnarchiver.unarchiveObject(with: data)
        }
        return nil
    }
    
    func setCustomValue(_ value: NSCoding?, forKey key: String) {
        let data: Data? = (value == nil) ? nil : NSKeyedArchiver.archivedData(withRootObject: value!)
        setValue(data, forKey: key)
    }
    
    func stringOrEmptyStringForKey(_ key: String) -> String {
        return string(forKey: key) ?? ""
    }
}

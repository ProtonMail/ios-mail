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
            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedArchiver(), forClassName: "ProtonMail.UserInfo")
            NSKeyedUnarchiver.setClass(Address.classForKeyedArchiver(), forClassName: "ProtonMail.Address")
            NSKeyedUnarchiver.setClass(Key.classForKeyedArchiver(), forClassName: "ProtonMail.Key")
            
//            NSKeyedUnarchiver.setClass(Address.classForKeyedArchiver(), forClassName: "UserInfo")
//            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedArchiver(), forClassName: "ProtonMail.UserInfo")
//            NSKeyedUnarchiver.setClass(UserInfo.classForKeyedArchiver(), forClassName: "UserInfo")
            
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

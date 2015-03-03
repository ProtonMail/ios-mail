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

extension NSUserDefaults {
    
    func customObjectForKey(key: String) -> AnyObject? {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey(key) as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(data)
        }
        
        return nil
    }
    
    func setCustomValue(value: NSCoding?, forKey key: String) {
        let data: NSData? = (value == nil) ? nil : NSKeyedArchiver.archivedDataWithRootObject(value!)
        NSUserDefaults.standardUserDefaults().setValue(data, forKey: key)
    }
    
    func stringOrEmptyStringForKey(key: String) -> String {
        return stringForKey(key) ?? ""
    }
}

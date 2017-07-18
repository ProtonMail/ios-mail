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


class MyUnArchiverDelegate: NSObject, NSKeyedUnarchiverDelegate {
    
    // This class is placeholder for unknown classes.
    // It will eventually be `nil` when decoded.
    final class UnknowClass: NSObject, NSCoding  {
        func encode(with aCoder: NSCoder) {
            
        }

        init?(coder aDecoder: NSCoder) {
            super.init()
            return nil
        }
        
        func encodeWithCoder(aCoder: NSCoder) {
        }
    }

    func unarchiver(_ unarchiver: NSKeyedUnarchiver, cannotDecodeObjectOfClassName name: String, originalClasses classNames: [String]) -> AnyClass? {
        return UnknowClass.self
    }
    
}

extension UserDefaults {
    
    func customObjectForKey(_ key: String) -> Any? {
        if let data = object(forKey: key) as? Data {
//            let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
//            let delegate = MyUnArchiverDelegate()
//            unarchiver.delegate = delegate
//            
//            return unarchiver.decodeObject(forKey: "root")
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

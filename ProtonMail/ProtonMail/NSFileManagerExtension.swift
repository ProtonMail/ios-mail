//
//  NSFileManagerExtension.swift
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

extension NSFileManager {
    
    var applicationSupportDirectoryURL: NSURL {
        let urls = URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask) as! [NSURL]
        let applicationSupportDirectoryURL = urls.first!
        
        if !NSFileManager.defaultManager().fileExistsAtPath(applicationSupportDirectoryURL.absoluteString!) {
            var error: NSError?
            if !NSFileManager.defaultManager().createDirectoryAtURL(applicationSupportDirectoryURL, withIntermediateDirectories: true, attributes: nil, error: &error) {
                NSLog("\(__FUNCTION__) Could not create \(applicationSupportDirectoryURL.absoluteString!) with error: \(error)")
            }
        }
        
        return applicationSupportDirectoryURL
    }
    
    var cachesDirectoryURL: NSURL {
        let urls = URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask) as! [NSURL]
        return urls.first!
    }
    
}

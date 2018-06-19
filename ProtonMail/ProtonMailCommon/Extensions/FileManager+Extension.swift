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

extension FileManager {
    
    public var applicationSupportDirectoryURL: URL {
        let urls = self.urls(for: .applicationSupportDirectory, in: .userDomainMask) 
        let applicationSupportDirectoryURL = urls.first!
        //TODO:: need to handle the ! when empty
        if !FileManager.default.fileExists(atPath: applicationSupportDirectoryURL.absoluteString) {
            do {
                try FileManager.default.createDirectory(at: applicationSupportDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch let ex as NSError {
                PMLog.D("Could not create \(applicationSupportDirectoryURL.absoluteString) with error: \(ex)")
            }
        }
        return applicationSupportDirectoryURL
    }
    
    public var cachesDirectoryURL: URL {
        let urls = self.urls(for: .cachesDirectory, in: .userDomainMask) 
        return urls.first!
    }
    
}

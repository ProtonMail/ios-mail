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
    public var appGroupsDirectoryURL: URL! {
        return self.containerURL(forSecurityApplicationGroupIdentifier: Constants.App.APP_GROUP)
    }
    
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
    
    public var temporaryDirectoryUrl: URL {
        if #available(iOS 10.0, *) {
            return FileManager.default.temporaryDirectory
        } else {
            return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        }
    }
    
    public var appGroupsTempDirectoryURL: URL {
        var tempUrl = self.appGroupsDirectoryURL.appendingPathComponent("tmp", isDirectory: true)
        if !FileManager.default.fileExists(atPath: tempUrl.path) {
            do {
                try FileManager.default.createDirectory(at: tempUrl, withIntermediateDirectories: false, attributes: nil)
                tempUrl.excludeFromBackup()
            } catch let ex as NSError {
                PMLog.D("Could not create \(tempUrl.absoluteString) with error: \(ex)")
            }
        }
        return tempUrl
    }
    
    public func createTempURL(forCopyOfFileNamed name: String) throws -> URL {
        let subUrl = self.appGroupsTempDirectoryURL.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString, isDirectory: true)
        try FileManager.default.createDirectory(at: subUrl, withIntermediateDirectories: true, attributes: nil)
        
        return subUrl.appendingPathComponent(name, isDirectory: false)
    }
    
}

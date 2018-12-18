//
//  ileManager+Extension.swift
//  ProtonMail
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

//
//  MessageDataService.swift
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

// MARK: - NSFileManager extension
extension FileManager {
    var attachmentDirectory: URL {
        let attachmentDirectory = applicationSupportDirectoryURL.appendingPathComponent("attachments", isDirectory: true)
        //TODO:: need to handle the empty instead of !
        if !self.fileExists(atPath: attachmentDirectory.absoluteString) {
            do {
                //TODO:: need to handle the empty instead of !
                try self.createDirectory(at: attachmentDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch let ex as NSError {
                PMLog.D(" error : \(ex).")
            }
        }
        //TODO:: need to handle the empty instead of !
        return attachmentDirectory
    }
    
    func cleanCachedAtts() {
        let attachmentDirectory = applicationSupportDirectoryURL.appendingPathComponent("attachments", isDirectory: true)
        let path = attachmentDirectory.path
        do {
            if self.fileExists(atPath: path) {
                let filePaths = try self.contentsOfDirectory(atPath: path)
                for fileName in filePaths {
                    let filePathName = "\(path)/\(fileName)"
                    try self.removeItem(atPath: filePathName)
                }
            }
        }
        catch let ex as NSError {
            PMLog.D("cleanCachedAtts error : \(ex).")
        }
    }
}

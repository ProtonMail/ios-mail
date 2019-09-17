//
//  MessageDataService.swift
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

// MARK: - NSFileManager extension
extension FileManager {
    var attachmentDirectory: URL {
        let attachmentDirectory = temporaryDirectoryUrl.appendingPathComponent("attachments", isDirectory: true)
        if !self.fileExists(atPath: attachmentDirectory.absoluteString) {
            do {
                try self.createDirectory(at: attachmentDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch let ex as NSError {
                PMLog.D(" error : \(ex).")
            }
        }
        return attachmentDirectory
    }
    
    func cleanTemporaryDirectory() {
        try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectoryUrl)
        try? FileManager.default.removeItem(at: FileManager.default.appGroupsTempDirectoryURL)
    }
    
    // this directory is no longer in use, but keep clearing it for old users
    func cleanCachedAttsLegacy() {
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

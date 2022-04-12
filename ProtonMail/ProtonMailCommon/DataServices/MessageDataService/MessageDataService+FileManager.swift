//
//  MessageDataService.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

// MARK: - NSFileManager extension
extension FileManager {
    var attachmentDirectory: URL {
        let attachmentDirectory = temporaryDirectoryUrl.appendingPathComponent("attachments", isDirectory: true)
        if !self.fileExists(atPath: attachmentDirectory.absoluteString) {
            do {
                try self.createDirectory(at: attachmentDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
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
        catch {
        }
    }
}

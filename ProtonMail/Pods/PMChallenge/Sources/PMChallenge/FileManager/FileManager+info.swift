//
//  FileManager+info.swift
//  ProtonMail - Created on 6/18/20.
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

// Storage
extension FileManager {

    /**
     Get device storage size
     - Returns: Storage size in gigabyte, reture `nil` if failed
     */
    static func deviceCapacity() -> Double? {
        let fileManager = FileManager.default
        guard let path = fileManager.urls(for: .libraryDirectory, in: .systemDomainMask).last?.path else {
            return nil
        }
        guard let systemSize = try? fileManager.attributesOfFileSystem(forPath: path)[.systemSize],
              let systemSizeByte = systemSize as? Int else {
            return nil
        }
        let systemSizeGB = Double(systemSizeByte) / 1000.0 / 1000.0 / 1000.0
        return systemSizeGB
    }
}

// MARK: Jail break
extension FileManager {
    static func isJailbreak() -> Bool {
        guard TARGET_IPHONE_SIMULATOR != 1 else {return false}

        // Check 1 : existence of files that are common for jailbroken devices
        let checkList = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        for path in checkList {
            if FileManager.default.fileExists(atPath: path) {
                // Uncommon file exists
                return true
            }
            if canOpen(path: path) {
                return true
            }
        }

        let path = "/private/" + UUID().uuidString
        do {
            try "anyString".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            try FileManager.default.removeItem(atPath: path)
            //            print("[Jailbreak detection]:\tCreate file in /private/.")
            return true
        } catch {
            return false
        }
    }

    private static func canOpen(path: String) -> Bool {
        let file = fopen(path, "r")
        guard file != nil else { return false }
        fclose(file)
        return true
    }
}

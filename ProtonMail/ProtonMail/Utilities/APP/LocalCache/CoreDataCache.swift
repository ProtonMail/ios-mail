//
//  CoreDataCache.swift
//  Proton Mail - Created on 12/18/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

/// core data related cache versioning. when clean or rebuild. should also rebuild the counter and queue
class CoreDataCache: Migrate {
    typealias Dependencies = HasKeychain & HasUserDefaults

    private let dependencies: Dependencies

    /// latest version, pass in from outside. should be constants in global.
    internal var latestVersion: Int

    enum Key {
        static let coreDataVersion = "latest_core_data_cache"
    }
    enum Version: Int {
        // Change this value to rebuild coredata
        static let CacheVersion: Int = 5 // this is core data cache

        case version1 = 1
        case version2 = 2
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        self.latestVersion = Version.CacheVersion
    }

    var currentVersion: Int {
        get {
            dependencies.userDefaults.integer(forKey: Key.coreDataVersion)
        }
        set {
            dependencies.userDefaults.set(newValue, forKey: Key.coreDataVersion)
        }
    }

    var initalRun: Bool {
        return currentVersion == 0
    }

    func rebuild(reason: RebuildReason) throws {
        CoreDataStore.deleteDataStore()

        if self.currentVersion <= Version.version2.rawValue {
            dependencies.userDefaults.set(0, forKey: UsersManager.CoderKey.Version)
            try dependencies.keychain.removeOrError(forKey: "BioProtection" + ".version")
            try dependencies.keychain.removeOrError(forKey: "PinProtection" + ".version")
        }

        // TODO:: fix me
        // sharedMessageDataService.cleanUp()
        self.currentVersion = self.latestVersion
    }
}

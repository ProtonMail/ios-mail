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

    /// saver for versioning
    private let versionSaver: Saver<Int>

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
        self.versionSaver = UserDefaultsSaver<Int>(key: Key.coreDataVersion, store: dependencies.userDefaults)
    }

    var currentVersion: Int {
        get {
            return self.versionSaver.get() ?? 0
        }
        set {
            self.versionSaver.set(newValue: newValue)
        }
    }

    var initalRun: Bool {
        return currentVersion == 0
    }

    internal func rebuild(reason: RebuildReason) {
        CoreDataStore.deleteDataStore()

        if self.currentVersion <= Version.version2.rawValue {
            let userVersion = UserDefaultsSaver<Int>(
                key: UsersManager.CoderKey.Version,
                store: dependencies.userDefaults
            )
            userVersion.set(newValue: 0)
            dependencies.keychain.remove(forKey: "BioProtection" + ".version")
            dependencies.keychain.remove(forKey: "PinProtection" + ".version")
        }

        // TODO:: fix me
        // sharedMessageDataService.cleanUp()
        self.currentVersion = self.latestVersion
    }
}

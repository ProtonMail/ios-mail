//
//  AppCacheService.swift
//  Proton Mail - Created on 12/4/18.
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

import ProtonCoreKeymaker

class AppCacheService: Service {
    typealias Dependencies = HasKeychain & HasUserDefaults

    enum Constants {
        enum SettingsBundleKeys {
            static var clearAll = "clear_all_preference"
            static var appVersion = "version_preference"
            static var libVersion = "lib_version_preference"
        }
    }

    private let coreDataCache: CoreDataCache
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.coreDataCache = CoreDataCache(dependencies: dependencies)
        self.dependencies = dependencies
    }

    func restoreCacheWhenAppStart() {
        self.checkSettingsBundle()
        self.coreDataCache.run()
    }

    private func checkSettingsBundle() {
        if dependencies.userDefaults.bool(forKey: Constants.SettingsBundleKeys.clearAll) {
            // core data
            CoreDataStore.deleteDataStore()

            let names = [PMPersistentQueue.Constant.name,
                        PMPersistentQueue.Constant.miscName]
            for name in names {
                let path = FileManager.default
                    .applicationSupportDirectoryURL
                    .appendingPathComponent(name)
                try? FileManager.default.removeItem(at: path)
            }

            if let domain = Bundle.main.bundleIdentifier {
                dependencies.userDefaults.removePersistentDomain(forName: domain)
            }

            dependencies.keychain.removeEverything()
        }

        dependencies.userDefaults.setValue(Bundle.main.appVersion, forKey: Constants.SettingsBundleKeys.appVersion)
    }
}

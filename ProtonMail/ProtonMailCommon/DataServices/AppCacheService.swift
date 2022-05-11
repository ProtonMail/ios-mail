//
//  AppCacheService.swift
//  ProtonMail - Created on 12/4/18.
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
import OpenPGP

class AppCacheService: Service {

    enum Constants {
        enum SettingsBundleKeys {
            static var clearAll = "clear_all_preference"
            static var appVersion = "version_preference"
            static var libVersion = "lib_version_preference"
        }
    }
    private let userDefault = SharedCacheBase()
    private let coreDataCache: CoreDataCache
    private let appCache: AppCache

    init() {
        self.coreDataCache = CoreDataCache()
        self.appCache = AppCache()
    }

    func restoreCacheWhenAppStart() {
        self.checkSettingsBundle()
        self.coreDataCache.run()
        self.appCache.run()
    }

    private func checkSettingsBundle() {
        if UserDefaults.standard.bool(forKey: Constants.SettingsBundleKeys.clearAll) {
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

            // user defaults
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
                self.userDefault.getShared().removePersistentDomain(forName: domain)
            }

            // keychain
            KeychainWrapper.keychain.removeEverything()
        }

        UserDefaults.standard.setValue(Bundle.main.appVersion, forKey: Constants.SettingsBundleKeys.appVersion)
        UserDefaults.standard.setValue(PMNLibVersion.getLibVersion(), forKey: Constants.SettingsBundleKeys.libVersion)
    }
}

// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

extension UsersManager: Migrate {
    var supportedVersions: [Int] {
        return [Version.ver0.rawValue,
                Version.ver1.rawValue]
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
        return currentVersion == 0 &&
            KeychainWrapper.keychain.data(forKey: CoderKey.keychainStore) == nil &&
            KeychainWrapper.keychain.data(forKey: CoderKey.authKeychainStore) == nil &&
            KeychainWrapper.keychain.data(forKey: CoderKey.userInfo) == nil &&
            KeychainWrapper.keychain.data(forKey: CoderKey.usersInfo) == nil
    }

    func rebuild(reason: RebuildReason) {
        self.cleanLagacy()
        self.currentVersion = self.latestVersion
    }

    func cleanLagacy() {
        // Clear up the old stuff on fresh installs also
    }

    func logout() {
        self.versionSaver.set(newValue: nil)
    }

    func migrate(from verfrom: Int, to verto: Int) -> Bool {
        switch (verfrom, verto) {
        case (0, 1):
            return self.migrate_0_1()
        default:
            return false
        }
    }
}

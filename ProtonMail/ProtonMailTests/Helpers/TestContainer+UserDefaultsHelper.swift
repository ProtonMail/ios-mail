// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCoreDataModel
import ProtonCoreNetworking
@testable import ProtonMail
import XCTest

extension TestContainer {

    func addNewUserInUserDefaults(userID: String = UUID().uuidString) {
        let auth = AuthCredential(
            sessionID: userID,
            accessToken: "",
            refreshToken: "",
            userName: userID,
            userID: userID,
            privateKey: nil,
            passwordKeySalt: nil
        )
        let userInfo = UserInfo(
            maxSpace: nil,
            maxBaseSpace: nil,
            maxDriveSpace: nil,
            usedSpace: nil,
            usedBaseSpace: nil,
            usedDriveSpace: nil,
            language: nil,
            maxUpload: nil,
            role: 1,
            delinquent: nil,
            keys: [],
            userId: userID,
            linkConfirmation: nil,
            credit: nil,
            currency: nil,
            createTime: nil,
            subscribed: nil,
            edmOptOut: nil
        )

        setupUserDefaultsWithUser(auth: auth, userInfo: userInfo)
    }

    func setupUserDefaultsWithUser(auth: AuthCredential, userInfo: UserInfo) {
        XCTAssertTrue(usersManager.users.isEmpty)

        // Add and remove user to UsersManager copying stored data in the middle
        do {
            try usersManager.add(auth: auth, user: userInfo, mailSettings: .init())
        } catch {
            XCTFail("\(error)")
            return
        }

        let authCredentials = userDefaults.value(forKey: UsersManager.CoderKey.authKeychainStore)
        let usersInfo = userDefaults.value(forKey: UsersManager.CoderKey.usersInfo)
        let mailSettings = userDefaults.value(forKey: UsersManager.CoderKey.mailSettingsStore)
        usersManager.users.forEach(usersManager.remove(user:))

        // Deleting data stored by UserObjectsPersistence
        try? FileManager.default.removeItem(at: FileManager.default.documentDirectoryURL.appendingPathComponent([AuthCredential].pathComponent))
        try? FileManager.default.removeItem(at: FileManager.default.documentDirectoryURL.appendingPathComponent([UserInfo].pathComponent))

        // Set copied stored data again in testContainer.userDefaults
        userDefaults.setValue(authCredentials, forKey: UsersManager.CoderKey.authKeychainStore)
        userDefaults.setValue(usersInfo, forKey: UsersManager.CoderKey.usersInfo)
        userDefaults.setValue(mailSettings, forKey: UsersManager.CoderKey.mailSettingsStore)

        XCTAssertTrue(usersManager.users.isEmpty)
    }
}

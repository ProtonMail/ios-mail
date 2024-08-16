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
import ProtonCoreServices
import ProtonCoreTestingToolkitUnitTestsServices
import UIKit

@testable import ProtonMail

extension UserManager {
    convenience init(
        api: APIService,
        userInfo: UserInfo = UserInfo.getDefault(),
        role: UserInfo.OrganizationRole? = nil,
        userID: String? = nil,
        appTelemetry: AppTelemetry = MailAppTelemetry(),
        authCredential: AuthCredential = .none,
        subscribed: User.Subscribed = .mail,
        globalContainer: GlobalContainer? = nil
    ) {
        if let role {
            userInfo.role = role.rawValue
        }

        if let userID {
            userInfo.userId = userID
        }

        userInfo.subscribed = subscribed

        self.init(
            api: api,
            userInfo: userInfo,
            authCredential: authCredential,
            mailSettings: nil,
            parent: nil,
            appTelemetry: appTelemetry,
            globalContainer: globalContainer ?? (UIApplication.shared.delegate as! AppDelegate).dependencies
        )
    }

    static func prepareUser(
        apiMock: APIServiceMock,
        userID: UserID = .init(String.randomString(10)),
        email: String = "",
        globalContainer: GlobalContainer? = nil
    ) throws -> UserManager {
        let keyPair = try MailCrypto.generateRandomKeyPair()
        let key = Key(
            keyID: "1",
            privateKey: keyPair.privateKey,
            keyFlags: Key.Flags.notCompromised.rawValue,
            active: 1,
            primary: 1
        )
        key.signature = "signature is needed to make this a V2 key"
        let address = Address(
            addressID: "1",
            domainID: nil,
            email: email,
            send: .active,
            receive: .active,
            status: .enabled,
            type: .externalAddress,
            order: 1,
            displayName: "",
            signature: "a",
            hasKeys: 1,
            keys: [key]
        )

        let user = UserManager(
            api: apiMock,
            userID: userID.rawValue,
            globalContainer: globalContainer
        )
        user.userInfo.userAddresses = [address]
        user.userInfo.userKeys = [key]
        user.authCredential.mailboxpassword = keyPair.passphrase
        return user
    }
}

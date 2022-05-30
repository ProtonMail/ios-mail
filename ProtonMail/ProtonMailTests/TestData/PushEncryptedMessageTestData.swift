// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_Crypto
@testable import ProtonMail

enum PushEncryptedMessageTestData {

    static func openUrlNotification(
        with encryptionKitProvider: EncryptionKitProviderMock,
        sender: String = "",
        body: String = "",
        url: String = ""
    ) -> String? {
        let message =
        """
        {
          "data": {
            "body": "\(body)",
            "sender": {
              "Name": "\(sender)",
              "Address": "abuse@protonmail.com",
              "Group": ""
            },
            "badge": 5,
            "messageId": "ee_HZqOT23NjYQ-AKNZ5kv8s866qLYG0JFBFm4OMiFUxEiy1z9nEATUHPnJZrZBj2N6HK54_GM83U3qobcd1Ug==",
            "url": "\(url)"
          },
          "type": "open_url"
        }
        """

        return try? Crypto().encryptNonOptional(plainText: message, publicKey: encryptionKitProvider.publicKey)
    }
}
